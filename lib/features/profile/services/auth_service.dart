import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  /// create instance
  static final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance;

  /// GOOGLE LOGIN
  static Future<User?> signInWithGoogle() async {

    /// initialize
    await _googleSignIn.initialize(
      serverClientId: null,
    );

    /// open account picker
    final GoogleSignInAccount account =
        await _googleSignIn.authenticate();

    /// get auth details
    final GoogleSignInAuthentication auth =
        account.authentication;

    /// firebase credential
    final credential =
        GoogleAuthProvider.credential(
      idToken: auth.idToken,
    );

    /// login to firebase
    final userCredential =
        await _auth.signInWithCredential(
      credential,
    );

    return userCredential.user;

  }

  /// LOGOUT
  static Future logout() async {

    await _googleSignIn.signOut();

    await _auth.signOut();

  }

}