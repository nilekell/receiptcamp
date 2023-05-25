// ignore_for_file: public_member_api_docs, sort_constructors_first
// class to abstract away unnecessary details from firebase User class
// https://pub.dev/documentation/firebase_auth/latest/firebase_auth/User-class.html

class AppUser {
  final String uid;
  final String? email;
  final bool isVerified;

  AppUser({
    required this.uid,
    required this.email,
    required this.isVerified
  });
}
