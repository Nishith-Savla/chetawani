import 'dart:async';

import 'package:chetawani/check_sms_spam.dart';
import 'package:chetawani/controllers/notification_controller.dart';
import 'package:chetawani/controllers/phone_state_controller.dart';
import 'package:chetawani/home_screen_list.dart';
import 'package:chetawani/models/phone_spam_check_response.dart';
import 'package:chetawani/models/spam_list_item.dart';
import 'package:chetawani/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:notifications/notifications.dart';
import 'package:phone_state/phone_state.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  configureDio();
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<NotificationEvent> _notificationEventSubscription;
  StreamSubscription<PhoneStateStatus?>? _phoneStateSubscription;
  String? incomingCallNumber;
  DateTime? _lastCallTimestamp;
  final List<SpamListItem> _spamList = [];

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
    NotificationController.onMarkAsSpam = handleMarkAsSpam;
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

  Future<PhoneSpamCheckResponse?> handleCallIncoming() async {
    // make a get request to the server to check if the phone number is spam
    final response = await dio.get('/phoneSpamCount/$incomingCallNumber');
    final Map<String, dynamic> json = response.data;
    debugPrint(json.toString());

    if (json['error'] != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(json['error'])));
      return null;
    }

    try {
      final phoneSpamCheckResponse = PhoneSpamCheckResponse.fromJson(json);
      debugPrint('phoneSpamCheckResponse: ${phoneSpamCheckResponse.toString()}');
      await NotificationController.createSpamAlertNotification(phoneSpamCheckResponse);
      return phoneSpamCheckResponse;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    return null;
  }

  void handleCallEnded() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Call ended')));
    await NotificationController.createSpamCheckNotification(incomingCallNumber!);
    debugPrint('CALL ENDED');
  }

  void startListening() {
    try {
      _notificationEventSubscription = Notifications().notificationStream!.listen(onData);
    } on NotificationException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void handleMarkAsSpam(String phoneNumber) {
    setState(() {
      _spamList.add(SpamListItem(
          phoneNumber: phoneNumber, timestamp: DateTime.now(), spamStatus: 'reported'));
    });
  }

  void onData(NotificationEvent event) {
    if (event.message?.toLowerCase().contains('incoming call') == true) {
      incomingCallNumber = event.title?.replaceAll(' ', '');
      if (incomingCallNumber != null) {
        if (_lastCallTimestamp != null &&
            DateTime.now().difference(_lastCallTimestamp!) < const Duration(seconds: 2)) {
          return;
        }
        final future = handleCallIncoming();
        _lastCallTimestamp = DateTime.now();
        future.then((phoneSpamCheckResponse) {
          if (phoneSpamCheckResponse != null && phoneSpamCheckResponse.riskScore > 0.5) {
            setState(() {
              _spamList.add(SpamListItem(
                  phoneNumber: incomingCallNumber!,
                  timestamp: _lastCallTimestamp!,
                  spamStatus: 'categorized'));
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${_spamList.isNotEmpty ? _spamList.length : 'No'} Chetawanis sent "),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => const CheckSMSSpam()));
              },
              icon: const Icon(Icons.sms))
        ],
      ),
      body: (_spamList.isEmpty)
          ? Center(
              child: Text('No Chetawanis sent', style: Theme.of(context).textTheme.headlineSmall))
          : Column(
              children: [
                HomeScreenList(items: _spamList),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _spamList.clear();
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
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
