import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/mobile_auth_provider.dart';
import '../providers/mobile_ride_provider.dart';
import '../services/mobile_user_repo.dart';

Future<void> showExtendRideSheet(BuildContext context) async {
  final auth = context.read<MobileAuthProvider>();
  final ride = context.read<MobileRideProvider>();
  final repo = context.read<MobileUserRepo>();
  final user = auth.currentUser;
  final session = ride.session;

  if (user == null || session == null) return;

  final ctl = TextEditingController(text: '1');
  final t = context.readTr;
  final money = NumberFormat.currency(locale: t.moneyLocale, symbol: t.moneySymbol);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final sheetT = sheetContext.tr;
          final extraHours = (int.tryParse(ctl.text.trim()) ?? 1).clamp(1, 24).toInt();
          final extraFee = session.pricePerHour * extraHours;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sheetT.extendRide, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                  controller: ctl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: sheetT.extraHoursLabel,
                    hintText: sheetT.hourHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.more_time),
                  ),
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 14),
                Text(sheetT.extraHours(extraHours), style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(sheetT.extraFee(money.format(extraFee))),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    try {
                      await repo.extendRide(user: user, session: session, extraHours: extraHours);
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(sheetT.extendedRide(extraHours))),
                      );
                    } catch (e) {
                      if (!sheetContext.mounted) return;
                      ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(sheetT.confirmExtend),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  ctl.dispose();
}
