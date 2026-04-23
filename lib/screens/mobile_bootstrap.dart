/*
 * @file       mobile_bootstrap.dart
 * @brief      Root router that dispatches to onboarding, login or home.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mobile_auth_provider.dart';
import 'home_mobile_shell.dart';
import 'login_register_screen.dart';
import 'onboarding_screen.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

/* Public classes ----------------------------------------------------- */
class MobileBootstrap extends StatelessWidget {
  const MobileBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    final MobileAuthProvider auth = context.watch<MobileAuthProvider>();

    if (auth.showOnboarding) {
      return const OnboardingScreen();
    }

    if (!auth.isLoggedIn) {
      return const LoginRegisterScreen();
    }

    return const HomeMobileShell();
  }
}

/* Private classes ---------------------------------------------------- */
/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
