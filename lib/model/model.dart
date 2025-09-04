class PigeonUserDetails {
  final String username;
  final String email;

  PigeonUserDetails({required this.username, required this.email});

  factory PigeonUserDetails.fromJson(Map<String, dynamic> json) {
    return PigeonUserDetails(
      username: json['username'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
    };
  }
}
