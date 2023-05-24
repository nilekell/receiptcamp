import 'package:firebase_auth/firebase_auth.dart';
import 'package:receiptcamp/models/app_user.dart';

class AuthService {

  // creating a member of class that represents an instance of firebase authentication
  final FirebaseAuth auth = FirebaseAuth.instance;

  // create user object based on firebase User class
  AppUser? userFromFirebaseUser(User user) {
    // ternary operator
    return AppUser(
      uid: user.uid,
      email: user.email 
    );
  }

  Stream<AppUser> retrieveCurrentUser() {
    // listening to when a user signs in/out
    // mapping firebase User to AppUser
    return auth.authStateChanges().map((User? user) {
      if (user != null) {
        return AppUser(uid: user.uid, email: user.email);
      } else {
        return  AppUser(uid: "uid", email: "email");
      }
    });
  }

  // sign in anonymously
  Future signInAnon() async {
    try {
      UserCredential result = await auth.signInAnonymously();
      User? firebaseUser = result.user;
      return userFromFirebaseUser(firebaseUser!);
    } catch(e) {
      print(e.toString());
      return null;
    
    }
  }

  // sign in with email & password
  Future<AppUser?> signIn(String email, String password) async {
    try {
      UserCredential result = await auth.signInWithEmailAndPassword(email: email, password: password);
      User? firebaseUser = result.user;
      return userFromFirebaseUser(firebaseUser!);
    } catch(e) {
      print(e.toString());
      return null;
    }
  }

  // register with email & password
  Future registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await auth.createUserWithEmailAndPassword(email: email, password: password);
      User? firebaseUser = result.user;
      return userFromFirebaseUser(firebaseUser!);
    } catch(e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> sendVerificationEmail() async {
    
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      return await user.sendEmailVerification();
    }
  }

  // sign out
  Future signOutFunc() async {
    try {
      auth.signOut();
    } catch(e) {
      print('Failed to sign out');
      print(e);

    }
  }
}