import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/service/xmpp.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/conversation.dart' as modelc;
import 'package:moxxyv2/shared/models/message.dart' as modelm;

const maxNotificationId = 2147483647;

// TODO(Unknown): Add resolution dependent drawables for the notification icon
class NotificationsService {
  NotificationsService() : _log = Logger('NotificationsService');
  // ignore: unused_field
  final Logger _log;

  Future<void> init() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('app_icon'),
      //ios: IOSInitilizationSettings(...)
    );

    // TODO(Unknown): Callback
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    GetIt.I.registerSingleton<FlutterLocalNotificationsPlugin>(flutterLocalNotificationsPlugin);
  }

  /// Returns true if a notification should be shown. false otherwise.
  bool shouldShowNotification(String jid) {
    return GetIt.I.get<XmppService>().getCurrentlyOpenedChatJid() != jid;
  }
  
  /// Show a notification for a message [m] grouped by its conversationJid
  /// attribute. If the message is a media message, i.e. mediaUrl != null and isMedia == true,
  /// then Android's BigPicture will be used.
  Future<void> showNotification(modelc.Conversation c, modelm.Message m, String title, { String? body }) async {
    // TODO(Unknown): Keep track of notifications to create a summary notification
    // See https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/example/lib/main.dart#L1293
    // TODO(Unknown): Also allow this with a generated video thumbnail
    final canShowMedia = m.mediaType != null && m.mediaUrl != null;
    String bodyToShow;
    if (body != null) {
      bodyToShow = body;
    } else {
      bodyToShow = canShowMedia ?
        mimeTypeToEmoji(m.mediaType) :
        m.body;
    }

    final person = Person(
      name: c.title,
      icon: c.avatarUrl.isNotEmpty ? BitmapFilePathAndroidIcon(c.avatarUrl) : null,
      key: c.jid,
    );
    final styleInformation = MessagingStyleInformation(
      person,
      conversationTitle: c.title,
      groupConversation: true,
      messages: [
        Message(
          bodyToShow,
          DateTime.now(),
          person,
          dataMimeType: canShowMedia ? m.mediaType : null,
          dataUri: canShowMedia ? 'file://${m.mediaUrl}' : null,
        ),
      ],
    );
    
    final androidDetails = AndroidNotificationDetails(
      'message_channel', 'Message channel',
      channelDescription: 'The notification channel for received messages',
      styleInformation: styleInformation,
      groupKey: m.conversationJid,
    );
    final details = NotificationDetails(android: androidDetails);
    await GetIt.I.get<FlutterLocalNotificationsPlugin>().show(
      m.id, null, null, details,
    );
  }

  /// Show a notification with the highest priority that uses [title] as the title
  /// and [body] as the body.
  // TODO(Unknown): Use the warning icon as the notification icon
  Future<void> showWarningNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'warning_channel', 'Warnings',
      channelDescription: 'Warnings related to Moxxy',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await GetIt.I.get<FlutterLocalNotificationsPlugin>().show(
      Random().nextInt(maxNotificationId),
      title,
      body,
      details,
    );
  }
}
