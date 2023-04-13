import 'package:chetawani/models/spam_list_item.dart';
import 'package:flutter/material.dart';

class HomeScreenList extends StatelessWidget {
  final List<SpamListItem> items;
  const HomeScreenList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          title: Text(items[index].phoneNumber,
              style: TextStyle(
                  color: items[index].spamStatus == 'reported' ? Colors.red : Colors.orange)),
          subtitle: Text(items[index].timestamp.toString()),
        );
      },
    );
  }
}
