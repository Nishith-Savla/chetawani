class SpamListItem {
  final String phoneNumber;
  final DateTime timestamp;
  final String spamStatus;

  SpamListItem({required this.phoneNumber, required this.timestamp, this.spamStatus = 'reported'});
}
