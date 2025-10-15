import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ComplaintServices {
  static Future<List<Map<String, dynamic>>> getComplaintsData() async {
    final user = FirebaseAuth.instance.currentUser;
    final dbRef = FirebaseDatabase.instance.ref();
    if (user == null) return [];
    try {
      final snapshot = await dbRef
          .child('complains')
          .orderByChild('assigned_to')
          .equalTo(user.uid)
          .get();
      if (!snapshot.exists) return [];
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      print("data::: $data");
      return data.entries.map((entry) {
        return {"id": entry.key, ...Map<String, dynamic>.from(entry.value)};
      }).toList();
    } catch (e) {
      print("⚠️ Error loading complaints: $e");
      return [];
    }

    // final complainSnap = await dbRef.child('complains').get();
    // final complainData = Map<String, dynamic>.from(complainSnap.value as Map);
    //  final filteredComplaints= complainData.entries.where((enter){
    //    final complain= Map<String, dynamic>.from(enter.value);
    //    return complain['assigned_to'] == user!.uid;

    //
    //  }).map((entry)=>{
    //
    //    "id":entry.key,
    //    ...Map<String, dynamic>.from(entry.value),
    //  } ).toList();
    // print("✅ Complaints assigned to ${user!.uid}:");
    // for (final complaint in filteredComplaints) {
    //   print(complaint);
    // }

    //  print(complainData);
  }

  static Future<bool> completeComplaint({
    required String complaintId,
    required String afterPictureBase64,
  }) async {
    try {
      final dbRef = FirebaseDatabase.instance.ref();
      await dbRef.child('complains').child(complaintId).update({
        'after_picture': afterPictureBase64,
        'resolution_datetime' : DateTime.now().toString(),
        'status': 'resolved',
        'completed_at': ServerValue.timestamp,
      });
      return true;
    } catch (e) {
      print('❌ Failed to complete complaint $complaintId: $e');
      return false;
    }
  }
}
