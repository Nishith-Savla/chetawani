class PhoneSpamCheckResponse {
  final int downvotes;
  final int upvotes;
  final double riskScore;
  final String phoneNumber;

  PhoneSpamCheckResponse({
    required this.phoneNumber,
    required this.downvotes,
    required this.upvotes,
    required this.riskScore,
  });

  factory PhoneSpamCheckResponse.fromJson(Map<String, dynamic> json) {
    return PhoneSpamCheckResponse(
      phoneNumber: json['phone_no'].toString(),
      downvotes: json['down_votes'],
      upvotes: 0,
      riskScore: 0,
      // upvotes: json['up_votes'],
      // riskScore: json['spam_risk'],
    );
  }
}
