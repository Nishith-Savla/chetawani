import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:chetawani/models/phone_spam_check_response.dart';
import 'package:chetawani/utils.dart';
import 'package:flutter/material.dart';

class NotificationController {
  static Function(String phoneNumber)? onMarkAsSpam;

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
    String spamStatus = '1';
    if (receivedAction.buttonKeyPressed == 'spam') {
      debugPrint("${receivedAction.payload?['phoneNumber']} is a spam");
      spamStatus = '-1';
      if (onMarkAsSpam != null) onMarkAsSpam!(receivedAction.payload!['phoneNumber']!);
    }
    if (receivedAction.payload?['phoneNumber'] != null) {
      final String? error =
          await updateSpamStatus(receivedAction.payload!['phoneNumber']!, spamStatus);
      if (error != null) {
        debugPrint(error);
      }
    }
  }

  static Future<bool> createSpamAlertNotification(
      PhoneSpamCheckResponse phoneSpamCheckResponse) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return false;
    debugPrint(phoneSpamCheckResponse.riskScore.toString());

    if (phoneSpamCheckResponse.riskScore > 0.5) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: -1, // -1 is replaced by a random number
          channelKey: 'Default',
          title: 'Spam Warning',
          body:
              "${phoneSpamCheckResponse.riskScore * 100}% reports have marked ${phoneSpamCheckResponse.phoneNumber} as a spam",
          notificationLayout: NotificationLayout.Default,
        ),
      );
      debugPrint('Notification created 1');
      return false;
    }
    debugPrint('Notification not created 1');
    return true;
  }

  static Future<void> createSpamCheckNotification(String phoneNumber) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;
    debugPrint('Creating notification for $phoneNumber');
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: -1, // -1 is replaced by a random number
          channelKey: 'Default',
          title: 'Verify Spam',
          body: "Was $phoneNumber a spam?",
          notificationLayout: NotificationLayout.BigText,
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
    debugPrint('Notification created 2');
  }

  static Future<String?> updateSpamStatus(String phoneNumber, String status) async {
    final response = await dio.post('/phoneCallVote/$phoneNumber/vote?upvote=$status');
    final Map<String, dynamic> json = response.data;
    debugPrint(json.toString());

    if (json['error'] != null) {
      return json['error'];
    }

    return null;
  }
}
