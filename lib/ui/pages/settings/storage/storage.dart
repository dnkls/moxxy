import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart' as nav;
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/storage_controller.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/settings/row.dart';
import 'package:moxxyv2/ui/widgets/settings/title.dart';
import 'package:moxxyv2/ui/widgets/stacked_bar_chart.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

/// The various time offsets for deleting old media files.
enum OlderThan {
  /// No offset. Deletes all media files.
  all(0),

  /// Deletes all files older than one week.
  oneWeek(7 * 24 * 60 * 60 * 1000),

  /// Deletes all files older than one month.
  oneMonth(31 * 24 * 60 * 60 * 1000);

  const OlderThan(this.milliseconds);

  /// The time offset in milliseconds.
  final int milliseconds;
}

class DeleteMediaDialog extends StatefulWidget {
  const DeleteMediaDialog({
    super.key,
  });

  @override
  DeleteMediaDialogState createState() => DeleteMediaDialogState();
}

class DeleteMediaDialogState extends State<DeleteMediaDialog> {
  OlderThan _selection = OlderThan.oneWeek;

  Widget _optionRow(OlderThan value, String text) {
    return InkWell(
      onTap: () {
        setState(() => _selection = value);
      },
      child: Row(
        children: [
          Radio(
            value: value,
            groupValue: _selection,
            onChanged: (_) {
              setState(() => _selection = value);
            },
          ),
          Text(text),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.pages.settings.storage.removeOldMediaDialog.title),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(textfieldRadiusRegular),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop(
              await showConfirmationDialog(
                t.pages.settings.storage.removeOldMediaDialog.title,
                t.pages.settings.storage.removeOldMediaDialog.confirmation.body,
                context,
                affirmativeText:
                    t.pages.settings.storage.removeOldMediaDialog.delete,
                destructive: true,
              )
                  ? _selection
                  : null,
            );
          },
          child: Text(
            t.pages.settings.storage.removeOldMediaDialog.delete,
            style: const TextStyle(
              color: Colors.red,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            t.global.dialogCancel,
          ),
        ),
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _optionRow(
            OlderThan.all,
            t.pages.settings.storage.removeOldMediaDialog.options.all,
          ),
          _optionRow(
            OlderThan.oneWeek,
            t.pages.settings.storage.removeOldMediaDialog.options.oneWeek,
          ),
          _optionRow(
            OlderThan.oneMonth,
            t.pages.settings.storage.removeOldMediaDialog.options.oneMonth,
          ),
        ],
      ),
    );
  }
}

class StorageSettingsPage extends StatefulWidget {
  const StorageSettingsPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const StorageSettingsPage(),
        settings: const RouteSettings(
          name: storageSettingsRoute,
        ),
      );

  @override
  StorageSettingsPageState createState() => StorageSettingsPageState();
}

class StorageSettingsPageState extends State<StorageSettingsPage> {
  /// The controller providing data to build the bar chart and the label.
  final StorageController _controller = StorageController();

  @override
  void initState() {
    super.initState();

    _controller.fetchStorageUsage();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.title(t.pages.settings.storage.title),
      body: BlocBuilder<PreferencesBloc, PreferencesState>(
        builder: (context, state) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: StreamBuilder<StorageState>(
                stream: _controller.stream,
                builder: (context, snapshot) {
                  final size = snapshot.hasData
                      ? fileSizeToString(snapshot.data!.totalUsage)
                      : t.pages.settings.storage.sizePlaceholder;

                  return Center(
                    child: Text(
                      t.pages.settings.storage.storageUsed(size: size),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  );
                },
              ),
            ),
            Center(
              child: StreamBuilder<StorageState>(
                stream: _controller.stream,
                builder: (context, snapshot) => StackedBarChart(
                  width: MediaQuery.of(context).size.width * 0.8,
                  items: [
                    BartChartItem(
                      t.pages.settings.storage.types.media,
                      snapshot.data?.mediaUsage ?? 0,
                      primaryColor,
                    ),
                    BartChartItem(
                      t.pages.settings.storage.types.stickers,
                      snapshot.data?.stickersUsage ?? 0,
                      Colors.blue,
                    ),
                  ],
                  showPlaceholderBars: !snapshot.hasData,
                ),
              ),
            ),
            Center(
              child: TextButton(
                child: Text(t.pages.settings.storage.viewMediaFiles),
                onPressed: () {
                  context.read<nav.NavigationBloc>().add(
                        nav.PushedNamedEvent(
                          const nav.NavigationDestination(
                            storageSharedMediaSettingsRoute,
                          ),
                        ),
                      );
                },
              ),
            ),
            SectionTitle(t.pages.settings.storage.storageManagement),
            SettingsRow(
              title: t.pages.settings.storage.removeOldMedia.title,
              description: t.pages.settings.storage.removeOldMedia.description,
              onTap: () async {
                final result = await showDialog<OlderThan>(
                  context: context,
                  builder: (context) => const DeleteMediaDialog(),
                );
                if (result != null) {
                  final deleteResult =
                      // ignore: cast_nullable_to_non_nullable
                      await MoxplatformPlugin.handler.getDataSender().sendData(
                            DeleteOldMediaFilesCommand(
                              timeOffset: result.milliseconds,
                            ),
                            awaitable: true,
                          ) as DeleteOldMediaFilesDoneEvent;

                  // Update the display
                  _controller.mediaUsageUpdated(
                    deleteResult.newUsage,
                  );

                  // Show the new conversations list
                  GetIt.I.get<ConversationsBloc>().add(
                        ConversationsSetEvent(deleteResult.conversations),
                      );
                }
              },
            ),
            SettingsRow(
              title: t.pages.settings.storage.manageStickers,
              onTap: () {
                Navigator.of(context).pushNamed(stickerPacksRoute);
              },
            ),
          ],
        ),
      ),
    );
  }
}
