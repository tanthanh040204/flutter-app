/*
 * @file       qr_scan_screen.dart
 * @brief      QR scanning screen. Triggers the START_RENTAL workflow over MQTT
 *             once a vehicle id is detected.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/error_codes.dart';
import '../providers/mobile_auth_provider.dart';
import '../providers/mobile_ride_provider.dart';

/* Constants ---------------------------------------------------------- */
const String kQrVehiclePrefix = 'VEHICLE:';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

/* Private classes ---------------------------------------------------- */
class _QrScanScreenState extends State<QrScanScreen> {
  bool handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét QR mở khóa xe')),
      body: MobileScanner(
        onDetect: (capture) async {
          if (handled) return;
          final String? code = capture.barcodes.first.rawValue;
          if (code == null) return;
          handled = true;
          final String vehicleId = _extractVehicleId(code);
          if (!mounted) return;
          await _showConfirm(context, vehicleId);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  String _extractVehicleId(String raw) {
    if (raw.startsWith(kQrVehiclePrefix)) {
      return raw.replaceFirst(kQrVehiclePrefix, '').trim();
    }
    return raw.trim();
  }

  Future<void> _showConfirm(BuildContext context, String vehicleId) async {
    final MobileAuthProvider auth = context.read<MobileAuthProvider>();
    final MobileRideProvider ride = context.read<MobileRideProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final bool enoughBalance =
        user.balance >= ride.pricing.minimumRequiredBalance;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Bạn muốn sử dụng xe $vehicleId?'),
        content: Text(
          enoughBalance
              ? 'Tài khoản đủ điều kiện. Phí khởi tạo: '
                '${ride.pricing.pricePerHour}đ / giờ + '
                '${ride.pricing.depositAmount}đ tiền cọc.'
              : 'Số dư hiện tại chưa đủ '
                '${ride.pricing.minimumRequiredBalance}đ để sử dụng xe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: enoughBalance
                ? () => Navigator.pop(context, true)
                : null,
            child: const Text('Có'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (!context.mounted) return;

    final bool published = await ride.startRental(bikeId: vehicleId);
    if (!context.mounted) return;
    if (!published) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorMessages.describe(
            ride.lastError ?? kErrUnknown,
          )),
        ),
      );
    }
  }
}

/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
