// lib/screens/vet_booking/vet_dashboard_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/appointment_model.dart';
import '../../models/emergency_alert_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../services/consultation_service.dart';
import '../../services/emergency_service.dart';
import '../../services/notification_service.dart';
import '../about/about_screen.dart';
import '../auth/login_screen.dart';
import '../help/help_support_screen.dart';
import '../settings/settings_screen.dart';
import 'vet_appointments_screen.dart';
import 'vet_emergency_alerts_screen.dart';
import 'vet_notifications_screen.dart';
import 'vet_profile_screen.dart';
import 'vet_select_animal_screen.dart';

class VetDashboardScreen extends StatefulWidget {
  final String userName;
  final VoidCallback? onAppointmentsTap;
  final VoidCallback? onAlertsTap;
  final ValueChanged<int>? onAlertsCountChanged;

  const VetDashboardScreen({
    super.key,
    required this.userName,
    this.onAppointmentsTap,
    this.onAlertsTap,
    this.onAlertsCountChanged,
  });

  @override
  State<VetDashboardScreen> createState() => _VetDashboardScreenState();
}

class _VetDashboardScreenState extends State<VetDashboardScreen> {
  static const Color primaryGreen = Color(0xFF20B769);

  final AppointmentService _appointmentService = AppointmentService();
  final ConsultationService _consultationService = ConsultationService();
  final EmergencyService _emergencyService = EmergencyService();
  final NotificationService _notificationService = NotificationService();

  // ================= BANNER VARIABLES =================
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBanner = 0;

  final List<Map<String, String>> _banners = [
    {
      'image': 'assets/images/vet_welcome_banner.png',
      'title': 'Welcome, Dr.',
      'subtitle': 'Manage your vet practice efficiently',
    },
    {
      'image': 'assets/images/vet_emergency_banner.png',
      'title': 'Emergency Alerts',
      'subtitle': 'Respond to urgent cases',
    },
    {
      'image': 'assets/images/vet_appointments_banner.png',
      'title': 'Manage Appointments',
      'subtitle': 'View and confirm bookings',
    },
  ];

  int _pendingCount = 0;
  int _confirmedCount = 0;
  List<EmergencyAlertModel> _emergencyAlerts = [];
  int _unreadNotifications = 0;
  bool _isLoading = true;

  // ✅ Profile image
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _subscribeToEmergencyAlerts();
    _subscribeToNotifications();
    _startBannerTimer();
    _loadProfilePhoto(); // ✅ ADD THIS
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  // ================= ✅ LOAD PROFILE PHOTO =================
  Future<void> _loadProfilePhoto() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser!.id;
      final supabase = Supabase.instance.client;

      // ✅ Try vet_profiles first (matches view profile)
      final vetData = await supabase
          .from('vet_profiles')
          .select('profile_image_url')
          .eq('user_id', userId)
          .maybeSingle();

      if (vetData != null &&
          vetData['profile_image_url'] != null &&
          vetData['profile_image_url'].toString().isNotEmpty) {
        if (mounted) {
          setState(() {
            _profileImageUrl = vetData['profile_image_url'];
          });
        }
        return;
      }

      // ✅ Fallback — profiles table
      final profileData = await supabase
          .from('profiles')
          .select('profile_image_url')
          .eq('id', userId)
          .maybeSingle();

