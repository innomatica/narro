import 'dart:async';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
// ignore: depend_on_referenced_packages
import 'package:googleapis_auth/googleapis_auth.dart' show AuthClient;

import '../shared/settings.dart';

class AuthLogic extends ChangeNotifier {
  final _googleSignIn = GoogleSignIn(scopes: googleSignInScopes);
  final _firebaseAuth = FirebaseAuth.instance;
  late final StreamSubscription _fAuthChange;
  late final StreamSubscription _gUserChange;

  User? _user;
  String lastError = '';

  AuthLogic() {
    // subscribe to the google user change
    _gUserChange = _googleSignIn.onCurrentUserChanged.listen((account) {
      // debugPrint('google account change: $account');
      // if google user signed out
      if (account == null) {
        // sign out from the firebase too
        _firebaseAuth.signOut();
        notifyListeners();
      }
    }, onError: (error) {
      debugPrint('GsignIn.onCurrentUserChanged error: $error');
    });

    // subcribe to the fbase auth change
    _fAuthChange = _firebaseAuth.authStateChanges().listen((user) {
      // debugPrint('firebase auth state change: $user');
      _user = user;
      notifyListeners();
    }, onError: (error) {
      debugPrint('Fbase.authStateChanges error: $error');
    });
  }

  @override
  dispose() {
    _fAuthChange.cancel();
    _gUserChange.cancel();
    super.dispose();
  }

  User? get user => _user;

  Future<AuthClient?> getAuthClient() async {
    if (_googleSignIn.currentUser == null) {
      // debugPrint('google is not signed in: sign in silently');
      await _googleSignIn.signInSilently();
    }
    return await _googleSignIn.authenticatedClient();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      // debugPrint('signInWithGoogle.account: $account');
      final auth = await account?.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: auth?.accessToken, idToken: auth?.idToken);
      return FirebaseAuth.instance.signInWithCredential(credential);
    } on PlatformException catch (e) {
      // don't be alarmed if this does not catch the exception
      // this is one of the never-fixed bugs in Firebase
      // https://stackoverflow.com/questions/56080818/how-to-catch-platformexception-in-flutter-dart
      lastError = e.code;
    } on FirebaseAuthException catch (e) {
      lastError = e.code;
    } catch (e) {
      lastError = e.toString();
    }
    return null;
  }

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
        case 'user-disabled':
        case 'user-not-found':
        case 'wrong-password':
        default:
          lastError = e.code;
      }
    } catch (e) {
      lastError = e.toString();
    }
    return null;
  }

  Future<bool> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user?.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
        case 'weak-password':
        case 'invalid-email':
        case 'user-disabled':
        case 'user-not-found':
        case 'wrong-password':
        default:
          lastError = e.code;
      }
    } catch (e) {
      lastError = e.hashCode.toString();
    }
    return false;
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
        case 'missing-android-pkg-name':
        case 'missing-continue-uri':
        case 'missing-ios-bundle-id':
        case 'invalid-continue-uri':
        case 'unauthorized-continue-uri':
        case 'user-not-found':
        default:
          lastError = e.code;
      }
    } catch (e) {
      lastError = e.hashCode.toString();
    }
    return false;
  }
}
