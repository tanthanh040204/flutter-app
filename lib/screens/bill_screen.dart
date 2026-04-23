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
    final bool      isViolation = bill.status != kStatusOk;
    final DateFormat dateFmt    = DateFormat('HH:mm dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Hóa đơn')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              isViolation ? Icons.warning_amber : Icons.check_circle,
              color: isViolation ? Colors.orange : Colors.green,
              size: 80,
            ),
            const SizedBox(height: 12),
            Text(
              isViolation
                  ? 'Chuyến đi đã kết thúc (có vi phạm)'
                  : 'Chuyến đi đã kết thúc',
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
            if (isViolation) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    ErrorMessages.describe(bill.status),
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
    if (status == kStatusOk) return 'Kết thúc thành công';
    return status;
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

/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
