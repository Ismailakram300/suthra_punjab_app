import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:figma_practice_project/dashboard.dart';
import 'package:figma_practice_project/login.dart';
import 'package:figma_practice_project/models/user_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/colors.dart';
import 'firebase_options.dart';
import 'location_service.dart';
import 'package:flutter/services.dart';

/// ✅ Background service entry (for Android foreground mode)
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // 🔹 Open Hive box inside background isolate
  await Hive.initFlutter();
  await Hive.openBox('offline_locations'); // ✅ match this name
  // 🔹 This will call native Android service to keep tracking even if Flutter is killed
  const platform = MethodChannel('com.example.figma_practice_project/location');
  try {
    await platform.invokeMethod('startNativeService');
    print('✅ Native service started for background location');
  } catch (e) {
    print('❌ Failed to start native service: $e');
  }
}

/// ✅ Check permissions
Future<void> _checkPermissions() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) await Geolocator.openLocationSettings();

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    await Geolocator.openAppSettings();
  }
}
var cloudinary=Cloudinary.fromStringUrl('cloudinary://<913868916354798>:<iVxR1PgHl3VPQmB5dkqZXdOkvNA>@dqzjojsmh');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _checkPermissions();
  cloudinary.config.urlConfig.secure = true;


  // ✅ Initialize Hive before accessing any box
  await Hive.initFlutter();
  await Hive.openBox('offlineData');

  // ✅ Start native background service
  const platform = MethodChannel('location_service_channel');
  try {
    await platform.invokeMethod('startService');
    print("✅ Native background location service started");
  } catch (e) {
    print("❌ Failed to start service: $e");
  }

  // ✅ Continue normal app setup
  final prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool("isLogIn") ?? false;
  UserModel? user;
  if (isLoggedIn) {
    final userData = prefs.getString("userData");
    if (userData != null) {
      final decodedData = jsonDecode(userData) as Map<String, dynamic>;
      user = UserModel.fromMap(decodedData);
    }
  }

  runApp(MyApp(isLoggedIn: isLoggedIn, user: user));
}

class MyApp extends StatelessWidget {
  final UserModel? user;
  final bool isLoggedIn;

  const MyApp({required this.isLoggedIn, required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Complaint Tracker',
       theme: ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: AppColors.background,
        error: AppColors.error,
      ),
      textTheme: const TextTheme(

        bodyLarge: TextStyle(color: AppColors.textDark),
        bodyMedium: TextStyle(color: AppColors.textDark),
        titleLarge: TextStyle(fontWeight: FontWeight.bold),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
         iconTheme: IconThemeData(color: Colors.white, size: 30, ),
    ),
      home: isLoggedIn && user != null
          ? DashboardScreen(user: user!)
          : const LoginScreen(),
    );
  }
}
