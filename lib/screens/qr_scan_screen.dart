import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét QR mở khóa xe')),
      body: MobileScanner(
        onDetect: (capture) async {
          if (handled) return;
          final code = capture.barcodes.first.rawValue;
          if (code == null) return;
          handled = true;
          final vehicleId = _extractVehicleId(code);
          if (!mounted) return;
          await _showConfirm(context, vehicleId);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  String _extractVehicleId(String raw) {
    if (raw.startsWith('VEHICLE:')) return raw.replaceFirst('VEHICLE:', '').trim();
    return raw.trim();
  }

  Future<void> _showConfirm(BuildContext context, String vehicleId) async {
    final auth = context.read<MobileAuthProvider>();
    final ride = context.read<MobileRideProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final vehicle = ride.vehicle?.id == vehicleId
        ? ride.vehicle!
        : RentalVehicle(
            id: vehicleId,
            name: 'Xe ${vehicleId.replaceAll(RegExp(r'[^0-9]'), '')}',
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
            lastLocation: const LatLng(10.7791, 106.6998),
            updatedAt: DateTime.now(),
          );

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Bạn muốn sử dụng ${vehicle.name}?'),
        content: Text(
          user.balance >= ride.pricing.minimumRequiredBalance
              ? 'Tài khoản đủ điều kiện. Phí khởi tạo: 10.000đ / giờ + 10.000đ tiền cọc.'
              : 'Số dư hiện tại chưa đủ 20.000đ để sử dụng xe.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: user.balance >= ride.pricing.minimumRequiredBalance ? () => Navigator.pop(context, true) : null, child: const Text('Có')),
        ],
      ),
    );

    if (ok == true) {
      await context.read<MobileUserRepo>().startRide(
            user: user,
            vehicle: vehicle,
            pricing: ride.pricing,
          );
    }
  }
}
