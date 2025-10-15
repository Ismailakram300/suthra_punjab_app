import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:figma_practice_project/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();


  //Signup
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String cnic,
    required String tehsil,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await _dbRef.child("users").child(user.uid).set({
          "uid": user.uid,
          "name": name,
          "email": email,
          "cnic": cnic,
          "tehsil": tehsil,
          "createdAt": ServerValue.timestamp,
        });

        //   return UserModel(uid: uid, name: name, email: email, cnic: cnic, tehsil: tehsil, password: password)

        return UserModel(
        //  password: password,
          uid: user.uid,
          name: name,
          email: email,
          cnic: cnic,
          tehsil: tehsil,
        );
      }
      return null;
    } catch (e) {
      print("❌ Signup error: $e");
      return null;
    }
  }

  // login
  Future<UserModel?> login(String email, String password) async {
    try {
      // final ref = FirebaseDatabase.instance.ref("locations");
      // await ref.remove();
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // 🔹 Fetch Firestore profile after successful login
        DatabaseEvent  event =
        await _dbRef.child("users").child(user.uid).once();
       // deletes ALL complaints


        if (!event.snapshot.exists) {
          print("⚠️ No profile found in Firestore for this user");
          return null;
        }

        Map<String, dynamic> data =
        Map<String, dynamic>.from(event.snapshot.value as Map);

        return UserModel(
          uid: user.uid,
          name: data["name"] ?? "",
          email: data["email"] ?? "",
          cnic: data["cnic"] ?? "",
          tehsil: data["tehsil"] ?? "",
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // 🔹 Handle Firebase login errors
      if (e.code == 'user-not-found') {
        print("❌ No user found for that email.");
      } else if (e.code == 'wrong-password') {
        print("❌ Wrong password provided.");
      } else if (e.code == 'invalid-email') {
        print("❌ Invalid email format.");
      } else {
        print("❌ FirebaseAuth error: ${e.message}");
      }
      return null;
    } catch (e) {
      // 🔹 Other unexpected errors
      print("❌ Login error: $e");
      return null;
    }
  }


}
