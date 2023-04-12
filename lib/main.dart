import 'package:flutter/material.dart';
import 'dart:async';

import 'package:notifications/notifications.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Notifications _notifications;
  late final StreamSubscription<NotificationEvent> _subscription;
  DateTime? _timestamp;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    // initFlutterLocalNotificationsPlugin();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    startListening();
  }

  void startListening() {
    _notifications = Notifications();
    try {
      _subscription = _notifications.notificationStream!.listen(onData);
    } on NotificationException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void onData(NotificationEvent event) {
    if (event.message?.toLowerCase().contains('incoming call') == true) {
      final String? phoneNumber = event.title?.replaceAll(' ', '');
      if (phoneNumber != null) {
        if (_timestamp != null &&
            DateTime.now().difference(_timestamp!) < const Duration(seconds: 2)) {
          return;
        }
        debugPrint('Incoming call from $phoneNumber');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Incoming call from $phoneNumber')));

        //mestamp = DateTime.now();
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
    _subscription.cancel();
    super.dispose();
  }
}
