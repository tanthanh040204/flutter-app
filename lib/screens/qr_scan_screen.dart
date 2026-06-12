/*
 * @file       qr_scan_screen.dart
 * @brief      QR scanning screen. Triggers START_RENTAL over MQTT after the
 *             selected rental duration is confirmed.
 */

/* Imports ------------------------------------------------------------ */
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/error_codes.dart';
import '../providers/ble_relay_provider.dart';
import '../providers/mobile_auth_provider.dart';
import '../providers/mobile_ride_provider.dart';

/* Constants ---------------------------------------------------------- */
const String kQrVehiclePrefix = 'VEHICLE:';

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
    final AppStrings t = context.tr;

    return Scaffold(
      appBar: AppBar(title: Text(t.scanQrUnlockTitle)),
      body: MobileScanner(
        onDetect: (capture) async {
          if (handled) return;
          final String? code = capture.barcodes.first.rawValue;
          if (code == null || code.trim().isEmpty) return;
          handled = true;
          final String vehicleId = _extractVehicleId(code);
          final NavigatorState navigator = Navigator.of(context);
          if (!mounted) return;
          final bool started = await _showConfirm(context, vehicleId);
          if (!mounted) return;
          if (started) {
            navigator.pop();
          } else {
            setState(() => handled = false);
          }
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

  Future<bool> _showConfirm(BuildContext context, String vehicleId) async {
    final AppStrings t = context.readTr;
    final MobileAuthProvider auth = context.read<MobileAuthProvider>();
    final MobileRideProvider ride = context.read<MobileRideProvider>();
    final user = auth.currentUser;
    if (user == null) return false;

    final NumberFormat money = NumberFormat.currency(
      locale: t.moneyLocale,
      symbol: t.moneySymbol,
    );
    final int requiredAmount = ride.selectedTotalRequired;
    final bool enoughBalance = user.balance >= requiredAmount;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.confirmUseVehicle(vehicleId)),
        content: Text(
          enoughBalance
              ? t.confirmRideEnoughBalance(
                  vehicleId: vehicleId,
                  hours: ride.selectedRentalHours,
                  usageFee: money.format(ride.selectedUsageFee),
                  depositAmount: money.format(ride.pricing.depositAmount),
                  requiredAmount: money.format(requiredAmount),
                )
              : t.confirmRideNotEnoughBalance(
                  vehicleId: vehicleId,
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
            onPressed: enoughBalance ? () => Navigator.pop(context, true) : null,
            child: Text(t.yes),
          ),
        ],
      ),
    );

    if (ok != true) return false;
    if (!context.mounted) return false;

    final BleRelayProvider ble = context.read<BleRelayProvider>();
    BuildContext? loadingCtx;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dCtx) {
          loadingCtx = dCtx;
          return Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(width: 14),
                    Text(t.connectingBle),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    await ble.warmUpFor(vehicleId, timeout: const Duration(seconds: 10));
    if (loadingCtx != null && loadingCtx!.mounted) {
      Navigator.of(loadingCtx!).pop();
    }
    if (!context.mounted) return false;

    final bool published = await ride.startRental(
      bikeId: vehicleId,
      rentalHours: ride.selectedRentalHours,
    );
    if (!context.mounted) return false;
    if (!published) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.errorDescription(ride.lastError ?? kErrUnknown)),
        ),
      );
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.startedRide(vehicleId, ride.selectedRentalHours)),
      ),
    );
    return true;
  }
}

/* End of file -------------------------------------------------------- */
