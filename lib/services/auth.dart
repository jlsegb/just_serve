import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class User {
  User({@required this.uid});

  final String uid;
}

abstract class AuthBase {
  Stream<User> get onAuthStateChange;

  Future<User> currentUser();

  Future<User> signInWithGoogle();

  Future<User> signInWithEmailAndPassword(String email, String password);

  Future<User> createUserWithEmailAndPassword(String email, String password);

  Future<void> signOut();
}

class Auth implements AuthBase {
  final _firebaseAuth = FirebaseAuth.instance;

  Stream<User> get onAuthStateChange {
    return _firebaseAuth.onAuthStateChanged.map(_userFromFirebaseInstance);
  }

  User _userFromFirebaseInstance(FirebaseUser firebaseUser) {
    if (firebaseUser == null) {
      return null;
    }
    return User(uid: firebaseUser.uid);
  }

  @override
  Future<User> currentUser() async {
    final firebaseUser = await _firebaseAuth.currentUser();
    return _userFromFirebaseInstance(firebaseUser);
  }

  @override
  Future<User> signInWithGoogle() async {
    GoogleSignIn googleSignIn = GoogleSignIn();
    GoogleSignInAccount googleAccount = await googleSignIn.signIn();

    if (googleAccount != null) {
      GoogleSignInAuthentication googleAuth = await googleAccount.authentication;
      if (googleAuth.idToken != null && googleAuth.accessToken != null) {
        final authResult = await _firebaseAuth.signInWithCredential(
          GoogleAuthProvider.getCredential(
            idToken: googleAuth.idToken,
            accessToken: googleAuth.accessToken,
          ),
        );
        return _userFromFirebaseInstance(authResult.user);
      } else {
        throw PlatformException(
          code: "ERROR_MISSING_AUTH_TOKEN",
          message: "Google sign in aborted due to missing ID or Access token",
        );
      }
    } else {
      throw PlatformException(
        code: "ERROR_ABORTED_BY_USER",
        message: "Google sign in aborted by user",
      );
    }
  }

  Future<User> signInWithEmailAndPassword(String email, String password) async {
    final authResult = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    return _userFromFirebaseInstance(authResult.user);
  }

  Future<User> createUserWithEmailAndPassword(String email, String password) async {
    final authResult = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
    return _userFromFirebaseInstance(authResult.user);
  }

  @override
  Future<void> signOut() async {
    final googleSignIn = GoogleSignIn();
    if (googleSignIn != null){
      await googleSignIn.signOut();
    }
    await _firebaseAuth.signOut();
  }
}
