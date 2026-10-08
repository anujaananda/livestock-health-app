import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF20B769);

  late TabController _tabController;
  final AppointmentService _appointmentService = AppointmentService();

  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final appointments = await _appointmentService.getFarmerAppointments(
      authService.currentUser!.id,
    );

    setState(() {
      _appointments = appointments;
      _isLoading = false;
    });
  }

  List<AppointmentModel> _getUpcoming() {
    return _appointments
        .where((a) => a.status == 'pending' || a.status == 'confirmed')
        .toList();
  }

  List<AppointmentModel> _getPast() {
    return _appointments
        .where((a) => a.status == 'completed' || a.status == 'cancelled')
        .toList();
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
          'My Appointments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildList(_getUpcoming()), _buildList(_getPast())],
            ),
    );
  }

  Widget _buildList(List<AppointmentModel> appointments) {
    if (appointments.isEmpty) {
      return const Center(
        child: Text(
          'No appointments',
          style: TextStyle(color: Color(0xFF697A71)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(appointments[index]);
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5F0E9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE5F7EA),
            backgroundImage: const NetworkImage(
              'https://i.pravatar.cc/150?img=12',
            ),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dr. Veterinary Doctor',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3027),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Veterinarian',
                  style: TextStyle(fontSize: 11, color: Color(0xFF697A71)),
                ),
                const SizedBox(height: 6),
                Text(
                  '${appointment.date.day} ${_getMonthName(appointment.date.month)} ${appointment.date.year} - ${appointment.time}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF697A71),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusBadge(appointment.status),
                    const SizedBox(width: 8),
                    _buildTypeBadge(appointment.type),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }

  // ================= STATUS BADGE =================
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'confirmed':
        bgColor = const Color(0xFFE5F7EA);
        textColor = const Color(0xFF20B769);
        label = 'Confirmed';
        break;
      case 'pending':
        bgColor = const Color(0xFFFFF4E5);
        textColor = const Color(0xFFF59E0B);
        label = 'Pending';
        break;
      case 'completed':
        bgColor = const Color(0xFFE5F0FA);
        textColor = const Color(0xFF3B82F6);
        label = 'Completed';
        break;
      case 'cancelled':
        bgColor = const Color(0xFFFFE5E5);
        textColor = const Color(0xFFEF4444);
        label = 'Cancelled';
        break;
      default:
        bgColor = const Color(0xFFE5F7EA);
        textColor = const Color(0xFF20B769);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // ================= TYPE BADGE (Online / On-site) =================
  Widget _buildTypeBadge(String type) {
    final isOnline = type.toLowerCase() == 'online';

    final bgColor = isOnline
        ? const Color(0xFFE5F0FA) // Blue for online
        : const Color(0xFFE5F7EA); // Green for onsite

    final textColor = isOnline
        ? const Color(0xFF3B82F6)
        : const Color(0xFF20B769);

    final label = isOnline ? 'Online' : 'On-site Visit';
    final icon = isOnline ? Icons.videocam_outlined : Icons.home_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
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
    return months[month - 1];
  }
}
