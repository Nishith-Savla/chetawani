import 'dart:async';

import 'package:chetawani/notification_controller.dart';
import 'package:chetawani/phone_state_controller.dart';
import 'package:flutter/material.dart';
import 'package:notifications/notifications.dart';
import 'package:phone_state/phone_state.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Notifications _notifications;
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

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    startListening();
  }

  void initNotificationController() {
    NotificationController.initializeLocalNotifications();
    NotificationController.startListeningNotificationEvents();
  }

  void initPhoneStateController() async {
    final controller = PhoneStateController(
      onCallEnded: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Call ended')));
        NotificationController.createSpamCheckNotification(phoneNumber!);
      },
    );
    final subscription = await controller.initStream();
    if (subscription != null) _phoneStateSubscription = subscription;
  }

  void startListening() {
    _notifications = Notifications();
    try {
      _notificationEventSubscription = _notifications.notificationStream!.listen(onData);
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
        _timestamp = DateTime.now();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications example app'),
      ),
      body: const Center(
        child: Text('Notifications example app'),
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
