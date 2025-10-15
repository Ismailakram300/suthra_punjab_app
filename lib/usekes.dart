// import 'dart:async';
// import 'dart:math';
//
// import 'package:dotted_border/dotted_border.dart';
// import 'package:figma_practice_project/complaint_form.dart';
// import 'package:figma_practice_project/complians_screen.dart';
// import 'package:figma_practice_project/location_service.dart';
// import 'package:figma_practice_project/models/user_model.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:location/location.dart' hide LocationAccuracy;
//
// /// ✅ Dashboard Screen
// class DashboardScreenTwo extends StatefulWidget {
//   final UserModel user;
//
//   const DashboardScreenTwo({required this.user, super.key});
//
//   @override
//   State<DashboardScreenTwo> createState() => _DashboardScreenTwoState();
// }
//
// class _DashboardScreenTwoState extends State<DashboardScreenTwo> {
//   GoogleMapController? _mapController;
//   LatLng? _currentLatLng;
//   Timer? _timer;
//
//   /// Converts degrees to radians
//   double _deg2rad(double deg) => deg * (pi / 180);
//
//   /// Calculate distance between two GPS points (Haversine formula)
//   double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
//     const R = 6371000; // Earth radius in meters
//     final dLat = _deg2rad(lat2 - lat1);
//     final dLon = _deg2rad(lon2 - lon1);
//
//     final a = sin(dLat / 2) * sin(dLat / 2) +
//         cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
//             sin(dLon / 2) * sin(dLon / 2);
//     final c = 2 * atan2(sqrt(a), sqrt(1 - a));
//
//     return R * c;
//   }
//
//   /// 🔹 Check if user is within 50m of a complaint and update its status
//   Future<void> checkNearbyComplaints() async {
//     final location = Location();
//     final userLocation = await location.getLocation();
//
//     final userLat = userLocation.latitude!;
//     final userLon = userLocation.longitude!;
//
//     final ref = FirebaseDatabase.instance.ref("complains");
//     final snapshot = await ref.get();
//
//     if (snapshot.exists) {
//       final complaints = Map<String, dynamic>.from(snapshot.value as Map);
//
//       complaints.forEach((key, value) async {
//         try {
//           final data = Map<String, dynamic>.from(value);
//
//           // ✅ Handle location stored as string like "33.598643, 73.153899"
//           final locationString = data["location"]?.toString();
//           if (locationString == null || !locationString.contains(",")) return;
//
//           final parts = locationString.split(",");
//           final lat = double.tryParse(parts[0].trim()) ?? 0.0;
//           final lon = double.tryParse(parts[1].trim()) ?? 0.0;
//
//           final distance = calculateDistance(userLat, userLon, lat, lon);
//           print("Complaint $key → distance: ${distance.toStringAsFixed(2)} m");
//
//           // ✅ Update if within 50 meters and not already inprocess
//           if (distance <= 50 && data["status"] == "pending") {
//             await ref.child(key).update({"status": "inprocess"});
//             print("✅ Complaint $key marked as inprocess");
//           }
//         } catch (e) {
//           print("❌ Error parsing complaint $key: $e");
//         }
//       });
//     } else {
//       print("⚠️ No complaints found");
//     }
//   }
//
//   /// 🔹 Run every 5 seconds to auto-check nearby complaints
//   void startComplaintMonitor() {
//     _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
//       checkNearbyComplaints();
//     });
//   }
//
//   void stopComplaintMonitor() {
//     _timer?.cancel();
//   }
//
//   /// 🔹 Request location permission
//   Future<void> _checkPermission() async {
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       permission = await Geolocator.requestPermission();
//     }
//   }
//
//   /// 🔹 Get current location and send to Firebase
//   Future<void> _getCurrentLocation() async {
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//
//       // ✅ Send location to Firebase
//       await LocationService.sendLocation(position);
//
//       setState(() {
//         _currentLatLng = LatLng(position.latitude, position.longitude);
//       });
//
//       _mapController?.animateCamera(
//         CameraUpdate.newLatLng(_currentLatLng!),
//       );
//     } catch (e) {
//       debugPrint("❌ Error getting location: $e");
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _checkPermission();
//     _getCurrentLocation();
//     startComplaintMonitor();
//   }
//
//   @override
//   void dispose() {
//     stopComplaintMonitor();
//     _mapController?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.lightBlueAccent,
//         title: const Text("Dashboard"),
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(15.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // 🔹 Google Map container
//               Container(
//                 decoration: BoxDecoration(
//                   border: Border.all(width: 1, color: Colors.black),
//                   borderRadius: BorderRadius.circular(13),
//                 ),
//                 width: 400,
//                 height: 300,
//                 child: _currentLatLng == null
//                     ? const Center(child: CircularProgressIndicator())
//                     : ClipRRect(
//                   borderRadius: BorderRadius.circular(12),
//                   child: GoogleMap(
//                     initialCameraPosition: CameraPosition(
//                       target: _currentLatLng!,
//                       zoom: 15,
//                     ),
//                     onMapCreated: (controller) {
//                       _mapController = controller;
//                     },
//                     myLocationEnabled: true,
//                     markers: {
//                       Marker(
//                         markerId: const MarkerId("currentLocation"),
//                         position: _currentLatLng!,
//                         infoWindow: const InfoWindow(title: "You are here"),
//                       ),
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               const Text("🔄 Sending location & checking nearby complaints every 5 sec ⏱️"),
//               const SizedBox(height: 20),
//
//               // 🔹 View Complaints button
//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                       context, MaterialPageRoute(builder: (_) => ComplaintsScreen()));
//                 },
//                 child: DottedBorder(
//                   color: Colors.black87,
//                   strokeWidth: 1.5,
//                   borderType: BorderType.RRect,
//                   radius: const Radius.circular(12),
//                   dashPattern: const [6, 4],
//                   child: Container(
//                     width: double.infinity,
//                     height: MediaQuery.of(context).size.height * 0.1,
//                     decoration: BoxDecoration(
//                       color: Colors.cyan.shade50,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.connected_tv_outlined),
//                         SizedBox(width: 10),
//                         Text(
//                           "View Complaints",
//                           style: TextStyle(
//                             color: Colors.black87,
//                             fontSize: 17,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // 🔹 Add Fueling Report button
//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                       context, MaterialPageRoute(builder: (_) => ComplaintForm()));
//                 },
//                 child: DottedBorder(
//                   color: Colors.black87,
//                   strokeWidth: 1.5,
//                   borderType: BorderType.RRect,
//                   radius: const Radius.circular(12),
//                   dashPattern: const [6, 4],
//                   child: Container(
//                     width: double.infinity,
//                     height: MediaQuery.of(context).size.height * 0.1,
//                     decoration: BoxDecoration(
//                       color: Colors.cyan.shade100,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.add_circle),
//                         SizedBox(width: 10),
//                         Text(
//                           "Add Fueling Reports",
//                           style: TextStyle(
//                             color: Colors.black87,
//                             fontSize: 17,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
