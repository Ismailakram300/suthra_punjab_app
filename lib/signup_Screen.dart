import 'package:figma_practice_project/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formkey = GlobalKey<FormState>();
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController cnic = TextEditingController();
  final TextEditingController pass = TextEditingController();
  final AuthService _auth = AuthService();

  String? selectedValue;
  final List<String> tehsils = [
    "Chakwal",
    "Attock",
    "Talagang",
    "Jhelum",
    "Dina",
    "Sohawa",
    "Hazo",
    "Jand",
    "Fateh Jang",
    "Pindi Gheb",
    "Hassanabdal",
    "Choa Saidan Shah",
    "Kallar Kahar",
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Form(
          key: _formkey,
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
                "You need to increase your minSdkVersion \n           in android/app/build.gradle.kt",
              ),
              SizedBox(height: 20),

              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Email is required";
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return "Enter a valid email";
                  }
                  return null;
                },
                controller: email,
                decoration: InputDecoration(
                  suffixIcon: Icon(Icons.email),
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),

              TextFormField(
                validator: (value) =>
                value == null || value.isEmpty ? "Name is required" : null,
                controller: name,
                decoration: InputDecoration(
                  suffixIcon: Icon(Icons.drive_file_rename_outline),
                  //PrefixIcon: ,
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),

              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "CNIC is required";
                  }
                  if (value.length < 13) {
                    return "CNIC must be 13 digits";
                  }
                  return null;
                },
                controller: cnic,
                decoration: InputDecoration(
                  suffixIcon: Icon(Icons.numbers),
                  labelText: "CNIC",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),

              TextFormField(
                controller: pass,
                decoration: InputDecoration(
                  suffixIcon: Icon(Icons.password),
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5), // rounded corners
                    ),
                  ),
                  hint: Text("Select Country"), // placeholder
                  icon: Icon(Icons.arrow_drop_down), //
                  items: tehsils.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedValue = value;
                    });

                  },
                  validator: (value) =>
                  value == null ? "Please select a tehsil" : null,
                ),
              ),
              // SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("if you have not register"),
                    TextButton(onPressed: () {
                      Navigator.push(context,MaterialPageRoute(builder:(_)=> LoginScreen()));
                    }, child: Text("LogIn")),
                  ],
                ),
              ),
              //SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  if (_formkey.currentState!.validate()) {
                    _auth.signUp(
                      name: name.text.trim(),
                      email: email.text.trim(),
                      cnic: cnic.text.trim(),
                      tehsil: selectedValue.toString(),
                      password: pass.text.trim(),
                    );
                    print("✅ Form Valid, Signing Up...");
                    Navigator.push(context,MaterialPageRoute(builder: (_)=>LoginScreen()));
                  } else {
                    print("❌ Form Invalid");
                  }

                },
                child: Container(
                  child: Center(
                    child: Text(
                      "Sign Up",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.red,
                  ),
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * .08,
                ),
              ),
              // SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
