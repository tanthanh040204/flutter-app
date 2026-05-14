/*
 * @file       mobile_home_tab.dart
 * @brief      Home tab: greets the user, shows balance and the current ride
 *             card. Reacts to MQTT-driven warnings and end-of-rental events.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_strings.dart';
import '../../models/error_codes.dart';
import '../../models/home_feed_item.dart';
import '../../providers/mobile_auth_provider.dart';
import '../../providers/mobile_ride_provider.dart';
import '../../services/protocol_codec.dart';
import '../../services/home_feed_fetcher.dart';
import '../bill_screen.dart';
import '../qr_scan_screen.dart';
import '../wallet_topup_screen.dart';
import '../usage_guide_screen.dart';
import '../../widgets/language_switch.dart';

/* Constants ---------------------------------------------------------- */
const Color kHeaderGradientStart = Color(0xFF1557FF);
const Color kHeaderGradientEnd = Color(0xFF2F80ED);
const String kCurrencyLocale = 'vi_VN';
const String kCurrencySymbol = 'đ';
const String kTuoiTreVehicleUrl = 'https://tuoitre.vn/xe.htm';
const String kTuoiTreWeatherUrl = 'https://tuoitre.vn/thoi-tiet.htm';
const String kOfficialWeatherUrl = 'https://nchmf.gov.vn/Kttvsite/vi-VN/1/thoi-tiet-1-15.html';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileHomeTab extends StatefulWidget {
  const MobileHomeTab({super.key});

  @override
  State<MobileHomeTab> createState() => _MobileHomeTabState();
}

/* Private classes ---------------------------------------------------- */
class _MobileHomeTabState extends State<MobileHomeTab> {
  bool _billShown = false;
  DateTime? _lastDeductedBillAt;
  late final TextEditingController _hoursCtrl;
  late final Future<List<HomeFeedItem>> _homeFeedFuture;

  @override
  void initState() {
    super.initState();
    _hoursCtrl = TextEditingController(text: '1');
    _homeFeedFuture = loadRemoteHomeFeedItems();
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    super.dispose();
  }

