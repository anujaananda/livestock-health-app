// lib/screens/vet_booking/my_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import 'appointment_detail_screen.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF20B769);
  static const Color softRed = Color(0xFFEF4444);
  static const Color softAmber = Color(0xFFF59E0B);
  static const Color softBlue = Color(0xFF3B82F6);
  static const Color darkText = Color(0xFF1E3027);
  static const Color mutedText = Color(0xFF697A71);

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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final appointments = await _appointmentService.getFarmerAppointments(
      authService.currentUser!.id,
    );

    if (!mounted) return;

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

  Future<void> _openDetails(AppointmentModel appointment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(appointment: appointment),
      ),
    );

    if (result == true || result == 'deleted') {
      setState(() => _isLoading = true);
      _loadAppointments();
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
              children: [
                _buildList(_getUpcoming(), isUpcoming: true),
                _buildList(_getPast(), isUpcoming: false),
              ],
            ),
    );
  }

  Widget _buildList(
    List<AppointmentModel> appointments, {
    required bool isUpcoming,
  }) {
    if (appointments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAppointments,
        color: primaryGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUpcoming
                          ? Icons.event_available_rounded
                          : Icons.event_busy_rounded,
                      size: 44,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isUpcoming
                        ? 'No upcoming appointments'
                        : 'No past appointments',
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pull down to refresh',
                    style: TextStyle(color: mutedText, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          return _buildAppointmentCard(appointments[index]);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final apptDate = DateTime(
      appointment.date.year,
      appointment.date.month,
      appointment.date.day,
    );
    final isToday = apptDate == today;
    final isTomorrow = apptDate == today.add(const Duration(days: 1));

    final statusColor = _statusColor(appointment.status);

    return GestureDetector(
      onTap: () => _openDetails(appointment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isToday
                ? primaryGreen.withValues(alpha: 0.5)
                : const Color(0xFFE5F0E9),
            width: isToday ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              if (isToday)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 4, color: primaryGreen),
                ),
              Padding(
                padding: EdgeInsets.only(
                  left: isToday ? 18 : 14,
                  top: 14,
                  right: 14,
                  bottom: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVetAvatar(appointment),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      appointment.displayVetName, // ✅ FIXED
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: darkText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isToday)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryGreen,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'TODAY',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    )
                                  else if (isTomorrow)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: softBlue,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'TOMORROW',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                appointment.displaySpecialization, // ✅ FIXED
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: mutedText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // INFO CHIPS
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.pets,
                          label: appointment.animalName,
                          color: primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        _buildInfoChip(
                          icon: appointment.isOnline
                              ? Icons.videocam_rounded
                              : Icons.home_rounded,
                          label: appointment.displayType,
                          color: appointment.isOnline ? softBlue : primaryGreen,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // DATE + TIME
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: mutedText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${appointment.date.day} ${_getMonthName(appointment.date.month)} ${appointment.date.year}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: mutedText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: mutedText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appointment.time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: mutedText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // NOTES
                    if (appointment.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.notes_rounded,
                              size: 13,
                              color: mutedText,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                appointment.notes,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: mutedText,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // PHOTO COUNT
                    if (appointment.photoUrls.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_library_outlined,
                              size: 11,
                              color: primaryGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${appointment.photoUrls.length} photo${appointment.photoUrls.length > 1 ? "s" : ""}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // FOOTER
                    Row(
                      children: [
                        _buildStatusBadge(appointment.status),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: statusColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVetAvatar(AppointmentModel appointment) {
    final imageUrl = appointment.vetImageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE5F7EA),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: 56,
                height: 56,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: primaryGreen,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, color: primaryGreen, size: 28),
              )
            : const Icon(Icons.person, color: primaryGreen, size: 28),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return primaryGreen;
      case 'pending':
        return softAmber;
      case 'completed':
        return softBlue;
      case 'cancelled':
        return softRed;
      default:
        return primaryGreen;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
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
