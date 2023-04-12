import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart' show debugPrint;

class NotificationController {
  static Future<void> initializeLocalNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'Default',
          channelName: 'Default',
          channelDescription: 'Default Channel for Spam Alerts',
          playSound: true,
          groupAlertBehavior: GroupAlertBehavior.Children,
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Private,
        )
      ],
      debug: true,
    );
  }

  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications().setListeners(onActionReceivedMethod: onActionReceivedMethod);
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == 'spam') {
      debugPrint("${receivedAction.payload?['phoneNumber']} is a spam");
    } else {
      debugPrint("${receivedAction.payload?['phoneNumber']} is NOT a spam");
    }
  }

  static Future<void> createSpamCheckNotification(String phoneNumber) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: -1, // -1 is replaced by a random number
          channelKey: 'Default',
          title: 'Verify Spam',
          body: "Was $phoneNumber a spam?",
          notificationLayout: NotificationLayout.Default,
          payload: {'phoneNumber': phoneNumber}),
      actionButtons: [
        NotificationActionButton(
          key: 'spam',
          label: 'Mark as SPAM',
          isDangerousOption: true,
        ),
        NotificationActionButton(
          key: 'dismiss',
          label: 'Not a Spam',
        )
      ],
    );
  }
}
