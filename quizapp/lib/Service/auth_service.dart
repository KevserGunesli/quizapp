import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizapp/Service/role_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoleService _roleService = RoleService();
  // Sign Up User
  Future<String> signUpUser({
    required String email,
    required String name,
    required String password,
    Uint8List? profileImage,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && name.isNotEmpty && password.isNotEmpty) {
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await _firestore.collection("userData").doc(cred.user!.uid).set({
          "name": name,
          "uid": cred.user!.uid,
          "email": email,
          'score': 0,
          'profileImage': profileImage != null
              ? base64Encode(profileImage)
              : null,
        });

        await _roleService.createUserRole(cred.user!.uid);
        await cred.user?.sendEmailVerification();
        res = "verification-sent";
      } else {
        res = "Please fill all the fields";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Login User
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        final cred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // E-maili doğrulanmamış kullanıcıları engelliyoruz ve maili yeniden yolluyoruz
        if (!(cred.user?.emailVerified ?? false)) {
          await cred.user?.sendEmailVerification();
          await _auth.signOut();
          return "email-not-verified";
        }

        res = "success";
      } else {
        res = "Please fill all the fields";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }
}
