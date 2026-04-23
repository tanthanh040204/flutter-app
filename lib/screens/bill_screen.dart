/*
 * @file       bill_screen.dart
 * @brief      Displays the final rental bill after END_RENTAL is received.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/error_codes.dart';
import '../models/rental_bill.dart';
import '../providers/mobile_ride_provider.dart';

/* Constants ---------------------------------------------------------- */
const String kCurrencyLocale = 'vi_VN';
const String kCurrencySymbol = 'đ';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class BillScreen extends StatelessWidget {
  final RentalBill bill;

  const BillScreen({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final NumberFormat money = NumberFormat.currency(
      locale: kCurrencyLocale,
      symbol: kCurrencySymbol,
    );
    final _BillUiState uiState = _stateForStatus(bill.status);
    final DateFormat dateFmt    = DateFormat('HH:mm dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Hóa đơn')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              uiState.icon,
              color: uiState.iconColor,
              size: 80,
            ),
            const SizedBox(height: 12),
            Text(
              uiState.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _Row(label: 'Mã người dùng',  value: bill.userId),
                    _Row(label: 'Kết thúc lúc',   value: dateFmt.format(bill.endedAt)),
                    _Row(label: 'Trạng thái',     value: _statusText(bill.status)),
                    const Divider(),
                    _Row(
                      label: 'Tổng thanh toán',
                      value: money.format(bill.amount),
                      bold:  true,
                    ),
                  ],
                ),
              ),
            ),
            if (uiState.detail != null) ...[
              const SizedBox(height: 16),
              Card(
                color: uiState.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    uiState.detail!,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],
            const Spacer(),
            FilledButton(
              onPressed: () {
                context.read<MobileRideProvider>().acknowledgeBill();
                Navigator.of(context).pop();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(String status) {
    final _BillUiState uiState = _stateForStatus(status);
    return uiState.statusLabel;
  }

  _BillUiState _stateForStatus(String status) {
    switch (status) {
      case kStatusOk:
        return _BillUiState(
          title: 'Chuyến đi đã kết thúc',
          statusLabel: 'Kết thúc thành công',
          icon: Icons.check_circle,
          iconColor: Colors.green,
          cardColor: Colors.green.shade50,
          detail: null,
        );
      case kErrTimeLimitWarning:
        return _BillUiState(
          title: 'Chuyến đi đã kết thúc (cảnh báo)',
          statusLabel: 'Kết thúc khi hết thời gian cảnh báo',
          icon: Icons.warning_amber,
          iconColor: Colors.orange,
          cardColor: Colors.orange.shade50,
          detail: 'Bạn đã về bãi trong thời gian cảnh báo 15 phút.',
        );
      case kErrTimeLimitExceeded:
        return _BillUiState(
          title: 'Chuyến đi đã kết thúc (vi phạm)',
          statusLabel: 'Vượt thời gian cảnh báo 15 phút',
          icon: Icons.error,
          iconColor: Colors.red,
          cardColor: Colors.red.shade50,
          detail:
              'Xe vẫn ngoài bãi sau 15 phút cảnh báo. Hệ thống đã kết thúc chuyến đi và áp dụng xử lý vi phạm.',
        );
      default:
        return _BillUiState(
          title: 'Chuyến đi đã kết thúc',
          statusLabel: status,
          icon: Icons.info,
          iconColor: Colors.blueGrey,
          cardColor: Colors.blueGrey.shade50,
          detail: ErrorMessages.describe(status),
        );
    }
  }
}

/* Private classes ---------------------------------------------------- */
class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool   bold;

  const _Row({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle? valueStyle = bold
        ? const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

class _BillUiState {
  final String title;
  final String statusLabel;
  final IconData icon;
  final Color iconColor;
  final Color cardColor;
  final String? detail;

  const _BillUiState({
    required this.title,
    required this.statusLabel,
    required this.icon,
    required this.iconColor,
    required this.cardColor,
    required this.detail,
  });
}

/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
