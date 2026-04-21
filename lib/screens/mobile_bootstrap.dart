import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mobile_auth_provider.dart';
import 'home_mobile_shell.dart';
import 'login_register_screen.dart';
import 'onboarding_screen.dart';

class MobileBootstrap extends StatelessWidget {
  const MobileBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<MobileAuthProvider>();

    if (auth.showOnboarding) {
      return const OnboardingScreen();
    }

    if (!auth.isLoggedIn) {
      return const LoginRegisterScreen();
    }

    return const HomeMobileShell();
  }
}
