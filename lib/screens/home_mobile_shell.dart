/*
 * @file       home_mobile_shell.dart
 * @brief      Bottom-navigation shell hosting the five main tabs.
 */

/* Imports ------------------------------------------------------------ */
import 'package:flutter/material.dart';

import 'tabs/mobile_home_tab.dart';
import 'tabs/mobile_more_tab.dart';
import 'tabs/mobile_notifications_tab.dart';
import 'tabs/mobile_ride_tab.dart';
import 'tabs/mobile_stations_tab.dart';

/* Constants ---------------------------------------------------------- */
/* Enums -------------------------------------------------------------- */
/* Typedef / Function types ------------------------------------------ */

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
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Trạm xe',
          ),
          NavigationDestination(
            icon: Icon(Icons.electric_bike_outlined),
            selectedIcon: Icon(Icons.electric_bike),
            label: 'Thông số',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Mở rộng',
          ),
        ],
      ),
    );
  }
}

/* Public functions --------------------------------------------------- */
/* Private functions -------------------------------------------------- */
/* Entry point -------------------------------------------------------- */
/* End of file -------------------------------------------------------- */