  bool _applyHours(BuildContext context) {
    final MobileRideProvider ride = context.read<MobileRideProvider>();
    final int? hours = int.tryParse(_hoursCtrl.text.trim());

    if (hours == null || hours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.readTr.invalidHours)),
      );
      return false;
    }

    ride.setSelectedRentalHours(hours);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings t = context.tr;
    final MobileAuthProvider auth = context.watch<MobileAuthProvider>();
    final MobileRideProvider ride = context.watch<MobileRideProvider>();
    final user = auth.currentUser;

    if (user == null) return const SizedBox.shrink();

    _handleRideSideEffects(auth, ride);

    final NumberFormat money = NumberFormat.currency(
      locale: t.moneyLocale,
      symbol: t.moneySymbol,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.home),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguageSwitch(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(
            user.fullName,
            user.email ?? user.phone ?? user.employeeCode,
            user.balance,
            user.depositLocked,
            money,
          ),
          const SizedBox(height: 16),
          if (!ride.hasActiveSession && ride.phase != RentalPhase.starting) ...[
            _buildRentalTimeCard(ride, money, t),
            const SizedBox(height: 16),
          ],
          _buildQuickActions(t),
          const SizedBox(height: 20),
          if (ride.warning != null) _buildWarningCard(ride),
          if (ride.lastError != null && !ride.hasActiveSession)
            _buildErrorCard(ride),
          const SizedBox(height: 12),
          _buildRideCard(ride),
          const SizedBox(height: 16),
          _buildDailyBriefingSection(t),
          const SizedBox(height: 16),
          _buildDailyNoticeOfferSection(t),
          const SizedBox(height: 16),
          _buildUsageGuideCard(t),
        ],
      ),
    );
  }

  void _handleRideSideEffects(
    MobileAuthProvider auth,
    MobileRideProvider ride,
  ) {
    if (ride.isEnded && ride.lastBill != null && !_billShown) {
      if (_lastDeductedBillAt != ride.lastBill!.endedAt) {
        auth.deductLocalBalance(ride.lastBill!.amount);
        _lastDeductedBillAt = ride.lastBill!.endedAt;
      }
      _billShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BillScreen(bill: ride.lastBill!)),
        );
      });
    }
    if (!ride.isEnded) _billShown = false;
  }

  Widget _buildHeader(
    String fullName,
    String userCode,
    int balance,
    int depositLocked,
    NumberFormat money,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kHeaderGradientStart, kHeaderGradientEnd],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr.hello(fullName),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            userCode,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _QuickCard(
                  title: context.tr.balance,
                  value: money.format(balance),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickCard(
                  title: context.tr.deposit,
                  value: money.format(depositLocked),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRentalTimeCard(
    MobileRideProvider ride,
    NumberFormat money,
    AppStrings t,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.enterRentalTime,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hoursCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: t.rentalHoursLabel,
              hintText: t.hourHint,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.timer_outlined),
            ),
            onChanged: (_) => _applyHours(context),
            onSubmitted: (_) => _applyHours(context),
          ),
          const SizedBox(height: 14),
          Text(
            t.selectedRentalHours(ride.selectedRentalHours),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            t.rentalFee(money.format(ride.selectedUsageFee)),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            t.depositFee(money.format(ride.pricing.depositAmount)),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            t.requiredTotal(money.format(ride.selectedTotalRequired)),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: kHeaderGradientStart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(AppStrings t) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WalletTopupScreen()),
            ),
            icon: const Icon(Icons.qr_code_2),
            label: Text(t.topUp),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () {
              if (!_applyHours(context)) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QrScanScreen()),
              );
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(t.scanQr),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningCard(MobileRideProvider ride) {
    final String w = ride.warning!;
    final bool severe = w == kEvtWarnOutOfBalance || w == kErrOutOfParkingZone;
    final String title = switch (w) {
      kEvtWarnLowBalance => 'Balance running low',
      kEvtWarnOutOfBalance => 'Out of balance — please return the bike',
      kErrOutOfParkingZone => 'Vehicle is outside a valid parking zone',
      _ => 'Warning',
    };
    final String body = switch (w) {
      kEvtWarnLowBalance =>
        'You only have enough for the current block. Please top up.',
      kEvtWarnOutOfBalance =>
        'Return the bike to a parking zone within 15 minutes to avoid '
            'a penalty.',
      kErrOutOfParkingZone =>
        'Move the bike to the nearest parking zone to end the ride.',
      _ => '',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: severe ? Colors.red.shade50 : Colors.orange.shade50,
        child: ListTile(
          leading: Icon(
            severe ? Icons.error : Icons.warning_amber,
            color: severe ? Colors.red : Colors.orange,
          ),
          title: Text(title),
          subtitle: Text(body),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: ride.clearWarning,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(MobileRideProvider ride) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Colors.red.shade50,
        child: ListTile(
          leading: const Icon(Icons.error, color: Colors.red),
          title: const Text('Could not start the ride'),
          subtitle: Text(ErrorMessages.describe(ride.lastError!)),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: ride.clearError,
          ),
        ),
      ),
    );
  }

  Widget _buildRideCard(MobileRideProvider ride) {
    if (!ride.hasActiveSession && ride.phase != RentalPhase.starting) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr.noRideTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(context.tr.noRideDesc),
          ],
        ),
      );
    }

    if (ride.phase == RentalPhase.starting) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            SizedBox(width: 14),
            Text('Unlocking the bike...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ride.isPaused
                ? 'Bike ${ride.currentBikeId ?? ''} — ${context.tr.pause}'
                : context.tr.vehicleInUse('Bike ${ride.currentBikeId ?? ''}'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            _formatSeconds(ride.liveRemainingSeconds),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: kHeaderGradientStart,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ride.isPaused
                ? '${context.tr.pause}: ${ride.effectivePricePerHour}đ/hour.'
                : '${context.tr.pricePerHour}: ${ride.pricing.pricePerHour}đ/hour.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: ride.isPaused ? ride.resumeRide : ride.pauseRide,
                  child: Text(
                    ride.isPaused ? context.tr.resume : context.tr.pause,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: ride.phase == RentalPhase.stopping
                      ? null
                      : ride.endRide,
                  child: Text(
                    ride.phase == RentalPhase.stopping
                        ? context.tr.processing
                        : context.tr.end,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildDailyBriefingSection(AppStrings t) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFEAF4FF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E8FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kHeaderGradientStart.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.newspaper, color: kHeaderGradientStart),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.dailyBriefingTitle,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t.dailyBriefingSubtitle(_todayLabel()),
                      style: const TextStyle(color: Colors.black54, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<HomeFeedItem>>(
            future: _homeFeedFuture,
            builder: (context, snapshot) {
              final List<HomeFeedItem> remoteItems = snapshot.data ?? const <HomeFeedItem>[];
              final List<HomeFeedItem> fallbackItems = _fallbackDailyFeedItems(t);
              final List<HomeFeedItem> items = <HomeFeedItem>[
                ...remoteItems.take(4),
                if (!remoteItems.any((item) => item.kind == HomeFeedKind.traffic))
                  fallbackItems.firstWhere((item) => item.kind == HomeFeedKind.traffic),
                if (!remoteItems.any((item) => item.kind == HomeFeedKind.weather))
                  fallbackItems.firstWhere((item) => item.kind == HomeFeedKind.weather),
              ].take(4).toList(growable: false);

              return Column(
                children: [
                  if (snapshot.connectionState == ConnectionState.waiting && remoteItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text(t.loadingDailyNews),
                        ],
                      ),
                    ),
                  for (int i = 0; i < items.length; i++) ...[
                    _DailyFeedCard(
                      item: items[i],
                      label: _feedKindLabel(items[i].kind, t),
                      accentColor: _feedKindColor(items[i].kind),
                      onTap: () => _openExternalUrl(items[i].url),
                      readMoreText: t.readMore,
                      liveText: items[i].isLive ? t.liveUpdated : t.dailyUpdated,
                    ),
                    if (i != items.length - 1) const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openExternalUrl(kTuoiTreVehicleUrl),
                          icon: const Icon(Icons.directions_car_filled_outlined),
                          label: Text(t.openTrafficNews),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openExternalUrl(kOfficialWeatherUrl),
                          icon: const Icon(Icons.cloud_outlined),
                          label: Text(t.openWeatherForecast),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDailyNoticeOfferSection(AppStrings t) {
    final List<_HomeHighlight> highlights = _dailyHighlights(t);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.campaign_outlined, color: kHeaderGradientStart),
            const SizedBox(width: 8),
            Text(
              t.noticeOfferTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < highlights.length; i++) ...[
          _HighlightCard(highlight: highlights[i]),
          if (i != highlights.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildUsageGuideCard(AppStrings t) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UsageGuideScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.menu_book_outlined, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.usageGuideTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.usageGuideCardDesc,
                    style: const TextStyle(color: Colors.white70, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  List<HomeFeedItem> _fallbackDailyFeedItems(AppStrings t) {
    final int seed = _dailySeed();

    final List<HomeFeedItem> traffic = t.vi
        ? <HomeFeedItem>[
            const HomeFeedItem(
              kind: HomeFeedKind.traffic,
              title: 'Gợi ý di chuyển hôm nay: ưu tiên đường nội bộ và làn xe chậm',
              summary: 'Trước khi thuê xe, hãy xem nhanh tình trạng giao thông và chọn tuyến ít giao cắt để đi an toàn hơn.',
              url: kTuoiTreVehicleUrl,
              source: 'Tuổi Trẻ Online',
            ),
            const HomeFeedItem(
              kind: HomeFeedKind.traffic,
              title: 'Giờ cao điểm: nên kiểm tra trạm trả xe trước khi xuất phát',
              summary: 'Nếu đi vào buổi sáng hoặc chiều tối, hãy xem trạm gần điểm đến để tránh mất thời gian tìm chỗ trả xe.',
              url: kTuoiTreVehicleUrl,
              source: 'Tuổi Trẻ Online',
            ),
            const HomeFeedItem(
              kind: HomeFeedKind.traffic,
              title: 'An toàn khi qua giao lộ: giảm tốc và quan sát hai bên',
              summary: 'Xe đạp nhỏ và dễ bị khuất tầm nhìn. Đừng tin hoàn toàn vào việc người khác đã thấy bạn, đời vốn không tử tế đến thế.',
              url: kTuoiTreVehicleUrl,
              source: 'Tuổi Trẻ Online',
            ),
          ]
        : <HomeFeedItem>[
            const HomeFeedItem(
              kind: HomeFeedKind.traffic,
              title: 'Today route tip: prefer inner streets and slow lanes',
              summary: 'Before renting a bike, quickly check traffic and choose a route with fewer crossings.',
              url: kTuoiTreVehicleUrl,
              source: 'Tuổi Trẻ Online',
            ),
            const HomeFeedItem(
              kind: HomeFeedKind.traffic,
              title: 'Peak hours: check the return station before leaving',
              summary: 'For morning or evening rides, check a nearby station at your destination first.',
              url: kTuoiTreVehicleUrl,
              source: 'Tuổi Trẻ Online',
            ),
            const HomeFeedItem(
              kind: HomeFeedKind.traffic,
              title: 'Intersection safety: slow down and look both ways',
              summary: 'Bikes are small and easy to miss. Do not assume everyone has seen you.',
              url: kTuoiTreVehicleUrl,
              source: 'Tuổi Trẻ Online',
            ),
          ];

    final List<HomeFeedItem> weather = t.vi
        ? <HomeFeedItem>[
            const HomeFeedItem(
              kind: HomeFeedKind.weather,
              title: 'Dự báo thời tiết hôm nay: kiểm tra mưa dông trước khi thuê xe',
              summary: 'Nếu trời có mưa lớn hoặc gió mạnh, hãy cân nhắc lộ trình ngắn và trả xe sớm tại trạm gần nhất.',
              url: kOfficialWeatherUrl,
              source: 'Trung tâm Dự báo KTTV Quốc gia',
            ),
            const HomeFeedItem(
              kind: HomeFeedKind.weather,
              title: 'Nắng nóng: mang nước và tránh chạy xe quá lâu giữa trưa',
              summary: 'Thời tiết oi bức dễ làm mất sức. Chuyến ngắn, đội mũ và nghỉ khi cần, nghe đơn giản mà nhiều người vẫn quên.',
              url: kOfficialWeatherUrl,
              source: 'Trung tâm Dự báo KTTV Quốc gia',
            ),
            const HomeFeedItem(
              kind: HomeFeedKind.weather,
              title: 'Chiều tối dễ có mưa: nhớ kiểm tra phanh trước khi rời trạm',
              summary: 'Mặt đường ướt làm quãng đường phanh dài hơn. Chậm một chút còn hơn biểu diễn vật lý không tự nguyện.',
              url: kOfficialWeatherUrl,
              source: 'Trung tâm Dự báo KTTV Quốc gia',
            ),
          ]
        : <HomeFeedItem>[
            const HomeFeedItem(
              kind: HomeFeedKind.weather,
              title: 'Today weather: check rain and storms before renting',
              summary: 'If heavy rain or strong wind is expected, choose a short route and return the bike earlier.',
              url: kOfficialWeatherUrl,
              source: 'National Center for Hydro-Meteorological Forecasting',
            ),
            const HomeFeedItem(
              kind: HomeFeedKind.weather,
              title: 'Hot weather: bring water and avoid long noon rides',
              summary: 'Heat drains energy quickly. Keep the ride short, wear a hat, and rest when needed.',
              url: kOfficialWeatherUrl,
              source: 'National Center for Hydro-Meteorological Forecasting',
            ),
            const HomeFeedItem(
              kind: HomeFeedKind.weather,
              title: 'Evening rain risk: check brakes before leaving',
              summary: 'Wet roads increase braking distance. Slow down a little. Physics is not interested in excuses.',
              url: kOfficialWeatherUrl,
              source: 'National Center for Hydro-Meteorological Forecasting',
            ),
          ];

    return <HomeFeedItem>[
      traffic[seed % traffic.length],
      weather[(seed + 1) % weather.length],
    ];
  }

  List<_HomeHighlight> _dailyHighlights(AppStrings t) {
    final int seed = _dailySeed();
    final List<_HomeHighlight> notices = t.vi
        ? <_HomeHighlight>[
            const _HomeHighlight(
              icon: Icons.battery_charging_full,
              color: Color(0xFF2563EB),
              title: 'Nhắc nhẹ hôm nay',
              body: 'Chọn xe còn trên 30% pin để chuyến đi mượt hơn. Xe hết pin giữa đường thì thơ mộng lắm, nếu bạn thích đẩy bộ.',
            ),
            const _HomeHighlight(
              icon: Icons.health_and_safety_outlined,
              color: Color(0xFF16A34A),
              title: 'Kiểm tra an toàn',
              body: 'Trước khi chạy, bóp thử phanh và nhìn nhanh bánh xe. Mất 5 giây, cứu được cả một buổi chiều cáu bẳn.',
            ),
            const _HomeHighlight(
              icon: Icons.local_parking_outlined,
              color: Color(0xFF7C3AED),
              title: 'Trả xe đúng trạm',
              body: 'Kết thúc chuyến đi tại trạm hợp lệ để tránh lỗi trả xe và phí phát sinh không đáng có.',
            ),
          ]
        : <_HomeHighlight>[
            const _HomeHighlight(
              icon: Icons.battery_charging_full,
              color: Color(0xFF2563EB),
              title: 'Today reminder',
              body: 'Pick a bike above 30% battery for a smoother ride. Pushing a dead bike is character development nobody asked for.',
            ),
            const _HomeHighlight(
              icon: Icons.health_and_safety_outlined,
              color: Color(0xFF16A34A),
              title: 'Safety check',
              body: 'Test the brakes and glance at the wheels before riding. Five seconds, fewer regrets.',
            ),
            const _HomeHighlight(
              icon: Icons.local_parking_outlined,
              color: Color(0xFF7C3AED),
              title: 'Return at a valid station',
              body: 'End your trip at a valid station to avoid return errors and unnecessary extra fees.',
            ),
          ];

    final List<_HomeHighlight> offers = t.vi
        ? <_HomeHighlight>[
            const _HomeHighlight(
              icon: Icons.card_giftcard,
              color: Color(0xFFF97316),
              title: 'Ưu đãi hôm nay',
              body: 'Gợi ý: thuê 1 giờ cho chuyến ngắn trong khuôn viên, vừa đủ đi việc cần mà không khóa tiền quá lâu.',
            ),
            const _HomeHighlight(
              icon: Icons.savings_outlined,
              color: Color(0xFFDB2777),
              title: 'Mẹo tiết kiệm',
              body: 'Canh sẵn trạm trả xe gần điểm đến trước khi quét QR. Đi lạc rồi đổ lỗi cho app thì app cũng biết buồn đấy.',
            ),
            const _HomeHighlight(
              icon: Icons.stars_outlined,
              color: Color(0xFF0891B2),
              title: 'Chuyến đi thông minh',
              body: 'Dùng tab Trạm xe để chọn xe gần nhất, sau đó mới quét QR. Quy trình nhỏ, đỡ rối lớn.',
            ),
          ]
        : <_HomeHighlight>[
            const _HomeHighlight(
              icon: Icons.card_giftcard,
              color: Color(0xFFF97316),
              title: 'Today offer',
              body: 'Tip: choose 1 hour for short campus rides, enough for quick errands without locking too much balance.',
            ),
            const _HomeHighlight(
              icon: Icons.savings_outlined,
              color: Color(0xFFDB2777),
              title: 'Saving tip',
              body: 'Check a return station near your destination before scanning QR. Less wandering, fewer app-blaming ceremonies.',
            ),
            const _HomeHighlight(
              icon: Icons.stars_outlined,
              color: Color(0xFF0891B2),
              title: 'Smart ride',
              body: 'Use the Stations tab to find the nearest bike first, then scan QR. Tiny process, fewer disasters.',
            ),
          ];

    return <_HomeHighlight>[
      notices[seed % notices.length],
      offers[(seed + 1) % offers.length],
    ];
  }

  String _feedKindLabel(HomeFeedKind kind, AppStrings t) {
    return switch (kind) {
      HomeFeedKind.traffic => t.traffic,
      HomeFeedKind.weather => t.weather,
    };
  }

  Color _feedKindColor(HomeFeedKind kind) {
    return switch (kind) {
      HomeFeedKind.traffic => const Color(0xFF2563EB),
      HomeFeedKind.weather => const Color(0xFF0EA5E9),
    };
  }

  int _dailySeed() {
    final DateTime now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  String _todayLabel() {
    final DateTime now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  Future<void> _openExternalUrl(String url) async {
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatSeconds(int seconds) {
    final String h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final String m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final String s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final String value;

  const _QuickCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyFeedCard extends StatelessWidget {
  final HomeFeedItem item;
  final String label;
  final String liveText;
  final String readMoreText;
  final Color accentColor;
  final VoidCallback onTap;

  const _DailyFeedCard({
    required this.item,
    required this.label,
    required this.liveText,
    required this.readMoreText,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    liveText,
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, height: 1.25),
            ),
            const SizedBox(height: 6),
            Text(
              item.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, height: 1.35),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.source,
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  readMoreText,
                  style: TextStyle(color: accentColor, fontWeight: FontWeight.w900),
                ),
                Icon(Icons.chevron_right, color: accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final _HomeHighlight highlight;

  const _HighlightCard({required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: highlight.color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: highlight.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(highlight.icon, color: highlight.color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  highlight.body,
                  style: const TextStyle(color: Colors.black54, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHighlight {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _HomeHighlight({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
