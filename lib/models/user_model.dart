class UserModel {
  final String uid;
  final String name;
  final String email;
  final String tehsil;
 // final String password;
  final String cnic;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.cnic,
    required this.tehsil,
 //   required this.password,
  });
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      cnic: map['cnic'],
      tehsil: map['tehsil'],
    //  password: map['password'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "name": name,
      "email": email,
      "cnic": cnic,
      "tehsil": tehsil,
    };
  }
}
