import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'vet_emergency_alerts_screen.dart';

class VetNotificationsScreen extends StatefulWidget {
  const VetNotificationsScreen({super.key});

  @override
  State<VetNotificationsScreen> createState() => _VetNotificationsScreenState();
}

class _VetNotificationsScreenState extends State<VetNotificationsScreen> {
  static const Color primaryGreen = Color(0xFF20B769);

  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notifications = await _notificationService.getNotifications(
      authService.currentUser!.id,
    );

    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _markAllAsRead() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await _notificationService.markAllAsRead(authService.currentUser!.id);
    _loadNotifications();
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    await _notificationService.markAsRead(notification.id);

    if (!mounted) return;

    if (notification.type == 'emergency') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VetEmergencyAlertsScreen()),
      );
    }

    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF9),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: primaryGreen,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationCard(_notifications[index]);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFE5F7EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              color: primaryGreen,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3027),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'You are all caught up!',
            style: TextStyle(fontSize: 13, color: Color(0xFF697A71)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel item) {
    Color iconBg;
    Color iconColor;
    IconData icon;

    switch (item.type) {
      case 'emergency':
        iconBg = const Color(0xFFFFE5E5);
        iconColor = const Color(0xFFD32F2F);
        icon = Icons.warning_amber_rounded;
        break;
      case 'appointment':
        iconBg = const Color(0xFFE5F0FA);
        iconColor = const Color(0xFF3B82F6);
        icon = Icons.calendar_today;
        break;
      default:
        iconBg = const Color(0xFFE5F7EA);
        iconColor = primaryGreen;
        icon = Icons.notifications;
    }

    return GestureDetector(
      onTap: () => _onNotificationTap(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFF0FBF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.type == 'emergency' && !item.isRead
                ? const Color(0xFFFFC7C7)
                : const Color(0xFFE5F0E9),
            width: item.type == 'emergency' && !item.isRead ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: item.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            color: const Color(0xFF1E3027),
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF697A71),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(item.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour(s) ago';
    return '${diff.inDays} day(s) ago';
  }
}
