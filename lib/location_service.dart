import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

class LocationService {
  static Future<void> sendLocation(Position position) async {
    String userName = "Unknown";
    String tehsilName = "Unknown";
    List<dynamic> unionCouncil = [];
    List<dynamic> unionCouncilId = [];
    String? tehsilId;
    final dbRef = FirebaseDatabase.instance.ref();
    final user = FirebaseAuth.instance.currentUser;

    final userSanp = await dbRef.child("users").child(user!.uid).get();
    if (userSanp.exists) {
      final userData = Map<String, dynamic>.from(userSanp.value as Map);
      print("Userrr Data: $userData");

      tehsilName = userData['tehsil_name'] ?? "Unknoen";
      print("Tehsil Name: $tehsilName");
      // ✅ safely cast to List if exists, otherwise []
      if (userData['union_council_name'] is List) {
        unionCouncil = List<dynamic>.from(userData['union_council_name']);
      }
      if (userData['union_council_id'] is List) {
        unionCouncilId = List<dynamic>.from(userData['union_council_id']);
      }
      userName = userData['name'] ?? "Unknown";
      tehsilId = userData['tehsil_id'] ?? "Unknown";
    }

    final data = {
      "latitude": position.latitude,
      "longitude": position.longitude,
      "tehsil_name": tehsilName,
      "tehsil_id": tehsilId,
      "union_council_id": unionCouncilId,
      "union_council_name": unionCouncil,
      "name": userName,
      "timestamp": DateTime.now().toIso8601String(),
    };
    try {
      await dbRef
          .child("locations")
          .child(user.uid)
          .child("logs")
          .push()
          .set(data);
      await dbRef.child("current_locations").child(user.uid).set(data);

      print("📍 Location saved: ${position.latitude}, ${position.longitude}");

      _syncOfflineData(user.uid);
    } catch (e) {
      print("⚠️ Firebase error, saving offline: $e");
      final box = Hive.box("offline_locations");

      await box.add({
        "uid": user.uid,
        "latitude": position.latitude,
        "longitude": position.longitude,
        "timestamp": DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<void> _syncOfflineData(String uid) async {
    final box = Hive.box("offline_locations");
    final dbRef = FirebaseDatabase.instance.ref();

    final offlineData = box.values.toList();

    for (var i = 0; i < offlineData.length; i++) {
      final data = offlineData[i];
      try {
        await dbRef
            .child("locations")
            .child(uid)
            .child("logs")
            .push()
            .set(data);
        await dbRef.child("current_locations").child(uid).set(data);
      } catch (e) {
        print("❌ Failed syncing ${data["timestamp"]}, stopping sync");
        return; // stop here, keep remaining unsent
      }
    }

    // ✅ Only clear after all sent successfully
    await box.clear();
    print("✅ Synced all offline packets (${offlineData.length})");
  }
}
