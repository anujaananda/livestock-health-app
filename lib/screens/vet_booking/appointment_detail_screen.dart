// lib/screens/vet_booking/appointment_detail_screen.dart
import 'package:flutter/material.dart';

import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  static const Color primaryGreen = Color(0xFF20B769);
  static const Color softRed = Color(0xFFEF4444);
  static const Color softAmber = Color(0xFFF59E0B);
  static const Color softBlue = Color(0xFF3B82F6);
  static const Color darkText = Color(0xFF1E3027);
  static const Color mutedText = Color(0xFF697A71);

  final AppointmentService _appointmentService = AppointmentService();
  bool _isLoading = false;

  // ✅ Editable state
  late DateTime _date;
  late String _time;

  List<String> get _photos => widget.appointment.photoUrls;

  @override
  void initState() {
    super.initState();
    _date = widget.appointment.date;
    _time = widget.appointment.time;
  }

  // ================= EDIT DATE + TIME =================
  Future<void> _editDateTime() async {
    final now = DateTime.now();
    final canEdit =
        widget.appointment.status == 'pending' ||
        widget.appointment.status == 'confirmed';

    if (!canEdit) {
      _showSnackBar('Cannot edit this appointment', color: softRed);
      return;
    }

    // ✅ Date picker
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              onSurface: darkText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    // ✅ Time picker
    final timeSlots = [
      '9:00 AM',
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '2:00 PM',
      '3:00 PM',
      '4:00 PM',
      '5:00 PM',
    ];

    final pickedTime = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: timeSlots.map((slot) {
                    final isSelected = slot == _time;
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, slot),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryGreen : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? primaryGreen
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          slot,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : darkText,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    // ✅ Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_calendar, color: primaryGreen, size: 24),
            SizedBox(width: 10),
            Text(
              'Update Appointment?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Change to:\n\n'
          '${pickedDate.day}/${pickedDate.month}/${pickedDate.year} at $pickedTime',
          style: const TextStyle(fontSize: 13, color: mutedText, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: mutedText)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check, size: 18, color: Colors.white),
            label: const Text('Update', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final success = await _appointmentService.updateAppointmentDateTime(
      appointmentId: widget.appointment.id,
      date: pickedDate,
      time: pickedTime,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      setState(() {
        _date = pickedDate;
        _time = pickedTime;
      });
      _showSnackBar('✅ Appointment updated!', color: primaryGreen);
    } else {
      _showSnackBar('Failed to update', color: softRed);
    }
  }

  // ================= CANCEL APPOINTMENT =================
  Future<void> _cancelAppointment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: softAmber, size: 26),
            SizedBox(width: 10),
            Text(
              'Cancel Appointment?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
          style: TextStyle(fontSize: 13, color: mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep', style: TextStyle(color: mutedText)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.block, size: 18, color: Colors.white),
            label: const Text('Cancel', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: softAmber,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final success = await _appointmentService.updateAppointmentStatus(
      appointmentId: widget.appointment.id,
      status: 'cancelled',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSnackBar('Appointment cancelled', color: softAmber);
      Navigator.pop(context, true);
    } else {
      _showSnackBar('Failed to cancel', color: softRed);
    }
  }

  // ================= DELETE APPOINTMENT =================
  Future<void> _deleteAppointment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: softRed, size: 26),
            SizedBox(width: 10),
            Text(
              'Delete Appointment?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'This action cannot be undone. Are you sure?',
          style: TextStyle(fontSize: 13, color: mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: mutedText)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: Colors.white,
            ),
            label: const Text('Delete', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: softRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final success = await _appointmentService.deleteAppointment(
      widget.appointment.id,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSnackBar('Appointment deleted', color: softRed);
      Navigator.pop(context, 'deleted');
    } else {
      _showSnackBar('Failed to delete', color: softRed);
    }
  }

  void _showSnackBar(String message, {required Color color}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openPhoto(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PhotoViewerScreen(imageUrl: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final canEdit =
        appointment.status == 'pending' || appointment.status == 'confirmed';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF9),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ================= SLIVER APP BAR =================
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: primaryGreen,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    // ✅ Edit icon — only for pending/confirmed
                    if (canEdit)
                      IconButton(
                        tooltip: 'Edit Date & Time',
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_calendar_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        onPressed: _editDateTime,
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF20B769),
                            Color(0xFF24B86A),
                            Color(0xFF2ECB7A),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Appointment',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Details',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _statusIcon(appointment.status),
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _statusLabel(appointment.status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ================= BODY =================
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVetCard(appointment),
                        const SizedBox(height: 20),

                        // ================= DATE & TIME (EDITABLE) =================
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompactCard(
                                icon: Icons.calendar_today_outlined,
                                title: 'Date',
                                value:
                                    '${_date.day} ${_getMonthName(_date.month)}',
                                subtitle: '${_date.year}',
                                onTap: canEdit ? _editDateTime : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildCompactCard(
                                icon: Icons.access_time_rounded,
                                title: 'Time',
                                value: _time,
                                subtitle: 'Duration: 30 min',
                                onTap: canEdit ? _editDateTime : null,
                              ),
                            ),
                          ],
                        ),

                        // ✅ Edit hint
                        if (canEdit) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app_outlined,
                                size: 12,
                                color: mutedText.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tap Date or Time to edit',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: mutedText.withValues(alpha: 0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 20),

                        // ================= DETAILS SECTION =================
                        const Text(
                          'Appointment Information',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildDetailRow(
                          icon: Icons.pets,
                          label: 'Animal',
                          value: appointment.animalName,
                        ),
                        const SizedBox(height: 10),

                        _buildDetailRow(
                          icon: appointment.isOnline
                              ? Icons.videocam_outlined
                              : Icons.home_outlined,
                          label: 'Consultation Type',
                          value: appointment.displayType,
                          valueColor: appointment.isOnline
                              ? softBlue
                              : primaryGreen,
                        ),
                        const SizedBox(height: 10),

                        _buildDetailRow(
                          icon: Icons.info_outline,
                          label: 'Status',
                          value: _statusLabel(appointment.status),
                          valueColor: _statusColor(appointment.status),
                        ),

                        // ================= NOTES =================
                        if (appointment.notes.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE5F0E9),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5F7EA),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.notes_rounded,
                                    color: primaryGreen,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    appointment.notes,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: darkText,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ================= PHOTOS =================
                        if (_photos.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Text(
                                'Attached Photos',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: darkText,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_photos.length}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 130,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _photos.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () => _openPhoto(_photos[index]),
                                  child: Container(
                                    width: 130,
                                    height: 130,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFE5F0E9),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            _photos[index],
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  color: const Color(
                                                    0xFFF9FAFB,
                                                  ),
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: Color(0xFF9CA3AF),
                                                    size: 32,
                                                  ),
                                                ),
                                          ),
                                          Positioned(
                                            bottom: 6,
                                            right: 6,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.5,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.zoom_in,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // ================= ACTION BUTTONS =================
                        if (canEdit) ...[
                          // ✅ Reschedule button (big, primary)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _editDateTime,
                              icon: const Icon(
                                Icons.edit_calendar,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Reschedule Appointment',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (canEdit)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _cancelAppointment,
                              icon: const Icon(Icons.block, size: 18),
                              label: const Text(
                                'Cancel Appointment',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: softAmber,
                                side: const BorderSide(
                                  color: softAmber,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _deleteAppointment,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text(
                              'Delete Appointment',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: softRed,
                              side: const BorderSide(
                                color: softRed,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ================= VET CARD =================
  Widget _buildVetCard(AppointmentModel appointment) {
    final imageUrl = appointment.vetImageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5F0E9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
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
                      width: 64,
                      height: 64,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: primaryGreen,
                        size: 32,
                      ),
                    )
                  : const Icon(Icons.person, color: primaryGreen, size: 32),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consultation with',
                  style: TextStyle(fontSize: 11, color: mutedText),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.displayVetName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appointment.displaySpecialization,
                  style: const TextStyle(fontSize: 12, color: mutedText),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, color: primaryGreen, size: 20),
          ),
        ],
      ),
    );
  }

  // ================= ✅ COMPACT CARD (EDITABLE) =================
  Widget _buildCompactCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: onTap != null
                ? primaryGreen.withValues(alpha: 0.3)
                : const Color(0xFFE5F0E9),
            width: onTap != null ? 1.5 : 1,
          ),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F7EA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: primaryGreen, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // ✅ Edit icon indicator
                if (onTap != null)
                  Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: primaryGreen.withValues(alpha: 0.7),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: mutedText),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DETAIL ROW =================
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5F0E9)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryGreen, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? darkText,
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================
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

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
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

// ================= PHOTO VIEWER =================
class _PhotoViewerScreen extends StatelessWidget {
  final String imageUrl;

  const _PhotoViewerScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white70, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
