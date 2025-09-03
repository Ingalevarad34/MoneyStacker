import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Login
  Future<String?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // await _dbRef.child("users").child(userCredential.user!.uid).update({
      //   "email": userCredential.user!.email,
      //   "lastLogin": DateTime.now().toIso8601String(),
      // });

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (_) {
      return "An unexpected error occurred.";
    }
  }

  // Register
  Future<String?> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _dbRef.child("users").child(userCredential.user!.uid).set({
        "uid": userCredential.user!.uid,
        "name": name,
        "email": email,
        "createdAt": DateTime.now().toIso8601String(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (_) {
      return "An unexpected error occurred.";
    }
  }
}
