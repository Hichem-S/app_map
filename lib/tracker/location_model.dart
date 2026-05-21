import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geocode;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class TrackerLocationModel extends ChangeNotifier {
  LatLng? here;
  geocode.Placemark? herePlace;
  StreamSubscription<LocationData>? locationStream;
  bool initialLocationSet = false;
  final Location _location = Location();


  Future<bool> requestLocationAccess() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }
    PermissionStatus permission = await _location.requestPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) return false;
    }
    return true;
  }

  Future<void> requestLocationUpdates() async {
    final granted = await requestLocationAccess();
    if (granted) {
      locationStream ??= _location.onLocationChanged.listen(_updateLocation);
      final locationData = await _location.getLocation();
      _updateLocation(locationData);
    } else {
      initialLocationSet = true;
      locationStream?.cancel();
      locationStream = null;
      here = null;
      herePlace = null;
      notifyListeners();
    }
  }

  void _updateLocation(LocationData data) {
    if (data.latitude != null && data.longitude != null) {
      here = LatLng(data.latitude!, data.longitude!);
      initialLocationSet = true;
      getAddress(here!).then((p) {
        herePlace = p;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void cancelLocationUpdates() {
    locationStream?.cancel();
    locationStream = null;
    here = null;
    herePlace = null;
    notifyListeners();
  }

  Future<geocode.Placemark?> getAddress(LatLng? loc) async {
    if (loc == null) return null;
    try {
      if (geocode.GeocodingPlatform.instance != null) {
        final marks = await geocode.placemarkFromCoordinates(
            loc.latitude, loc.longitude);
        return marks.first;
      }
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
    return null;
  }
}
