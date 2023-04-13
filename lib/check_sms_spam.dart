import 'package:chetawani/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class CheckSMSSpam extends StatefulWidget {
  const CheckSMSSpam({super.key});

  @override
  State<CheckSMSSpam> createState() => _CheckSMSSpamState();
}

class _CheckSMSSpamState extends State<CheckSMSSpam> {
  final TextEditingController _smsTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // a textfield to get the SMS text as input and send it to the server
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check SMS Spam'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          children: [
            const SizedBox(height: 150),
            TextField(
              controller: _smsTextController,
              minLines: 10,
              maxLines: 30,
              decoration:
                  const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter SMS Text'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                debugPrint(_smsTextController.text);

                // send the SMS text to the server
                final response = await dio.post('/sms', data: {'content': _smsTextController.text});
                final Map<String, dynamic> json = response.data;
                debugPrint(json.toString());

                if (json['error'] != null && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(json['error'])));
                }

                if (json['isSpam'] == 1 && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text("Spam Classified")));
                } else {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Not Spam')));
                }
              },
              child: const Text('Check is Spam'),
            ),
          ],
        ),
      ),
    );
  }
}