      if (profileData != null &&
          profileData['profile_image_url'] != null &&
          profileData['profile_image_url'].toString().isNotEmpty) {
        if (mounted) {
          setState(() {
            _profileImageUrl = profileData['profile_image_url'];
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Load photo error: $e');
    }
  }

  // ================= BANNER TIMER =================
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

  // ================= LOAD DASHBOARD DATA =================
  Future<void> _loadDashboardData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final vetId = authService.currentUser!.id;

    try {
      final appointments = await _appointmentService.getVetAppointments(vetId);
      final consultations = await _consultationService.getVetConsultations(
        vetId,
      );
      final alerts = await _emergencyService.getActiveAlerts(vetId);
      final unread = await _notificationService.getUnreadCount(vetId);

      if (!mounted) return;

      final List<AppointmentModel> allItems = [
        ...appointments,
        ...consultations,
      ];

      final pending = allItems.where((a) => a.status == 'pending').length;
      final confirmed = allItems.where((a) => a.status == 'confirmed').length;

      setState(() {
        _pendingCount = pending;
        _confirmedCount = confirmed;
        _emergencyAlerts = alerts;
        _unreadNotifications = unread;
        _isLoading = false;
      });

      widget.onAlertsCountChanged?.call(alerts.length);
    } catch (e) {
      debugPrint('❌ Error loading dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToEmergencyAlerts() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final vetId = authService.currentUser!.id;

    _emergencyService.streamActiveAlerts(vetId).listen((alerts) {
      if (!mounted) return;
      setState(() {
        _emergencyAlerts = alerts;
      });
      widget.onAlertsCountChanged?.call(alerts.length);
    });
  }

  void _subscribeToNotifications() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final vetId = authService.currentUser!.id;

    _notificationService.streamNotifications(vetId).listen((notifications) {
      if (!mounted) return;
      final unread = notifications.where((n) => !n.isRead).length;
      setState(() {
        _unreadNotifications = unread;
      });
    });
  }

  // ================= LOGOUT =================
  Future<void> _logout() async {
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

    if (confirm != true) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // ================= OPEN NOTIFICATIONS =================
  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VetNotificationsScreen()),
    );
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF9),
      drawer: _buildDrawer(authService),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: primaryGreen,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),

                      // ✅ BANNER CAROUSEL
                      _buildBannerCarousel(),

                      const SizedBox(height: 12),

                      // ✅ BANNER DOTS
                      _buildBannerDots(),

                      const SizedBox(height: 20),

                      if (_emergencyAlerts.isNotEmpty) _buildEmergencyBanner(),
                      _buildStats(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ================= BANNER CAROUSEL =================
  Widget _buildBannerCarousel() {
    return SizedBox(
      height: 180,
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
            title: index == 0
                ? 'Welcome, Dr. ${widget.userName}'
                : banner['title']!,
            subtitle: banner['subtitle']!,
          );
        },
      ),
    );
  }

  // ================= BANNER DOTS =================
  Widget _buildBannerDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_banners.length, (index) {
        final selected = _currentBanner == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: selected ? 18 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: selected ? primaryGreen : const Color(0xFFCDE7D7),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  // ================= BANNER DESIGN =================
  Widget _buildBanner({
    required String image,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              image,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF42B97A),
                        Color(0xFF20B769),
                        Color(0xFF176B43),
                      ],
                    ),
                  ),
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
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 45,
              right: 45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                      shadows: [
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
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF42B97A), Color(0xFF6DCE96), Color(0xFF91DDB0)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Vet Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Stack(
                children: [
                  IconButton(
                    onPressed: _openNotifications,
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                    ),
                  ),
                  if (_unreadNotifications > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_unreadNotifications',
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
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hello, Dr. ${widget.userName}!',
            style: const TextStyle(
              color: Color(0xFFF4FFF7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage your appointments and consultations',
            style: TextStyle(color: Color(0xFFE5F7EB), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ================= STATS =================
  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.pending_actions,
              value: '$_pendingCount',
              label: 'Pending',
              color: const Color(0xFFFFF4E5),
              iconColor: const Color(0xFFF59E0B),
              onTap: () => widget.onAppointmentsTap?.call(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_outline,
              value: '$_confirmedCount',
              label: 'Confirmed',
              color: const Color(0xFFE5F7EA),
              iconColor: primaryGreen,
              onTap: () => widget.onAppointmentsTap?.call(),
            ),
          ),
        ],
      ),
    );
  }

  // ================= QUICK ACTIONS =================
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3027),
            ),
          ),
          const SizedBox(height: 12),

          // 1️⃣ My Appointments
          _buildMenuCard(
            icon: Icons.calendar_month,
            title: 'My Appointments',
            subtitle: _pendingCount + _confirmedCount > 0
                ? '${_pendingCount + _confirmedCount} appointment(s)'
                : 'View and manage appointments',
            onTap: () {
              if (widget.onAppointmentsTap != null) {
                widget.onAppointmentsTap!();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VetAppointmentsScreen(),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),

          // 2️⃣ Emergency Alerts
          _buildMenuCard(
            icon: Icons.warning_amber_outlined,
            title: 'Emergency Alerts',
            subtitle: _emergencyAlerts.isEmpty
                ? 'No active alerts'
                : '${_emergencyAlerts.length} active alert(s)',
            onTap: () {
              if (widget.onAlertsTap != null) {
                widget.onAlertsTap!();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VetEmergencyAlertsScreen(),
                  ),
                );
              }
            },
            badgeCount: _emergencyAlerts.length,
          ),
          const SizedBox(height: 12),

          // 3️⃣ Medical Records
          _buildMenuCard(
            icon: Icons.description_outlined,
            title: 'Medical Records',
            subtitle: 'Add medical records for farmers',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VetSelectAnimalScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // 4️⃣ Notifications
          _buildMenuCard(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: _unreadNotifications > 0
                ? '$_unreadNotifications unread'
                : 'View all notifications',
            onTap: _openNotifications,
            badgeCount: _unreadNotifications,
          ),
        ],
      ),
    );
  }

  // ================= DRAWER =================
  Widget _buildDrawer(AuthService authService) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ FIXED — CircleAvatar with dynamic photo
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
                  const SizedBox(height: 12),
                  Text(
                    'Dr. ${widget.userName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authService.currentUser?.email ?? 'vet@email.com',
                    style: const TextStyle(
                      color: Color(0xFFE5F7EB),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.calendar_month,
                    title: 'My Appointments',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VetAppointmentsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.warning_amber_outlined,
                    title: 'Emergency Alerts',
                    badge: _emergencyAlerts.length,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VetEmergencyAlertsScreen(),
                        ),
                      );
                    },
                  ),

                  // ✅ Medical Records
                  _buildDrawerItem(
                    icon: Icons.description_outlined,
                    title: 'Medical Records',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VetSelectAnimalScreen(),
                        ),
                      );
                    },
                  ),

                  _buildDrawerItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    badge: _unreadNotifications,
                    onTap: () {
                      Navigator.pop(context);
                      _openNotifications();
                    },
                  ),
                  const Divider(height: 30),
                  _buildDrawerItem(
                    icon: Icons.person_outline_rounded,
                    title: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VetProfileScreen(),
                        ),
                      ).then((_) => _loadProfilePhoto()); // ✅ Reload photo
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
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
                      _logout();
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
    int badge = 0,
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
      trailing: badge > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  // ================= EMERGENCY BANNER =================
  Widget _buildEmergencyBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFC7C7), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFCDD2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFD32F2F),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_emergencyAlerts.length} Emergency Alert(s)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB71C1C),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Urgent attention required',
                  style: TextStyle(fontSize: 11, color: Color(0xFFD32F2F)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              if (widget.onAlertsTap != null) {
                widget.onAlertsTap!();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VetEmergencyAlertsScreen(),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text(
              'View',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ================= STAT CARD =================
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3027),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF697A71),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= MENU CARD =================
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5F0E9)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F7EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryGreen, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3027),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF697A71),
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}
