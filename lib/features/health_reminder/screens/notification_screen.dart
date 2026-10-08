import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
      _fetchNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error marking as read: $e')));
      }
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _sortNotifications(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final aRead = a['is_read'] == true;
      final bRead = b['is_read'] == true;
      if (aRead != bRead) {
        return aRead ? 1 : -1;
      }
      final aDate =
          DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime.now();
      final bDate =
          DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime.now();
      return bDate.compareTo(aDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayNotifications = _notifications.where((n) {
      final d =
          DateTime.tryParse(n['created_at']?.toString() ?? '') ??
          DateTime.now();
      return _isToday(d);
    }).toList();
    _sortNotifications(todayNotifications);

    final earlierNotifications = _notifications.where((n) {
      final d =
          DateTime.tryParse(n['created_at']?.toString() ?? '') ??
          DateTime.now();
      return !_isToday(d);
    }).toList();
    _sortNotifications(earlierNotifications);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF1E5936),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Notification',
              style: TextStyle(
                color: Color(0xFF1E5936),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            Text(
              'Health & reminder center',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none,
                  color: Color(0xFF1E7D42),
                ),
                onPressed: () {},
              ),
              if (_notifications.any((n) => n['is_read'] == false))
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCA0E24),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (todayNotifications.isNotEmpty) ...[
                    const Text(
                      'Today',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E5936),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...todayNotifications.map(
                      (n) => _buildNotificationCard(context, n),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (earlierNotifications.isNotEmpty) ...[
                    const Text(
                      'Earlier',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E5936),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...earlierNotifications.map(
                      (n) => _buildNotificationCard(context, n),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (todayNotifications.isEmpty &&
                      earlierNotifications.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'No notifications found.',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],

                  // Notification Helper Text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBDE2BF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Tap a notification to view details',
                        style: TextStyle(
                          color: Color(0xFF1E5936),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, Map<String, dynamic> n) {
    final isRead = n['is_read'] == true;
    final title = n['title']?.toString() ?? 'Notification';
    final message = n['message']?.toString() ?? '';
    final type = n['type']?.toString() ?? 'General';
    final createdAt =
        DateTime.tryParse(n['created_at']?.toString() ?? '') ?? DateTime.now();

    IconData getIconForType(String t) {
      final typeLower = t.toLowerCase();
      if (typeLower.contains('vaccin')) return Icons.vaccines;
      if (typeLower.contains('treat') || typeLower.contains('med'))
        return Icons.medical_services;
      if (typeLower.contains('health')) return Icons.health_and_safety;
      if (typeLower.contains('remind') || typeLower.contains('event'))
        return Icons.event;
      return Icons.notifications_none;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5EAE7)),
      ),
      child: InkWell(
        onTap: () {
          if (!isRead) {
            _markAsRead(n['id'].toString());
          }
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1E5936),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.category,
                        size: 16,
                        color: Color(0xFF1E7D42),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Type: $type',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isRead
                            ? Icons.mark_email_read
                            : Icons.mark_email_unread,
                        size: 16,
                        color: Color(0xFF1E7D42),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Status: ${isRead ? 'Read' : 'Unread'}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(0xFF1E7D42),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Date: ${DateFormat('yyyy-MM-dd h:mm a').format(createdAt)}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFE5EAE7)),
                  Text(message, style: const TextStyle(color: Colors.black87)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Color(0xFF1E7D42)),
                  ),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFF0FDF4),
                child: Icon(
                  getIconForType(type),
                  color: const Color(0xFF1E7D42),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                        color: isRead ? const Color(0xFF374151) : Colors.black,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('h:mm a').format(createdAt),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isRead)
                    Container(
                      margin: const EdgeInsets.only(top: 6, bottom: 18),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E7D42),
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 32),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
