import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color primaryGreen = Color(0xFF20B769);

  // Sample notifications
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Vaccination Due',
      'message': 'Bessie needs FMD vaccination by 15 Oct 2026',
      'time': '2 hours ago',
      'icon': Icons.vaccines_outlined,
      'color': const Color(0xFF20B769),
      'bgColor': const Color(0xFFE5F7EA),
      'read': false,
    },
    {
      'title': 'Appointment Confirmed',
      'message': 'Dr. Anjali Perera confirmed your appointment',
      'time': '5 hours ago',
      'icon': Icons.check_circle_outline,
      'color': const Color(0xFF3B82F6),
      'bgColor': const Color(0xFFE5F0FA),
      'read': false,
    },
    {
      'title': 'Treatment Reminder',
      'message': 'Bessie needs follow-up treatment',
      'time': '1 day ago',
      'icon': Icons.medication_outlined,
      'color': const Color(0xFFF59E0B),
      'bgColor': const Color(0xFFFFF4E5),
      'read': true,
    },
    {
      'title': 'Health Alert',
      'message': 'Cow in your area reported with fever',
      'time': '2 days ago',
      'icon': Icons.warning_amber_rounded,
      'color': const Color(0xFFEF4444),
      'bgColor': const Color(0xFFFFE5E5),
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
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
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in _notifications) {
                  n['read'] = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All marked as read'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationCard(_notifications[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Color(0xFF9CA3AF)),
          SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3027),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['read'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : notification['bgColor'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead
              ? const Color(0xFFE5F0E9)
              : notification['color'].withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: notification['bgColor'],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              notification['icon'],
              color: notification['color'],
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification['title'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isRead
                              ? FontWeight.w600
                              : FontWeight.bold,
                          color: const Color(0xFF1E3027),
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE85D68),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification['message'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF697A71),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  notification['time'],
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
    );
  }
}
