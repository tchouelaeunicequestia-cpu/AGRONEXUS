// lib/services/platform_services.dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';

// --- DATA MODELS ---

class PositionData {
  final double latitude;
  final double longitude;
  final String description;

  PositionData({
    required this.latitude,
    required this.longitude,
    required this.description,
  });
}

// --- ABSTRACT INTERFACES ---

abstract class LocationService {
  Future<PositionData> getCurrentLocation();
}

abstract class IdentityService {
  Future<bool> verifyFaceOrBiometric();
}

// --- LOCATION IMPLEMENTATIONS ---

class AndroidLocationService implements LocationService {
  @override
  Future<PositionData> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled on Android.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied.');
      }
    }

    Position pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return PositionData(
      latitude: pos.latitude,
      longitude: pos.longitude,
      description:
          'Android GPS (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
    );
  }
}

class WebLocationService implements LocationService {
  @override
  Future<PositionData> getCurrentLocation() async {
    Position pos = await Geolocator.getCurrentPosition();
    return PositionData(
      latitude: pos.latitude,
      longitude: pos.longitude,
      description:
          'Web Geolocation (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
    );
  }
}

class DesktopLocationService implements LocationService {
  @override
  Future<PositionData> getCurrentLocation() async {
    try {
      // 1. Check if Windows Location Services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Windows Location Services are disabled in PC Settings.',
        );
      }

      // 2. Check and request permissions on Windows
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Windows Location Permission denied.');
        }
      }

      // 3. Query actual live position on Windows
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return PositionData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        description:
            'Windows Live GPS (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
      );
    } catch (e) {
      // Fallback if Windows privacy or hardware blocks live location access
      return PositionData(
        latitude: 4.0511, // Douala Hub
        longitude: 9.7679,
        description: 'Desktop Fixed Hub (Douala, SRID: 4326)',
      );
    }
  }
}

class LocationServiceFactory {
  static LocationService getService() {
    if (kIsWeb) {
      return WebLocationService();
    } else if (Platform.isAndroid || Platform.isIOS) {
      return AndroidLocationService();
    } else {
      return DesktopLocationService();
    }
  }
}

// --- IDENTITY / BIOMETRIC IMPLEMENTATIONS ---

class AndroidIdentityService implements IdentityService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  Future<bool> verifyFaceOrBiometric() async {
    final bool canAuth =
        await _localAuth.canCheckBiometrics ||
        await _localAuth.isDeviceSupported();
    if (!canAuth) {
      throw Exception('Biometrics not supported on this Android device.');
    }

    return await _localAuth.authenticate(
      localizedReason:
          'Scan your face or fingerprint for AgroNexus verification.',
      biometricOnly: false,
    );
  }
}

class WebIdentityService implements IdentityService {
  @override
  Future<bool> verifyFaceOrBiometric() async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}

class DesktopIdentityService implements IdentityService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  Future<bool> verifyFaceOrBiometric() async {
    try {
      final bool canAuth =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (canAuth) {
        return await _localAuth.authenticate(
          localizedReason:
              'Verify identity via Windows Hello / Biometric sensor.',
        );
      }
    } catch (_) {}
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}

class IdentityServiceFactory {
  static IdentityService getService() {
    if (kIsWeb) {
      return WebIdentityService();
    } else if (Platform.isAndroid || Platform.isIOS) {
      return AndroidIdentityService();
    } else {
      return DesktopIdentityService();
    }
  }
}
