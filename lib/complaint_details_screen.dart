// complaint_details_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'Services/complaints_services.dart';

class ComplaintDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;

  const ComplaintDetailsScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  GoogleMapController? _mapController;
  LocationData? _currentLocation;
  LatLng? _complaintPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _iscomplete = false;

  final Location _location = Location();
  final ImagePicker _picker = ImagePicker();

  // Replace with your real API key (Routes API & Maps SDK must be enabled + billing)
  final String _googleApiKey = 'AIzaSyC--d-xPvD0h9QSD8qZxKW-Lp7KY9Z11Uk';

  LatLngBounds? _routeBounds; // computed bounds for camera

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    try {
      // Get user's location (this will request runtime permission if needed)
      final userLocation = await _location.getLocation();

      // Parse complaint location string stored like "lat, lng"
      final locationString = widget.complaint['location']?.toString() ?? '';
      if (!locationString.contains(',')) {
        debugPrint('Invalid complaint location: $locationString');
        // still show map with user location
        setState(() {
          _currentLocation = userLocation;
          _isLoading = false;
        });
        return;
      }

      final parts = locationString.split(',');
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());

      if (lat == null || lng == null) {
        debugPrint('Could not parse complaint coordinates: $locationString');
        setState(() {
          _currentLocation = userLocation;
          _isLoading = false;
        });
        return;
      }

      final complaintPosition = LatLng(lat, lng);

      // set markers for both points
      setState(() {
        _currentLocation = userLocation;
        _complaintPosition = complaintPosition;
        _markers = {
          Marker(
            markerId: const MarkerId('user'),
            position: LatLng(
              userLocation.latitude ?? 0.0,
              userLocation.longitude ?? 0.0,
            ),
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
          Marker(
            markerId: const MarkerId('complaint'),
            position: complaintPosition,
            infoWindow: const InfoWindow(title: 'Complaint Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        };
      });

      // get route using Routes API (v2)
      await _createRoute();
    } catch (e, st) {
      debugPrint('Error initializing map: $e\n$st');
    } finally {
      // Stop the loading spinner (map will appear even if route fails)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createRoute() async {
    if (_currentLocation == null || _complaintPosition == null) return;

    try {
      final origin = '${_currentLocation!.latitude},${_currentLocation!.longitude}';
      final destination = '${_complaintPosition!.latitude},${_complaintPosition!.longitude}';
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=driving&key=$_googleApiKey');

      final response = await http.get(url);
      if (response.statusCode != 200) {
        debugPrint('Directions request failed: HTTP ${response.statusCode}');
        _drawDirectLineFallback();
        return;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final status = data['status']?.toString() ?? 'UNKNOWN';
      if (status != 'OK') {
        debugPrint('Directions API status: $status, message: ${data['error_message']}');
        _drawDirectLineFallback();
        return;
      }

      final routes = (data['routes'] as List?) ?? [];
      if (routes.isEmpty) {
        debugPrint('Directions API returned no routes');
        _drawDirectLineFallback();
        return;
      }

      // Prefer overview polyline; if missing, concatenate step polylines
      final route0 = routes.first as Map<String, dynamic>;
      final overview = route0['overview_polyline'] as Map<String, dynamic>?;
      String? encoded = overview?['points'] as String?;
      List<LatLng> decodedPoints = [];

      if (encoded != null && encoded.isNotEmpty) {
        decodedPoints = _decodePolyline(encoded);
      } else {
        // Fallback to legs/steps polyline
        final legs = (route0['legs'] as List?) ?? [];
        for (final leg in legs) {
          final steps = (leg['steps'] as List?) ?? [];
          for (final step in steps) {
            final stepPoly = (step['polyline'] as Map<String, dynamic>?)?['points'] as String?;
            if (stepPoly != null && stepPoly.isNotEmpty) {
              decodedPoints.addAll(_decodePolyline(stepPoly));
            }
          }
        }
      }
      if (decodedPoints.isEmpty) {
        debugPrint('Decoded polyline produced 0 points');
        _drawDirectLineFallback();
        return;
      }

      setState(() {
        _polylines = {
          Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          width: 5,
          points: decodedPoints,
          ),
        };
      });

      final bounds = _computeBounds(decodedPoints);
      _routeBounds = bounds;
      await Future.delayed(const Duration(milliseconds: 200));
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } catch (e) {
      debugPrint('Error fetching directions: $e');
      _drawDirectLineFallback();
    }
  }

  void _drawDirectLineFallback() {
    if (_currentLocation == null || _complaintPosition == null) return;
    setState(() {
      _polylines.add(Polyline(
        polylineId: const PolylineId('direct'),
        color: Colors.blueGrey,
        width: 4,
        points: [
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          _complaintPosition!,
        ],
      ));
    });
  }

  // Polyline decoder for Google Encoded Polyline Algorithm Format
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  LatLngBounds _computeBounds(List<LatLng> points) {
    assert(points.isNotEmpty);
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base64Image = widget.complaint["before_picture"];
    final afterBase64 = widget.complaint["after_picture"];
    final complaintId = (widget.complaint["id"] ?? "").toString();
    final statusStr = (widget.complaint["status"] ?? "Unknown").toString();
    ImageProvider? imageProvider;
    ImageProvider? afterImageProvider;

    if (base64Image != null && (base64Image as String).isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(base64Image));
      } catch (e) {
        imageProvider = const AssetImage('assets/error.png');
      }
    }

    if (afterBase64 != null && (afterBase64 as String).isNotEmpty) {
      try {
        afterImageProvider = MemoryImage(base64Decode(afterBase64));
      } catch (e) {
        afterImageProvider = const AssetImage('assets/error.png');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () async {
              if (_complaintPosition == null) return;
              final lat = _complaintPosition!.latitude;
              final lng = _complaintPosition!.longitude;
              final url = Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: SizedBox(
              height: 260,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation != null
                      ? LatLng(_currentLocation!.latitude ?? 0.0,
                      _currentLocation!.longitude ?? 0.0)
                      : (_complaintPosition ?? const LatLng(33.6844, 73.0479)),
                  zoom: 13,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                onMapCreated: (controller) async {
                  _mapController = controller;
                  // animate to bounds if we already computed them
                  if (_routeBounds != null) {
                    await Future.delayed(const Duration(milliseconds: 200));
                    try {
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLngBounds(_routeBounds!, 50),
                      );
                    } catch (e) {
                      debugPrint('Failed to animate to bounds: $e');
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (imageProvider != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image(
                image: imageProvider,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Complaint ID: ${complaintId.isEmpty ? "N/A" : complaintId}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text('Status: $statusStr'),
          const SizedBox(height: 8),
            Text('Description: ${widget.complaint["description"] ?? "No details"}'),
          const SizedBox(height: 8),
          Text(
            'Created at: ${widget.complaint["created_at"] ?? "Unknown"}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (widget.complaint.containsKey('assigned_to'))
            Text(
              'Assigned by: ${widget.complaint["name"]}',
              style: const TextStyle(color: Colors.blueAccent),
            ),

          const SizedBox(height: 16),
          if (afterImageProvider != null) ...[
            const Text('After Image:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image(
                image: afterImageProvider,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ],

          ElevatedButton.icon(
            onPressed: widget.complaint["status"] == "resolved" || _isSaving
                ? null
                : () async {
                    await _onUploadAfterImageAndComplete(complaintId);
                    _iscomplete=true;

                  },
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_isSaving ? 'Saving...' : 'Upload After Image & Complete',style: TextStyle(color: Colors.white),),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Future<void> _onUploadAfterImageAndComplete(String complaintId) async {
    try {
      setState(() {
        _isSaving = true;
      });

      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (picked == null) {
        setState(() {
          _isSaving = false;
        });
        return;
      }

      final bytes = await picked.readAsBytes();
      final afterBase64 = base64Encode(bytes);

      final ok = await ComplaintServices.completeComplaint(
        complaintId: complaintId,
        afterPictureBase64: afterBase64,
      );

      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resolved complaint')),
        );
      } else {
        // update current view model
        setState(() {
          widget.complaint['after_picture'] = afterBase64;
          widget.complaint['status'] = 'resolved';
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint marked complete')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}