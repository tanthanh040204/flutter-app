/*
 * @file       home_mobile_shell.dart
 * @brief      Bottom-navigation shell hosting the five main tabs.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'tabs/mobile_home_tab.dart';
import 'tabs/mobile_more_tab.dart';
import 'tabs/mobile_notifications_tab.dart';
import 'tabs/mobile_ride_tab.dart';
import 'tabs/mobile_stations_tab.dart';

/* Public classes ----------------------------------------------------- */
class HomeMobileShell extends StatefulWidget {
  const HomeMobileShell({super.key});

  @override
  State<HomeMobileShell> createState() => _HomeMobileShellState();
}

/* Private classes ---------------------------------------------------- */
class _HomeMobileShellState extends State<HomeMobileShell> {
  int index = 0;

  final List<Widget> pages = const [
    MobileHomeTab(),
    MobileStationsTab(),
    MobileRideTab(),
    MobileNotificationsTab(),
    MobileMoreTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final AppStrings t = context.tr;

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: t.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.location_on_outlined),
            selectedIcon: const Icon(Icons.location_on),
            label: t.stations,
          ),
          NavigationDestination(
            icon: const Icon(Icons.electric_bike_outlined),
            selectedIcon: const Icon(Icons.electric_bike),
            label: t.rideStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_outlined),
            selectedIcon: const Icon(Icons.notifications),
            label: t.notifications,
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view),
            label: t.more,
          ),
        ],
      ),
    );
  }
}

/* End of file -------------------------------------------------------- */
