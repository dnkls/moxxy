import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/newconversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/bloc/request_bloc.dart';
import 'package:moxxyv2/ui/bloc/share_selection_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/ui/service/sharing.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> _requestPermissions() async {
  if (!(await Permission.notification.request().isGranted)) {
    GetIt.I.get<Logger>().finest('User did not grant notifcation permission');
  }
}

/// Handler for when we received a [PreStartDoneEvent].
Future<void> preStartDone(PreStartDoneEvent result, {dynamic extra}) async {
  GetIt.I.get<PreferencesBloc>().add(
        PreferencesChangedEvent(
          result.preferences,
          notify: false,
        ),
      );

  WidgetsFlutterBinding.ensureInitialized();
  if (result.preferences.languageLocaleCode == 'default') {
    LocaleSettings.useDeviceLocale();
  } else {
    LocaleSettings.setLocaleRaw(result.preferences.languageLocaleCode);
  }

  if (result.state == preStartLoggedInState) {
    // Set up the data service
    GetIt.I.get<UIDataService>().processPreStartDoneEvent(result);

    // Set up the BLoCs
    GetIt.I.get<ConversationsBloc>().add(
          ConversationsInitEvent(
            result.displayName!,
            result.jid!,
            result.conversations!,
            avatarUrl: result.avatarUrl,
          ),
        );
    GetIt.I.get<NewConversationBloc>().add(
          NewConversationInitEvent(
            result.roster!,
          ),
        );
    GetIt.I.get<ShareSelectionBloc>().add(
          ShareSelectionInitEvent(
            result.conversations!,
            result.roster!,
          ),
        );

    // Handle requesting permissions
    GetIt.I.get<RequestBloc>().add(
          RequestsSetEvent(
            [
              if (result.requestNotificationPermission) Request.notifications,
              if (result.excludeFromBatteryOptimisation)
                Request.batterySavingExcemption,
            ],
          ),
        );

    final sharing = GetIt.I.get<UISharingService>();
    if (sharing.hasEarlyMedia) {
      GetIt.I
          .get<Logger>()
          .finest('Early media available. Navigating to share selection');
      await sharing.handleEarlySharedMedia();
    } else {
      // TODO(Unknown): Actually handle this in the UI so that we can also display a text with the
      //                popup.
      if (result.requestNotificationPermission) {
        unawaited(_requestPermissions());
      }

      GetIt.I.get<Logger>().finest('Navigating to conversations');
      GetIt.I.get<NavigationBloc>().add(
            PushedNamedAndRemoveUntilEvent(
              const NavigationDestination(conversationsRoute),
              (_) => false,
            ),
          );
    }
  } else if (result.state == preStartNotLoggedInState) {
    // Set UI data
    GetIt.I.get<UIDataService>().isLoggedIn = false;

    // Clear shared media data
    await GetIt.I.get<UISharingService>().clearSharedMedia();

    // Navigate to the intro page
    GetIt.I.get<Logger>().finest('Navigating to intro');
    GetIt.I.get<NavigationBloc>().add(
          PushedNamedAndRemoveUntilEvent(
            const NavigationDestination(introRoute),
            (_) => false,
          ),
        );
  }
}
