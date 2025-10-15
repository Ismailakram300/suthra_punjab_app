import 'dart:convert';

import 'package:figma_practice_project/Custom_Widgets/CustomButton.dart';
import 'package:figma_practice_project/Services/auth_service.dart';
import 'package:figma_practice_project/dashboard.dart';
import 'package:figma_practice_project/signup_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}



class _LoginScreenState extends State<LoginScreen> {
  ButtonState _state = ButtonState.enablen;
  final TextEditingController email = TextEditingController();
  final TextEditingController pass = TextEditingController();
  final AuthService _auth = AuthService();

  final _formKey = GlobalKey<FormState>(); // ✅ Add form key
  void initState() {
    super.initState();
    email.text = "ismail@gmail.com";
    pass.text = "12345678";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Form(
            key: _formKey, // ✅ Attach form key
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "You need to increase your minSdkVersion \n          in android/app/build.gradle.kt",
                  ),
                  SizedBox(height: 20),

                  // ✅ Email Field
                  TextFormField(
                    controller: email,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your email";
                      }
                      if (!value.contains("@")) {
                        return "Enter a valid email";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  // ✅ Password Field
                  TextFormField(
                    controller: pass,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your password";
                      }
                      if (value.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),

                  // Signup Redirect
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don’t have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SignupScreen()),
                            );
                          },
                          child: Text("Sign Up"),
                        ),
                      ],
                    ),
                  ),

                  // ✅ Login Button with validation check
                  GestureDetector(
                    onTap: () async {
                      if (_formKey.currentState!.validate()) {
                        // Call login service
                        final userModel = await _auth.login(
                          email.text.trim(),
                          pass.text.trim(),
                        );

                        if (userModel != null) {
                          // ✅ Login successful
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Welcome ${userModel.name} 🎉"),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          //  await _auth.startConnectivityListener(FirebaseAuth.instance.currentUser!.uid);
                          final prefs = await SharedPreferences.getInstance();

                          final ref = FirebaseDatabase.instance.ref(
                            "locations",
                          );
                          await ref.remove(); // deletes ALL complaints
                          await prefs.setBool("isLogIn", true);
                          await prefs.setString("userData", jsonEncode(userModel.toMap()));
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DashboardScreen(user: userModel),
                            ),
                          );
                          // Example navigation after login
                          // Get.offAll(() => HomeScreen(user: userModel));
                        } else {
                          // ❌ Login failed
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("LOgin Faild🎉"),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      child: Center(
                        child: Text(
                          "Login",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.red,
                      ),
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * .09,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
