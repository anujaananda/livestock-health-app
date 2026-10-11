import 'package:flutter/material.dart';

import '../vet_booking/vet_appointments_screen.dart';
import '../vet_booking/vet_dashboard_screen.dart';
import '../vet_booking/vet_emergency_alerts_screen.dart';
import '../vet_booking/vet_profile_screen.dart';

class VetHomeScreen extends StatefulWidget {
  final String userName;

  const VetHomeScreen({super.key, required this.userName});

  @override
  State<VetHomeScreen> createState() => _VetHomeScreenState();
}

class _VetHomeScreenState extends State<VetHomeScreen> {
  static const Color primaryGreen = Color(0xFF20B769);

  int _selectedIndex = 0;
  int _activeAlertsCount = 0;

  // ================= TAB SWITCH =================
  void _switchTab(int index) {
    setState(() => _selectedIndex = index);
  }

  // ================= ALERTS COUNT UPDATE =================
  void _updateAlertsCount(int count) {
    if (_activeAlertsCount != count && mounted) {
      setState(() => _activeAlertsCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF9),

      // ================= BODY =================
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // 0 - Dashboard
          VetDashboardScreen(
            userName: widget.userName,
            onAppointmentsTap: () => _switchTab(1),
            onAlertsTap: () => _switchTab(2),
            onAlertsCountChanged: _updateAlertsCount,
          ),

          // 1 - Appointments
          const VetAppointmentsScreen(showBackButton: false),

          // 2 - Emergency Alerts
          const VetEmergencyAlertsScreen(showBackButton: false),

          // 3 - Profile ✅ const අයින් කරා
          VetProfileScreen(),
        ],
      ),

      // ================= BOTTOM NAVIGATION =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: const Color(0xFF7D8B83),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Appointments',
          ),

          // ✅ Alerts tab with red badge
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.warning_amber_outlined),
                if (_activeAlertsCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_activeAlertsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.warning_amber_rounded),
                if (_activeAlertsCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_activeAlertsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Alerts',
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
