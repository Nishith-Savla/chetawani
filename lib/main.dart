import 'dart:async';
import 'dart:convert';

import 'package:chetawani/constants.dart';
import 'package:chetawani/models/phone_spam_check_response.dart';
import 'package:chetawani/controllers/notification_controller.dart';
import 'package:chetawani/controllers/phone_state_controller.dart';
import 'package:flutter/material.dart';
import 'package:notifications/notifications.dart';
import 'package:phone_state/phone_state.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<NotificationEvent> _notificationEventSubscription;
  StreamSubscription<PhoneStateStatus?>? _phoneStateSubscription;
  String? phoneNumber;
  DateTime? _timestamp;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initNotificationController();
    initPhoneStateController();
  }

  void initPlatformState() {
    startListening();
  }

  void initNotificationController() {
    NotificationController.initializeLocalNotifications();
    NotificationController.startListeningNotificationEvents();
  }

  void initPhoneStateController() async {
    final controller = PhoneStateController(
      onCallEnded: handleCallEnded,
    );
    try {
      final subscription = await controller.initStream();
      if (subscription != null) _phoneStateSubscription = subscription;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> handleCallIncoming() async {
    // make a get request to the server to check if the phone number is spam
    var url = Constants.baseURL.resolve('/phoneSpamCount/$phoneNumber');
    debugPrint(url.toString());
    final response = await http.get(url);
    final Map<String, dynamic> json = jsonDecode(response.body);
    debugPrint(json.toString());

    if (json['error'] != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(json['error'])));
      return;
    }

    try {
      final phoneSpamCheckResponse = PhoneSpamCheckResponse.fromJson(json);
      await NotificationController.createSpamAlertNotification(phoneSpamCheckResponse);
      debugPrint('Notification created for Phone Spam Check Response: $phoneSpamCheckResponse');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void handleCallEnded() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Call ended')));
    NotificationController.createSpamCheckNotification(phoneNumber!);
  }

  void startListening() {
    try {
      _notificationEventSubscription = Notifications().notificationStream!.listen(onData);
    } on NotificationException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void onData(NotificationEvent event) {
    if (event.message?.toLowerCase().contains('incoming call') == true) {
      phoneNumber = event.title?.replaceAll(' ', '');
      if (phoneNumber != null) {
        if (_timestamp != null &&
            DateTime.now().difference(_timestamp!) < const Duration(seconds: 2)) {
          return;
        }
        handleCallIncoming();
        _timestamp = DateTime.now();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chetawani'),
      ),
      body: const Center(
        child: Text('Your spams will be visible here'),
      ),
    );
  }

  @override
  void dispose() {
    _notificationEventSubscription.cancel();
    _phoneStateSubscription?.cancel();
    super.dispose();
  }
}
