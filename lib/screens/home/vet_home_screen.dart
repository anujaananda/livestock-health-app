import 'package:flutter/material.dart';

import '../vet_booking/vet_appointments_screen.dart';
import '../vet_booking/vet_dashboard_screen.dart';
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

  // ================= TAB SWITCH METHOD =================
  void _switchTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF9),

      // ================= BODY =================
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Dashboard with callback
          VetDashboardScreen(
            userName: widget.userName,
            onAppointmentsTap: () => _switchTab(1),
          ),
          // Appointments
          const VetAppointmentsScreen(showBackButton: false),
          // Profile
          const VetProfileScreen(),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
