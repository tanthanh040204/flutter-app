/*
 * @file       mobile_stations_provider.dart
 * @brief      Provides the list of bike stations and the user's current location.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/station.dart';

/* Constants ---------------------------------------------------------- */
const LatLng kDefaultUserLocation = LatLng(10.7769, 106.7009);

const String kVehicleStatusReady = 'Sẵn sàng';
const String kVehicleStatusCharging = 'Đang sạc';
const String kVehicleStatusPaused = 'Tạm ngưng';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileStationsProvider extends ChangeNotifier {
  MobileStationsProvider() {
    _loadDemoStations();
  }

  /* --- private fields ------------------------------------------ */
  LatLng _currentUserLocation = kDefaultUserLocation;
  List<BikeStation> _stations = [];

  /* --- public getters ------------------------------------------ */
  LatLng get currentUserLocation => _currentUserLocation;
  List<BikeStation> get stations => _stations;

  /* --- public methods ------------------------------------------ */
  Future<void> refreshUserLocation() async {
    /* Demo build: keep location at District 1 so stations are visible. */
    /* TODO: hook up the real geolocator later. */
    _currentUserLocation = kDefaultUserLocation;
    notifyListeners();
  }

  /* --- private methods ----------------------------------------- */
  void _loadDemoStations() {
    _stations = const [
      BikeStation(
        id: 'ST001',
        name: '048 - Trạm Ga Metro Bến Thành',
        address: '20 Lê Lai, Phường Bến Thành, Quận 1, TP Hồ Chí Minh',
        point: LatLng(10.7726, 106.6980),
        bikeCount: 12,
        availableSlots: 8,
        googleMapUrl:
            'https://www.google.com/maps/search/?api=1&query=10.7726,106.6980',
        vehicles: [
          StationVehicleInfo(
            code: 'X72B-22.600',
            batteryPercent: 94,
            status: kVehicleStatusReady,
          ),
          StationVehicleInfo(
            code: 'X51A-21.300',
            batteryPercent: 72,
            status: kVehicleStatusReady,
          ),
          StationVehicleInfo(
            code: 'X51B-21.368',
            batteryPercent: 68,
            status: kVehicleStatusReady,
          ),
        ],
      ),
      BikeStation(
        id: 'ST002',
        name: 'Công viên 30/4',
        address: 'Lê Duẩn, Phường Bến Nghé, Quận 1, TP Hồ Chí Minh',
        point: LatLng(10.7791, 106.6998),
        bikeCount: 10,
        availableSlots: 10,
        googleMapUrl:
            'https://www.google.com/maps/search/?api=1&query=10.7791,106.6998',
        vehicles: [
          StationVehicleInfo(
            code: 'X51V-21.888',
            batteryPercent: 17,
            status: kVehicleStatusReady,
          ),
          StationVehicleInfo(
            code: 'X51C-21.123',
            batteryPercent: 23,
            status: kVehicleStatusReady,
          ),
          StationVehicleInfo(
            code: 'X51U-21.444',
            batteryPercent: 99,
            status: kVehicleStatusReady,
          ),
        ],
      ),
      BikeStation(
        id: 'ST003',
        name: 'Trống Đồng',
        address:
            '12B Cách Mạng Tháng 8, Phường Bến Thành, Quận 1, TP Hồ Chí Minh',
        point: LatLng(10.7735, 106.6938),
        bikeCount: 13,
        availableSlots: 6,
        googleMapUrl:
            'https://www.google.com/maps/search/?api=1&query=10.7735,106.6938',
        vehicles: [
          StationVehicleInfo(
            code: 'X73A-23.001',
            batteryPercent: 88,
            status: kVehicleStatusReady,
          ),
          StationVehicleInfo(
            code: 'X73A-23.002',
            batteryPercent: 75,
            status: kVehicleStatusReady,
          ),
          StationVehicleInfo(
            code: 'X73A-23.003',
            batteryPercent: 52,
            status: kVehicleStatusCharging,
          ),
        ],
      ),
      BikeStation(
        id: 'ST004',
        name: 'Sở Y Tế',
        address:
            '59 Nguyễn Thị Minh Khai, Phường Bến Thành, Quận 1, TP Hồ Chí Minh',
        point: LatLng(10.7761, 106.6927),
        bikeCount: 5,
        availableSlots: 14,
        googleMapUrl:
            'https://www.google.com/maps/search/?api=1&query=10.7761,106.6927',
        vehicles: [
          StationVehicleInfo(
            code: 'X61A-20.501',
            batteryPercent: 81,
            status: kVehicleStatusReady,
          ),
          StationVehicleInfo(
            code: 'X61A-20.502',
            batteryPercent: 64,
            status: kVehicleStatusReady,
          ),
        ],
      ),
      BikeStation(
        id: 'ST005',
        name: 'Công viên Tao Đàn',
        address: 'Trương Định, Phường Bến Thành, Quận 1, TP Hồ Chí Minh',
        point: LatLng(10.7747, 106.6919),
        bikeCount: 13,
        availableSlots: 2,
        googleMapUrl:
            'https://www.google.com/maps/search/?api=1&query=10.7747,106.6919',
        vehicles: [
          StationVehicleInfo(
            code: 'X62B-19.800',
            batteryPercent: 96,
            status: kVehicleStatusReady,
          ),
          StationVehicleInfo(
            code: 'X62B-19.801',
            batteryPercent: 45,
            status: kVehicleStatusReady,
          ),
          StationVehicleInfo(
            code: 'X62B-19.802',
            batteryPercent: 33,
            status: kVehicleStatusPaused,
          ),
        ],
      ),
      BikeStation(
        id: 'ST006',
        name: 'Cung Văn hóa Lao Động',
        address:
            '57 Nguyễn Thị Minh Khai, Phường Bến Thành, Quận 1, TP Hồ Chí Minh',
        point: LatLng(10.7758, 106.6944),
        bikeCount: 3,
        availableSlots: 20,
        googleMapUrl:
            'https://www.google.com/maps/search/?api=1&query=10.7758,106.6944',
        vehicles: [
          StationVehicleInfo(
            code: 'X66A-18.120',
            batteryPercent: 55,
            status: kVehicleStatusReady,
          ),
        ],
      ),
      BikeStation(
        id: 'ST007',
        name: 'Nhà thờ Đức Bà',
        address: '01 Công xã Paris, Phường Bến Nghé, Quận 1, TP Hồ Chí Minh',
        point: LatLng(10.7798, 106.6990),
        bikeCount: 16,
        availableSlots: 4,
        googleMapUrl:
            'https://www.google.com/maps/search/?api=1&query=10.7798,106.6990',
        vehicles: [
          StationVehicleInfo(
            code: 'X70A-22.001',
            batteryPercent: 89,
            status: kVehicleStatusReady,
          ),
          StationVehicleInfo(
            code: 'X70A-22.002',
            batteryPercent: 92,
            status: kVehicleStatusReady,
          ),
          StationVehicleInfo(
            code: 'X70A-22.003',
            batteryPercent: 21,
            status: kVehicleStatusReady,
          ),
        ],
      ),
      BikeStation(
        id: 'ST008',
        name: 'Vincom Đồng Khởi',
        address: '72 Lê Thánh Tôn, Phường Bến Nghé, Quận 1, TP Hồ Chí Minh',
        point: LatLng(10.7782, 106.7032),
        bikeCount: 11,
        availableSlots: 7,
        googleMapUrl:
            'https://www.google.com/maps/search/?api=1&query=10.7782,106.7032',
        vehicles: [
          StationVehicleInfo(
            code: 'X80A-20.010',
            batteryPercent: 77,
            status: kVehicleStatusReady,
          ),
          StationVehicleInfo(
            code: 'X80A-20.011',
            batteryPercent: 59,
            status: kVehicleStatusCharging,
          ),
        ],
      ),
    ];

    notifyListeners();
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
