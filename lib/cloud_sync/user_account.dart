/// LLD class: UserAccount. The person who created an optional account.
class UserAccount {
  const UserAccount({
    required this.uid,
    required this.fullName,
    required this.email,
  });

  final String uid;
  final String fullName;
  final String email;

  Map<String, dynamic> toJson() =>
      {'uid': uid, 'fullName': fullName, 'email': email};

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        uid: json['uid'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
      );
}
