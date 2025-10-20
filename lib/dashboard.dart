import 'dart:async';
import 'dart:math';
import 'package:dotted_border/dotted_border.dart';
import 'package:figma_practice_project/complaint_form.dart';
import 'package:figma_practice_project/complians_screen.dart';
import 'package:figma_practice_project/constants/custom_container.dart';
import 'package:figma_practice_project/location_service.dart';
import 'package:figma_practice_project/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' hide LocationAccuracy;

import 'constants/appbar.dart';
import 'fuel_entry_submission_form.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;
  const DashboardScreen({required this.user, super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  Timer? _timer;
  Set<Marker> _markers = {};
  int _total = 0;
  int _pending = 0;
  int _inprocess = 0;
  int _resolved = 0;


  double _deg2rad(double deg) => deg * (pi / 180);

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // Earth radius in meters
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// 🔹 Fetch all complaints and add markers to map
  Future<void> loadComplaintsOnMap() async {

    final ref = FirebaseDatabase.instance.ref("complains");
    final snapshot = await ref.get();

    if (!snapshot.exists || _currentLatLng == null) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    Set<Marker> markers = {};
    int total = 0;
    int pending = 0;
    int inprocess = 0;
    int resolved = 0;

    data.forEach((key, value) {
      try {
        final item = Map<String, dynamic>.from(value);

        final locationString = item["location"]?.toString();
        if (locationString == null || !locationString.contains(",")) return;

        final parts = locationString.split(",");
        final lat = double.tryParse(parts[0].trim()) ?? 0.0;
        final lon = double.tryParse(parts[1].trim()) ?? 0.0;

        final distance = calculateDistance(
          _currentLatLng!.latitude,
          _currentLatLng!.longitude,
          lat,
          lon,
        );

        //Count
        total++;
        switch (item["status"]) {
          case "pending":
            pending++;
            break;
          case "inprocess":
            inprocess++;
            break;
          case "resolved":
            resolved++;
            break;
        }


        // 🎨 Marker color by status
        BitmapDescriptor markerColor;
        switch (item["status"]) {
          case "inprocess":
            markerColor = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueYellow,
            );
            break;
          case "resolved":
            markerColor = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            );
            break;
          default:
            markerColor = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            );
        }

        markers.add(
          Marker(
            markerId: MarkerId(key),
            position: LatLng(lat, lon),
            infoWindow: InfoWindow(
              title: item["title"] ?? "Complaint",
              snippet: "📍 ${(distance / 1000).toStringAsFixed(2)} km away",
            ),
            icon: markerColor,
          ),
        );
      } catch (e) {
        debugPrint("❌ Error loading complaint marker: $e");
      }
    });
    setState(() {
      _markers = markers;
      _total = total ;
      _pending = pending;
      _inprocess = inprocess;
      _resolved = resolved;
    });
  }

  Future<void> checkNearbyComplaints() async {
    if (_currentLatLng == null) return;
    final ref = FirebaseDatabase.instance.ref("complains");
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final complaints = Map<String, dynamic>.from(snapshot.value as Map);

      for (var entry in complaints.entries) {
        final key = entry.key;
        final value = Map<String, dynamic>.from(entry.value);

        final locationString = value["location"]?.toString();
        if (locationString == null || !locationString.contains(",")) continue;

        final parts = locationString.split(",");
        final lat = double.tryParse(parts[0].trim()) ?? 0.0;
        final lon = double.tryParse(parts[1].trim()) ?? 0.0;

        final distance = calculateDistance(
          _currentLatLng!.latitude,
          _currentLatLng!.longitude,
          lat,
          lon,
        );

        // ✅ Mark as "inprocess" if near
        if (distance <= 50 && value["status"] == "pending") {
          await ref.child(key).update({"status": "inprocess"});
          debugPrint("✅ Complaint $key marked as inprocess");
        }
      }

      await loadComplaintsOnMap(); // refresh markers
    }
  }

  void startComplaintMonitor() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      checkNearbyComplaints();
    });
  }

  void stopComplaintMonitor() {
    _timer?.cancel();
  }

  Future<void> _checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await LocationService.sendLocation(position);

      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLatLng!));

      await loadComplaintsOnMap(); // ✅ Load complaints after current location ready
    } catch (e) {
      debugPrint("❌ Error getting location: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _getCurrentLocation();
    startComplaintMonitor();
  }

  @override
  void dispose() {
    stopComplaintMonitor();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomContainerAppBar(title: 'Dashboard'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 15),

                Row(
                  children: [
                    Icon(Icons.pin_drop_rounded, color:Colors.grey,),
                    SizedBox(width: 8),
                    Text("Chakwal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold,fontSize: 20),),

                  ],
                ),
                SizedBox(height: 15),

                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ComplaintsScreen()),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: AssetImage(
                          "assets/images/complainsDashboard/complainsDashboard.png",
                        ),
                      ),
                      border: Border.all(width: 1, color: Colors.black),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    width: 400,
                    height: 140,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(28.0),
                              child:RichText(text: TextSpan(
                                text:   'Complains ($_total)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,

                                ),
                                // children:[
                                //   TextSpan(
                                //     text: '\nPending ',
                                //     style: TextStyle(
                                //       color: Colors.blue,
                                //       fontSize: 17,
                                //       fontWeight: FontWeight.bold,
                                //     ),
                                //   ),   TextSpan(
                                //     text: ': $_total',
                                //     style: TextStyle(
                                //       color: Colors.blue,
                                //       fontSize: 16,
                                //       fontWeight: FontWeight.bold,
                                //     ),
                                //   ),
                                // ]
                              ))
                            ),

                            // CustomCard(title: "Hello"),
                            // CustomCard(title: "Hello"),
                            // CustomCard(title: "Hello"),
                            // Expanded(
                            //   child: Padding(
                            //     padding: const EdgeInsets.all(8.0),
                            //     child: Container(
                            //       height: 140,
                            //       decoration: BoxDecoration(
                            //         boxShadow: [
                            //           BoxShadow(
                            //             color: Colors.black.withOpacity(0.3), // shadow color
                            //             blurRadius: 8, // how soft the shadow is
                            //             spreadRadius: 2, // how wide the shadow spreads
                            //             offset: const Offset(2, 4), // (x, y) — move right & down
                            //           ),
                            //         ],
                            //         color: Colors.yellow.shade400,
                            //         border: Border.all(
                            //             width: 1, color: Colors.black),
                            //         borderRadius: BorderRadius.circular(13),
                            //       ),
                            //
                            //       child: Text("Conatiner !"),
                            //     ),
                            //   ),
                            // ),
                            //
                            //
                            //    Expanded(
                            //     child: Padding(
                            //       padding: const EdgeInsets.all(8.0),
                            //       child: Container(
                            //         height: 160,
                            //         decoration: BoxDecoration(
                            //           border: Border.all(width: 1, color: Colors.black),
                            //           borderRadius: BorderRadius.circular(13),
                            //         ),
                            //         child: Text("Conatiner !"),
                            //       ),
                            //     ),
                            //   ),
                            //
                            // Expanded(
                            //   child: Padding(
                            //     padding: const EdgeInsets.all(8.0),
                            //     child: Container(
                            //       height: 160,
                            //       decoration: BoxDecoration(
                            //         border: Border.all(width: 1, color: Colors.black),
                            //         borderRadius: BorderRadius.circular(13),
                            //       ),
                            //
                            //       child: Text("Conatiner !"),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0,0,10,0),
                              child: Container(
                                width: 120,
                                height: 39,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14)
                                ),
                                child: Center(child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Check",style: TextStyle(
                                        fontSize: 17,fontWeight: FontWeight.bold),
                                    ),
                                    Icon(Icons.arrow_forward_ios_rounded,color: Colors.black,size: 18,)
                                  ],
                                )),
                              ),
                            )

                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FuelEntrySubmissionForm(),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: AssetImage(
                          "assets/images/complainsDashboard/complainsDashboard.png",
                        ),
                      ),
                      border: Border.all(width: 1, color: Colors.black),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    width: 400,
                    height: 140,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                                padding: const EdgeInsets.all(28.0),
                                child:RichText(text: TextSpan(
                                  text:   'Add Fuels ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,

                                  ),
                                  // children:[
                                  //   TextSpan(
                                  //     text: '\nPending ',
                                  //     style: TextStyle(
                                  //       color: Colors.blue,
                                  //       fontSize: 17,
                                  //       fontWeight: FontWeight.bold,
                                  //     ),
                                  //   ),   TextSpan(
                                  //     text: ': $_total',
                                  //     style: TextStyle(
                                  //       color: Colors.blue,
                                  //       fontSize: 16,
                                  //       fontWeight: FontWeight.bold,
                                  //     ),
                                  //   ),
                                  // ]
                                ))
                            ),

                            // CustomCard(title: "Hello"),
                            // CustomCard(title: "Hello"),
                            // CustomCard(title: "Hello"),
                            // Expanded(
                            //   child: Padding(
                            //     padding: const EdgeInsets.all(8.0),
                            //     child: Container(
                            //       height: 140,
                            //       decoration: BoxDecoration(
                            //         boxShadow: [
                            //           BoxShadow(
                            //             color: Colors.black.withOpacity(0.3), // shadow color
                            //             blurRadius: 8, // how soft the shadow is
                            //             spreadRadius: 2, // how wide the shadow spreads
                            //             offset: const Offset(2, 4), // (x, y) — move right & down
                            //           ),
                            //         ],
                            //         color: Colors.yellow.shade400,
                            //         border: Border.all(
                            //             width: 1, color: Colors.black),
                            //         borderRadius: BorderRadius.circular(13),
                            //       ),
                            //
                            //       child: Text("Conatiner !"),
                            //     ),
                            //   ),
                            // ),
                            //
                            //
                            //    Expanded(
                            //     child: Padding(
                            //       padding: const EdgeInsets.all(8.0),
                            //       child: Container(
                            //         height: 160,
                            //         decoration: BoxDecoration(
                            //           border: Border.all(width: 1, color: Colors.black),
                            //           borderRadius: BorderRadius.circular(13),
                            //         ),
                            //         child: Text("Conatiner !"),
                            //       ),
                            //     ),
                            //   ),
                            //
                            // Expanded(
                            //   child: Padding(
                            //     padding: const EdgeInsets.all(8.0),
                            //     child: Container(
                            //       height: 160,
                            //       decoration: BoxDecoration(
                            //         border: Border.all(width: 1, color: Colors.black),
                            //         borderRadius: BorderRadius.circular(13),
                            //       ),
                            //
                            //       child: Text("Conatiner !"),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0,0,10,0),
                              child: Container(
                                width: 120,
                                height: 39,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14)
                                ),
                                child: Center(child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Add",style: TextStyle(
                                        fontSize: 17,fontWeight: FontWeight.bold),
                                    ),
                                    Icon(Icons.arrow_forward_ios_rounded,color: Colors.black,size: 18,)
                                  ],
                                )),
                              ),
                            )

                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 🔹 Map
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.black),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  width: 400,
                  height: 300,
                  child: _currentLatLng == null
                      ? const Center(child: CircularProgressIndicator())
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _currentLatLng!,
                              zoom: 15,
                            ),
                            onMapCreated: (controller) {
                              _mapController = controller;
                            },
                            myLocationEnabled: true,
                            markers: _markers,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "📍 All complaints displayed with distance & auto-update every 5 sec ⏱️",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // _buildButton(
                //   context,
                //   icon: Icons.list,
                //   text: "View Complaints",
                //   color: Colors.cyan.shade50,
                //
                // ),
                const SizedBox(height: 20),
                // _buildButton(
                //   context,
                //   icon: Icons.add_circle,
                //   text: "Add Fueling Reports",
                //   color: Colors.cyan.shade100,
                //   onTap: () => Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (_) => FuelEntrySubmissionForm(),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        color: Colors.black87,
        strokeWidth: 1.5,
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        dashPattern: const [6, 4],
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.1,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
