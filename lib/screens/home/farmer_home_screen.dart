import 'dart:async';

import 'package:flutter/material.dart';

// ================= VET BOOKING IMPORTS =================
import '../vet_booking/find_vet_screen.dart';
import '../vet_booking/my_appointments_screen.dart';
import '../vet_booking/farmer_profile_screen.dart';
import '../farmer/my_animals_screen.dart';

import '../../features/health_reminder/screens/notification_screen.dart';
import '../../features/health_reminder/screens/reminders_screen.dart';

class FarmerHomeScreen extends StatefulWidget {
  final String userName;

  const FarmerHomeScreen({super.key, this.userName = 'Farmer'});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBanner = 0;
  int _selectedIndex = 0;

  static const Color primaryGreen = Color(0xFF20B769);
  static const Color darkGreen = Color(0xFF176B43);

  final List<Map<String, String>> _banners = [
    {
      'image': 'assets/images/farmer_home_banner.png',
      'title': 'Healthy Livestock\nStronger Tomorrow',
      'subtitle': '',
    },
    {
      'image': 'assets/images/shelter_banner.png',
      'title': 'Safe Shelter & Hygiene',
      'subtitle': 'A clean environment keeps animals healthy',
    },
    {
      'image': 'assets/images/vaccination_banner.png',
      'title': 'Vaccination & Prevention',
      'subtitle': 'Prevent diseases, ensure productivity',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_bannerController.hasClients) return;
      final nextPage = (_currentBanner + 1) % _banners.length;
      _bannerController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  // ================= NAVIGATION METHODS =================

  // ================= FIND A VET (Step 1) =================
  void _openFindVet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindVetScreen()),
    );
  }

  // ================= MY APPOINTMENTS =================
  void _openMyAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyAppointmentsScreen()),
    );
  }

  // ================= FARMER PROFILE =================
  void _openFarmerProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FarmerProfileScreen()),
    );
  }

  void _openMyAnimals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyAnimalsScreen()),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    );
  }

  void _openReminders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RemindersScreen()),
    );
  }

  void _openHealthGuide(int index) {
    _comingSoon('Health Guide');
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be added soon'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkGreen,
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF9),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ================= HEADER =================
                    ClipPath(
                      clipper: HomeHeaderClipper(),
                      child: Container(
                        width: double.infinity,
                        height: 165,
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 35),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF42B97A),
                              Color(0xFF6DCE96),
                              Color(0xFF91DDB0),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _comingSoon('Menu'),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.menu_rounded,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Text(
                                    'Livestock Health',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    IconButton(
                                      onPressed: _openNotifications,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.notifications_none_rounded,
                                        color: Colors.white,
                                        size: 27,
                                      ),
                                    ),
                                    Positioned(
                                      right: 1,
                                      top: 0,
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE85D68),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 17),
                            Text(
                              'Hello, ${widget.userName}!',
                              style: const TextStyle(
                                color: Color(0xFFF4FFF7),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Keep your animals healthy and productive',
                              style: TextStyle(
                                color: Color(0xFFE5F7EB),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ================= BANNER =================
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        controller: _bannerController,
                        itemCount: _banners.length,
                        onPageChanged: (index) {
                          setState(() => _currentBanner = index);
                          _startBannerTimer();
                        },
                        itemBuilder: (context, index) {
                          final banner = _banners[index];
                          return _buildBanner(
                            image: banner['image']!,
                            title: banner['title']!,
                            subtitle: banner['subtitle']!,
                            isOriginalBanner: index == 0,
                            onTap: () => _openHealthGuide(index),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ================= BANNER DOTS =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_banners.length, (index) {
                        final selected = _currentBanner == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: selected ? 18 : 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: selected
                                ? primaryGreen
                                : const Color(0xFFCDE7D7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 22),

                    // ================= HOME CARDS =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // ================= MY ANIMALS =================
                          _buildHomeCard(
                            title: 'My Animals',
                            subtitle: 'View and manage your animals',
                            icon: Icons.pets_rounded,
                            backgroundColor: const Color(0xFFE5F7EA),
                            iconBackground: const Color(0xFFCFF0D9),
                            iconColor: const Color(0xFF16894E),
                            onTap: _openMyAnimals,
                          ),
                          const SizedBox(height: 14),

                          // ================= EMERGENCY =================
                          _buildHomeCard(
                            title: 'EMERGENCY',
                            subtitle: 'Contact a Vet Now',
                            icon: Icons.emergency_rounded,
                            backgroundColor: const Color(0xFFFFE8E8),
                            iconBackground: const Color(0xFFFFD7D7),
                            iconColor: const Color(0xFFD95360),
                            onTap: () => _comingSoon('Emergency'),
                          ),
                          const SizedBox(height: 14),

                          // ================= CONSULT A VET → FIND A VET =================
                          _buildHomeCard(
                            title: 'Consult a Vet',
                            subtitle: 'Get professional advice',
                            icon: Icons.medical_services_outlined,
                            backgroundColor: const Color(0xFFF0EBFA),
                            iconBackground: const Color(0xFFE4D9F5),
                            iconColor: const Color(0xFF7652A8),
                            onTap: _openFindVet, // ✅ Find a Vet
                          ),

                          const SizedBox(height: 14),

                          // ================= APPOINTMENTS → MY APPOINTMENTS =================
                          _buildHomeCard(
                            title: 'Appointments',
                            subtitle: 'View and manage appointments',
                            icon: Icons.calendar_month_outlined,
                            backgroundColor: const Color(0xFFFCEFE5),
                            iconBackground: const Color(0xFFF7DFCD),
                            iconColor: const Color(0xFFB96832),
                            onTap: _openMyAppointments, // ✅ My Appointments
                          ),

                          const SizedBox(height: 14),

                          // ================= RECENT REMINDER =================
                          _buildHomeCard(
                            title: 'Recent Reminder',
                            subtitle:
                                'Check your latest animal health reminders',
                            icon: Icons.campaign_outlined,
                            backgroundColor: const Color(0xFFEAF0F6),
                            iconBackground: const Color(0xFFDCE6F0),
                            iconColor: const Color(0xFF466A89),
                            onTap: _openReminders,
                          ),
                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ================= BOTTOM NAVIGATION =================
            BottomNavigationBar(
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: primaryGreen,
              unselectedItemColor: const Color(0xFF7D8B83),
              selectedFontSize: 11,
              unselectedFontSize: 11,
              onTap: (index) {
                if (index == 0) {
                  setState(() => _selectedIndex = 0);
                } else if (index == 1) {
                  _openMyAnimals();
                } else if (index == 2) {
                  // ================= CONSULT TAB → FIND A VET =================
                  _openFindVet(); // ✅ Find a Vet
                } else if (index == 3) {
                  // ================= APPOINTMENTS TAB → MY APPOINTMENTS =================
                  _openMyAppointments(); // ✅ My Appointments
                } else if (index == 4) {
                  // ================= PROFILE TAB → FARMER PROFILE =================
                  _openFarmerProfile(); // ✅ Farmer Profile
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.pets_rounded),
                  label: 'Animals',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.medical_services_outlined),
                  label: 'Consult',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_outlined),
                  label: 'Appointments',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= BANNER =================
  Widget _buildBanner({
    required String image,
    required String title,
    required String subtitle,
    required bool isOriginalBanner,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFCDE7D7),
                    child: const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.white),
                    ),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                top: isOriginalBanner ? 45 : 48,
                right: 45,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isOriginalBanner
                            ? const Color.fromARGB(132, 255, 255, 255)
                            : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                        shadows: const [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black54,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HOME CARD =================
  Widget _buildHomeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color backgroundColor,
    required Color iconBackground,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF1E3027),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF697A71),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: iconColor, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - 35);
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height + 5,
      size.width * 0.45,
      size.height - 8,
    );
    path.quadraticBezierTo(
      size.width * 0.18,
      size.height - 22,
      0,
      size.height - 35,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
