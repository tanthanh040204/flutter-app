/*
 * @file       mobile_stations_provider.dart
 * @brief      Provides the list of bike stations (sourced from Firestore
 *             collection `parking_zones`, shared with the web admin tool)
 *             and the user's current location.
 */

/* Imports ------------------------------------------------------------ */
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/parking_zone.dart';
import '../models/station.dart';
import '../services/mobile_user_repo.dart';

/* Constants ---------------------------------------------------------- */
const LatLng kDefaultUserLocation = LatLng(10.849908, 106.771621);

const String kVehicleStatusReady = 'Ready';
const String kVehicleStatusCharging = 'Charging';
const String kVehicleStatusPaused = 'Paused';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileStationsProvider extends ChangeNotifier {
  MobileStationsProvider(this._repo) {
    _bind();
  }

  /* --- private fields ------------------------------------------ */
  final MobileUserRepo _repo;
  StreamSubscription<List<ParkingZone>>? _zonesSub;
  LatLng _currentUserLocation = kDefaultUserLocation;
  List<BikeStation> _stations = const [];

  /* --- public getters ------------------------------------------ */
  LatLng get currentUserLocation => _currentUserLocation;
  List<BikeStation> get stations => _stations;

  /* --- public methods ------------------------------------------ */
  Future<void> refreshUserLocation() async {
    _currentUserLocation = kDefaultUserLocation;
    notifyListeners();
  }

  @override
  void dispose() {
    _zonesSub?.cancel();
    super.dispose();
  }

  /* --- private methods ----------------------------------------- */
  void _bind() {
    _zonesSub = _repo.watchParkingZones().listen(_onZonesUpdated);
  }

  void _onZonesUpdated(List<ParkingZone> zones) {
    _stations = zones.map(_zoneToStation).toList(growable: false);
    notifyListeners();
  }

  BikeStation _zoneToStation(ParkingZone zone) {
    return BikeStation(
      id: zone.id,
      name: zone.name,
      address: zone.address,
      point: zone.point,
      bikeCount: 0,
      availableSlots: 0,
      googleMapUrl:
          'https://www.google.com/maps/search/?api=1&query=${zone.point.latitude},${zone.point.longitude}',
      vehicles: const [],
      isActive: zone.isActive,
    );
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
