import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import 'add_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  static const Color primaryGreen = Color(0xFF20B769);

  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final data = await Supabase.instance.client
          .from('reminders')
          .select()
          .eq('owner_id', authService.currentUser!.id)
          .order('reminder_date', ascending: true);

      setState(() {
        _reminders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  // ================= OPEN ADD REMINDER =================
  Future<void> _openAddReminder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddReminderScreen()),
    );

    if (result == true) {
      _loadReminders();
    }
  }

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
          'Reminders',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                return _buildReminderCard(_reminders[index]);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddReminder,
        backgroundColor: primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Reminder',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // ================= EMPTY STATE =================
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
              size: 40,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No reminders',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3027),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a reminder to get started.',
            style: TextStyle(fontSize: 13, color: Color(0xFF697A71)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openAddReminder,
            icon: const Icon(Icons.add),
            label: const Text('Add Reminder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ================= REMINDER CARD =================
  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    final type = (reminder['type'] ?? 'Vaccination').toString();
    final isOverdue = _isOverdue(reminder['reminder_date']);

    Color color;
    Color bgColor;
    IconData icon;

    switch (type.toLowerCase()) {
      case 'vaccination':
        color = const Color(0xFF20B769);
        bgColor = const Color(0xFFE5F7EA);
        icon = Icons.vaccines_outlined;
        break;
      case 'treatment':
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFFF4E5);
        icon = Icons.medication_outlined;
        break;
      case 'checkup':
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFE5F0FA);
        icon = Icons.medical_services_outlined;
        break;
      default:
        color = const Color(0xFF7652A8);
        bgColor = const Color(0xFFF0EBFA);
        icon = Icons.notifications_none;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
              : const Color(0xFFE5F0E9),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
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
                        reminder['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3027),
                        ),
                      ),
                    ),
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5E5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Overdue',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reminder['animal_name'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF697A71),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(reminder['reminder_date']),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(reminder['reminder_time']),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isOverdue(String? date) {
    if (date == null) return false;
    try {
      final reminderDate = DateTime.parse(date);
      return reminderDate.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try {
      final parsed = DateTime.parse(date);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return date;
    }
  }

  String _formatTime(String? time) {
    if (time == null) return '';
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (_) {
      return time;
    }
  }
}
