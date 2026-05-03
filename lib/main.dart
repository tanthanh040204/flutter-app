import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'firebase_options.dart';
import 'providers/app_language_provider.dart';
import 'providers/mobile_auth_provider.dart';
import 'providers/mobile_notice_provider.dart';
import 'providers/mobile_ride_provider.dart';
import 'providers/mobile_stations_provider.dart';
import 'screens/mobile_bootstrap.dart';
import 'services/mobile_user_repo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // fallback demo mode
  }

  runApp(const TnGoUserApp());
}

class TnGoUserApp extends StatelessWidget {
  const TnGoUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MobileUserRepo>(
          create: (_) => MobileUserRepo.instance,
        ),
        ChangeNotifierProvider(
          create: (_) => AppLanguageProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => MobileAuthProvider(
            context.read<MobileUserRepo>(),
          ),
        ),
        ChangeNotifierProxyProvider<MobileAuthProvider, MobileRideProvider>(
          create: (context) => MobileRideProvider(
            context.read<MobileUserRepo>(),
          ),
          update: (context, auth, previous) =>
              previous!..bindUser(auth.currentUser?.uid),
        ),
        ChangeNotifierProxyProvider<MobileAuthProvider, MobileNoticeProvider>(
          create: (context) => MobileNoticeProvider(
            context.read<MobileUserRepo>(),
          ),
          update: (context, auth, previous) =>
              previous!..bindUser(auth.currentUser?.uid),
        ),
     ChangeNotifierProvider(
  create: (_) => MobileStationsProvider(),
),
      ],
      child: Consumer<AppLanguageProvider>(
        builder: (context, language, _) {
          return MaterialApp(
            title: 'UTE-go',
            debugShowCheckedModeBanner: false,
            locale: language.locale,
            theme: AppTheme.lightTheme,
            home: const MobileBootstrap(),
          );
        },
      ),
    );
  }
}
