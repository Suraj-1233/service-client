import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId:
    "355133834187-i5bgnaku9l1vgm0d6shl05m660smamko.apps.googleusercontent.com", // Web OAuth ID
    forceCodeForRefreshToken: true, // Optional (for backend auth)
  );

  static Future<String?> getIdToken() async {
    try {
      await googleSignIn.signOut();
      final user = await googleSignIn.signIn();
      if (user == null) return null;

      final auth = await user.authentication;
      return auth.idToken;
    } catch (e) {
      print("Google Login Error: $e");
      return null;
    }
  }
}
