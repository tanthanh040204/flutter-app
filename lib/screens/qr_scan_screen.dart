import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/rental_vehicle.dart';
import '../providers/mobile_auth_provider.dart';
import '../providers/mobile_ride_provider.dart';
import '../services/mobile_user_repo.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool handled = false;

  static const String _validQrPrefix = 'haq-trk-';
  static const LatLng _defaultVehicleLocation = LatLng(10.853028, 106.782845);

  @override
  Widget build(BuildContext context) {
    final t = context.tr;

    return Scaffold(
      appBar: AppBar(title: Text(t.scanQrUnlockTitle)),
      body: MobileScanner(
        onDetect: (capture) async {
          if (handled) return;

          final code = capture.barcodes.first.rawValue;
          if (code == null || code.trim().isEmpty) return;

          handled = true;

          final valid = _resolveValidVehicle(context, code);
          if (valid == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.readTr.invalidQr)),
              );
            }
            await Future.delayed(const Duration(milliseconds: 1200));
            if (mounted) {
              setState(() {
                handled = false;
              });
            }
            return;
          }

          if (!mounted) return;
          final started = await _showConfirm(context, valid);

          if (!mounted) return;

          if (started) {
            Navigator.pop(context);
          } else {
            setState(() {
              handled = false;
            });
          }
        },
      ),
    );
  }

  _ValidQrVehicle? _resolveValidVehicle(BuildContext context, String raw) {
    final vehicleId = raw.trim().toLowerCase();

    if (!vehicleId.startsWith(_validQrPrefix)) return null;
    if (vehicleId.length <= _validQrPrefix.length) return null;

    return _ValidQrVehicle(
      qrValue: vehicleId,
      vehicleId: vehicleId,
      vehicleName: _vehicleNameFromQr(context, vehicleId),
      fallbackLocation: _defaultVehicleLocation,
    );
  }

  String _vehicleNameFromQr(BuildContext context, String vehicleId) {
    final code = vehicleId.replaceFirst(_validQrPrefix, '').toUpperCase();
    return context.readTr.vehicleNameFromCode(code);
  }

  Future<bool> _showConfirm(BuildContext context, _ValidQrVehicle valid) async {
    final t = context.readTr;
    final auth = context.read<MobileAuthProvider>();
    final ride = context.read<MobileRideProvider>();
    final repo = context.read<MobileUserRepo>();
    final user = auth.currentUser;
    if (user == null) return false;

    final money = NumberFormat.currency(locale: t.moneyLocale, symbol: t.moneySymbol);
    final requiredAmount = ride.selectedTotalRequired;

    final currentVehicle = ride.vehicle;
    final vehicle =
        (currentVehicle != null && currentVehicle.id == valid.vehicleId)
            ? currentVehicle
            : RentalVehicle(
                id: valid.vehicleId,
                name: valid.vehicleName,
                batteryPercent: 85,
                isLocked: true,
                isRunning: false,
                isPaused: false,
                isInUse: false,
                currentUserId: null,
                currentSessionId: null,
                totalKm: 0,
                temp: 0,
                hum: 0,
                dust: 0,
                lastLocation: valid.fallbackLocation,
                updatedAt: DateTime.now(),
              );

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.confirmUseVehicle(vehicle.name)),
        content: Text(
          user.balance >= requiredAmount
              ? t.confirmRideEnoughBalance(
                  vehicleId: valid.vehicleId,
                  hours: ride.selectedRentalHours,
                  usageFee: money.format(ride.selectedUsageFee),
                  depositAmount: money.format(ride.pricing.depositAmount),
                  requiredAmount: money.format(requiredAmount),
                )
              : t.confirmRideNotEnoughBalance(
                  vehicleId: valid.vehicleId,
                  hours: ride.selectedRentalHours,
                  requiredAmount: money.format(requiredAmount),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: user.balance >= requiredAmount
                ? () => Navigator.pop(context, true)
                : null,
            child: Text(t.yes),
          ),
        ],
      ),
    );

    if (ok != true) return false;

    try {
      await repo.startRide(
        user: user,
        vehicle: vehicle,
        pricing: ride.pricing,
        rentalHours: ride.selectedRentalHours,
      );

      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.startedRide(vehicle.name, ride.selectedRentalHours)),
        ),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.startRideFailed('$e'))),
      );
      return false;
    }
  }
}

class _ValidQrVehicle {
  final String qrValue;
  final String vehicleId;
  final String vehicleName;
  final LatLng fallbackLocation;

  const _ValidQrVehicle({
    required this.qrValue,
    required this.vehicleId,
    required this.vehicleName,
    required this.fallbackLocation,
  });
}
