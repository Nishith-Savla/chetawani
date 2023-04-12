import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart' show debugPrint;
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
    if (receivedAction.buttonKeyPressed == 'spam') {
      debugPrint("${receivedAction.payload?['phoneNumber']} is a spam");
    } else {
      debugPrint("${receivedAction.payload?['phoneNumber']} is NOT a spam");
    }
  }

  // static Future<bool> displayNotificationRationale() async {
  //   final BuildContext _context = context!;
  //   bool userAuthorized = false;
  //   await showDialog(
  //       context: _context,
  //       builder: (BuildContext ctx) {
  //         return AlertDialog(
  //           title: Text('Get Notified!', style: Theme.of(_context).textTheme.titleLarge),
  //           content: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: Image.asset(
  //                       'assets/animated-bell.gif',
  //                       height: MediaQuery.of(_context).size.height * 0.3,
  //                       fit: BoxFit.fitWidth,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 20),
  //               const Text('Allow Awesome Notifications to send you beautiful notifications!'),
  //             ],
  //           ),
  //           actions: [
  //             TextButton(
  //                 onPressed: () {
  //                   Navigator.of(ctx).pop();
  //                 },
  //                 child: Text(
  //                   'Deny',
  //                   style: Theme.of(_context).textTheme.titleLarge?.copyWith(color: Colors.red),
  //                 )),
  //             TextButton(
  //                 onPressed: () async {
  //                   userAuthorized = true;
  //                   Navigator.of(ctx).pop();
  //                 },
  //                 child: Text(
  //                   'Allow',
  //                   style:
  //                       Theme.of(_context).textTheme.titleLarge?.copyWith(color: Colors.deepPurple),
  //                 )),
  //           ],
  //         );
  //       });
  //   return userAuthorized && await AwesomeNotifications().requestPermissionToSendNotifications();
  // }

  static Future<void> executeLongTaskInBackground() async {
    print("starting long task");
    await Future.delayed(const Duration(seconds: 4));
    final url = Uri.parse("http://google.com");
    final re = await http.get(url);
    print(re.body);
    print("long task done");
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
