/*
 * @file       main.dart
 * @brief      Application entry point. Initializes Firebase + MQTT and wires
 *             providers.
 */

/* Imports ------------------------------------------------------------ */
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'firebase_options.dart';
import 'providers/mobile_auth_provider.dart';
import 'providers/mobile_notice_provider.dart';
import 'providers/mobile_ride_provider.dart';
import 'providers/mobile_stations_provider.dart';
import 'providers/mobile_telemetry_provider.dart';
import 'providers/mobile_wallet_provider.dart';
import 'screens/mobile_bootstrap.dart';
import 'services/mobile_user_repo.dart';
import 'services/mqtt_service.dart';

/* Constants ---------------------------------------------------------- */
const String kAppTitle = 'UTE-go';

/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class TnGoUserApp extends StatelessWidget {
  const TnGoUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MobileUserRepo>(create: (_) => MobileUserRepo.instance),
        ChangeNotifierProvider<MqttService>(
          create: (_) => MqttService(),
          lazy: false,
        ),
        ChangeNotifierProvider<MobileTelemetryProvider>(
          create: (context) =>
              MobileTelemetryProvider(context.read<MqttService>()),
          lazy: false,
        ),
        ChangeNotifierProvider(
          create: (context) =>
              MobileAuthProvider(context.read<MobileUserRepo>()),
        ),
        ChangeNotifierProxyProvider<MobileAuthProvider, MobileRideProvider>(
          create: (context) => MobileRideProvider(
            context.read<MqttService>(),
            telemetry: context.read<MobileTelemetryProvider>(),
          ),
          update: (context, auth, previous) {
            final MobileRideProvider provider = previous ??
                MobileRideProvider(
                  context.read<MqttService>(),
                  telemetry: context.read<MobileTelemetryProvider>(),
                );
            provider.bindUser(auth.currentUser);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<MobileAuthProvider, MobileWalletProvider>(
          create: (context) =>
              MobileWalletProvider(context.read<MqttService>()),
          update: (context, auth, previous) {
            final MobileWalletProvider provider =
                previous ?? MobileWalletProvider(context.read<MqttService>());
            provider.bindUser(auth.currentUser);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<MobileAuthProvider, MobileNoticeProvider>(
          create: (context) =>
              MobileNoticeProvider(context.read<MobileUserRepo>()),
          update: (context, auth, previous) =>
              previous!..bindUser(auth.currentUser?.uid),
        ),
        ChangeNotifierProvider(create: (_) => MobileStationsProvider()),
      ],
      child: MaterialApp(
        title: kAppTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MobileBootstrap(),
      ),
    );
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */

/* Entry point -------------------------------------------------------- */
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    /* fallback demo mode */
  }

  runApp(const TnGoUserApp());
}

/* End of file -------------------------------------------------------- */
