import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:chetawani/constants.dart';
import 'package:chetawani/models/phone_spam_check_response.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    String spamStatus = '1';
    if (receivedAction.buttonKeyPressed == 'spam') {
      debugPrint("${receivedAction.payload?['phoneNumber']} is a spam");
      spamStatus = '-1';
    }
    if (receivedAction.payload?['phoneNumber'] != null) {
      final String? error =
          await updateSpamStatus(receivedAction.payload!['phoneNumber']!, spamStatus);
      if (error != null) {
        debugPrint(error);
      }
    }
  }

  static Future<void> createSpamAlertNotification(
      PhoneSpamCheckResponse phoneSpamCheckResponse) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;
    debugPrint(phoneSpamCheckResponse.riskScore.toString());

    if (phoneSpamCheckResponse.riskScore > 0.5) {
      debugPrint((await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: -1, // -1 is replaced by a random number
          channelKey: 'Default',
          title: 'Spam Warning',
          body:
              "${phoneSpamCheckResponse.riskScore * 100}% reports have marked ${phoneSpamCheckResponse.phoneNumber} as a spam",
          notificationLayout: NotificationLayout.Default,
        ),
      ))
          .toString());
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
  }

  static Future<String?> updateSpamStatus(String phoneNumber, String status) async {
    var url = Constants.baseURL.resolve('/phoneCallVote/$phoneNumber/vote?upvote=$status');
    debugPrint(url.toString());
    final response = await http.post(url);
    final Map<String, dynamic> json = jsonDecode(response.body);
    debugPrint(json.toString());

    if (json['error'] != null) {
      return json['error'];
    }

    return null;
  }
}
