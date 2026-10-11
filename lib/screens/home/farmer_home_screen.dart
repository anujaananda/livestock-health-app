// lib/screens/home/farmer_home_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ================= KAUSHALYA ගේ IMPORTS =================
import '../farmer/my_animals_screen.dart';
import '../farmer/health_guide_screen.dart';

// ================= ඔයාගේ IMPORTS =================
import '../vet_booking/find_vet_screen.dart';
import '../vet_booking/my_appointments_screen.dart';
import '../vet_booking/farmer_profile_screen.dart';

// ================= NOTIFICATIONS & REMINDERS =================
import '../notifications/notifications_screen.dart';
import '../reminders/reminders_screen.dart';

// ================= EMERGENCY =================
import '../emergency/emergency_screen.dart';

// ================= SETTINGS, HELP, ABOUT =================
import '../settings/settings_screen.dart';
import '../help/help_support_screen.dart';
import '../about/about_screen.dart';

// ================= AUTH =================
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

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

  // ✅ Profile image
  String? _profileImageUrl;

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
    _loadProfilePhoto();
  }

  // ================= ✅ LOAD PROFILE PHOTO =================
  Future<void> _loadProfilePhoto() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser!.id;
      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('profiles')
          .select('profile_image_url')
          .eq('id', userId)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _profileImageUrl = data['profile_image_url'];
        });
      }
    } catch (e) {
      debugPrint('❌ Load photo error: $e');
    }
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

  void _openMyAnimals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyAnimalsScreen()),
    );
  }

  void _openHealthGuide(int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HealthGuideScreen(
            headerTitle: 'Nutrition for Healthy Animals',
            imagePath: 'assets/images/farmer_home_banner.png',
            title: 'Healthy Livestock',
            subtitle: 'Stronger Tomorrow',
            description: 'Good nutrition and proper animal care help livestock stay healthy and productive. Provide clean drinking water, appropriate feed and regular veterinary care.',
            tips: [
              'Provide clean drinking water every day.',
              'Maintain a balanced feeding routine.',
              'Monitor animal health regularly.',
            ],
          ),
        ),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HealthGuideScreen(
            headerTitle: 'Shelter & Hygiene',
            imagePath: 'assets/images/shelter_banner.png',
            title: 'Safe Shelter & Hygiene',
            subtitle: 'A clean environment keeps animals healthy',
            description: 'Proper shelter protects your animals from extreme weather, reduces stress and helps prevent the spread of diseases. Keep animal housing clean, dry and well-ventilated.',
            tips: [
              'Keep animal housing clean and dry.',
              'Ensure proper ventilation.',
              'Remove animal waste regularly.',
            ],
          ),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HealthGuideScreen(
            headerTitle: 'Vaccination & Prevention',
            imagePath: 'assets/images/vaccination_banner.png',
            title: 'Vaccination & Prevention',
            subtitle: 'Prevent diseases, ensure productivity',
            description: 'Vaccination helps protect livestock from preventable diseases. Consult a veterinarian about appropriate vaccination schedules and maintain accurate animal health records.',
            tips: [
              'Follow a veterinarian-approved schedule.',
              'Maintain vaccination records.',
              'Consult your vet for disease prevention.',
            ],
          ),
        ),
      );
    }
  }

  void _openFindVet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindVetScreen()),
    );
  }

  void _openMyAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyAppointmentsScreen()),
    );
  }

  void _openFarmerProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FarmerProfileScreen()),
    ).then((_) => _loadProfilePhoto());
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  void _openReminders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RemindersScreen()),
    );
  }

  void _openEmergency() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmergencyScreen()),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _openHelpSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
    );
  }

  void _openAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutScreen()),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF9),
      drawer: _buildDrawer(context, widget.userName),
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
                                Builder(
                                  builder: (context) => IconButton(
                                    onPressed: () =>
                                        Scaffold.of(context).openDrawer(),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.menu_rounded,
                                      color: Colors.white,
                                      size: 25,
                                    ),
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
                                GestureDetector(
                                  onTap: _openNotifications,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        const Icon(
                                          Icons.notifications_none_rounded,
                                          color: Colors.white,
                                          size: 27,
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
                                  ),
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

                          _buildHomeCard(
                            title: 'EMERGENCY',
                            subtitle: 'Contact a Vet Now',
                            icon: Icons.emergency_rounded,
                            backgroundColor: const Color(0xFFFFE8E8),
                            iconBackground: const Color(0xFFFFD7D7),
                            iconColor: const Color(0xFFD95360),
                            onTap: _openEmergency,
                          ),
                          const SizedBox(height: 14),

                          _buildHomeCard(
                            title: 'Consult a Vet',
                            subtitle: 'Get professional advice',
                            icon: Icons.medical_services_outlined,
                            backgroundColor: const Color(0xFFF0EBFA),
                            iconBackground: const Color(0xFFE4D9F5),
                            iconColor: const Color(0xFF7652A8),
                            onTap: _openFindVet,
                          ),
                          const SizedBox(height: 14),

                          _buildHomeCard(
                            title: 'Appointments',
                            subtitle: 'View and manage appointments',
                            icon: Icons.calendar_month_outlined,
                            backgroundColor: const Color(0xFFFCEFE5),
                            iconBackground: const Color(0xFFF7DFCD),
                            iconColor: const Color(0xFFB96832),
                            onTap: _openMyAppointments,
                          ),
                          const SizedBox(height: 14),

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
                  _openFindVet();
                } else if (index == 3) {
                  _openMyAppointments();
                } else if (index == 4) {
                  _openFarmerProfile();
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

  // ================= DRAWER (MENU) =================
  Widget _buildDrawer(BuildContext context, String userName) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
              child: Row(
                children: [
                  // ✅ FIXED — CircleAvatar (null-safe)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Builder(
                      builder: (context) {
                        final hasImage =
                            _profileImageUrl != null &&
                            _profileImageUrl!.isNotEmpty;

                        return CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          backgroundImage: hasImage
                              ? NetworkImage(_profileImageUrl!)
                              : null,
                          onBackgroundImageError: hasImage ? (_, __) {} : null,
                          child: hasImage
                              ? null
                              : const Icon(
                                  Icons.person,
                                  color: primaryGreen,
                                  size: 30,
                                ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Farmer',
                          style: TextStyle(
                            color: Color(0xFFE5F7EB),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 0);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.pets_rounded,
                    title: 'My Animals',
                    onTap: () {
                      Navigator.pop(context);
                      _openMyAnimals();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.medical_services_outlined,
                    title: 'Consult a Vet',
                    onTap: () {
                      Navigator.pop(context);
                      _openFindVet();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.calendar_month_outlined,
                    title: 'Appointments',
                    onTap: () {
                      Navigator.pop(context);
                      _openMyAppointments();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.campaign_outlined,
                    title: 'Reminders',
                    onTap: () {
                      Navigator.pop(context);
                      _openReminders();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      _openNotifications();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.emergency_rounded,
                    title: 'Emergency',
                    onTap: () {
                      Navigator.pop(context);
                      _openEmergency();
                    },
                  ),
                  const Divider(height: 30),
                  _buildDrawerItem(
                    icon: Icons.person_outline_rounded,
                    title: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      _openFarmerProfile();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      _openSettings();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      _openHelpSupport();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About',
                    onTap: () {
                      Navigator.pop(context);
                      _openAbout();
                    },
                  ),
                  const Divider(height: 30),
                  _buildDrawerItem(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    titleColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _logout(context);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DRAWER ITEM =================
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? primaryGreen).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? primaryGreen, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? const Color(0xFF1E3027),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
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
