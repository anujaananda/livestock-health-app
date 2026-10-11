// lib/screens/vet_booking/vet_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';

class VetAppointmentsScreen extends StatefulWidget {
  final bool showBackButton;

  const VetAppointmentsScreen({super.key, this.showBackButton = true});

  @override
  State<VetAppointmentsScreen> createState() => _VetAppointmentsScreenState();
}

class _VetAppointmentsScreenState extends State<VetAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  // ================= BOOK APPOINTMENT THEME COLORS =================
  static const Color primaryGreen = Color(0xFF24B86A);
  static const Color borderGrey = Color(0xFFE5E7EB);
  static const Color darkText = Color(0xFF1E3027);
  static const Color mutedText = Color(0xFF697A71);
  static const Color softRed = Color(0xFFE15B5B);
  static const Color softAmber = Color(0xFFD88719);
  static const Color softBlue = Color(0xFF3B82F6);

  late TabController _tabController;
  final AppointmentService _appointmentService = AppointmentService();
  final TextEditingController _searchController = TextEditingController();

  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ================= LOAD =================
  Future<void> _loadAppointments() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final appointments = await _appointmentService.getVetAppointments(
      authService.currentUser!.id,
    );

    if (!mounted) return;

    setState(() {
      _appointments = appointments;
      _isLoading = false;
    });
  }

  // ================= FILTER =================
  List<AppointmentModel> _applySearch(List<AppointmentModel> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((a) {
      return a.animalName.toLowerCase().contains(_searchQuery) ||
          a.notes.toLowerCase().contains(_searchQuery) ||
          a.status.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  // ================= SORT =================
  List<AppointmentModel> _applySort(List<AppointmentModel> list) {
    final sorted = List<AppointmentModel>.from(list);
    switch (_sortBy) {
      case 'date_asc':
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'name':
        sorted.sort((a, b) => a.animalName.compareTo(b.animalName));
        break;
      case 'date_desc':
      default:
        sorted.sort((a, b) => b.date.compareTo(a.date));
    }
    return sorted;
  }

  List<AppointmentModel> _getPending() {
    final list = _appointments.where((a) => a.status == 'pending').toList();
    return _applySort(_applySearch(list));
  }

  List<AppointmentModel> _getConfirmed() {
    final list = _appointments
        .where((a) => a.status == 'confirmed' || a.status == 'completed')
        .toList();
    return _applySort(_applySearch(list));
  }

  List<AppointmentModel> _getCancelled() {
    final list = _appointments.where((a) => a.status == 'cancelled').toList();
    return _applySort(_applySearch(list));
  }

  // ================= STATS =================
  int get _totalCount => _appointments.length;

  int get _todayCount {
    final now = DateTime.now();
    return _appointments
        .where(
          (a) =>
              a.date.year == now.year &&
              a.date.month == now.month &&
              a.date.day == now.day,
        )
        .length;
  }

  int get _pendingCount =>
      _appointments.where((a) => a.status == 'pending').length;

  // ================= UPDATE STATUS =================
  Future<void> _updateStatus(String appointmentId, String status) async {
    final success = await _appointmentService.updateAppointmentStatus(
      appointmentId: appointmentId,
      status: status,
    );

    if (success && mounted) {
      _showSnackBar(
        status == 'confirmed'
            ? '✅ Appointment confirmed!'
            : '❌ Appointment cancelled!',
        color: status == 'confirmed' ? primaryGreen : softRed,
      );
      _loadAppointments();
    }
  }

  // ================= DELETE =================
  Future<void> _deleteAppointment(AppointmentModel appointment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: softRed, size: 26),
            SizedBox(width: 10),
            Text(
              'Delete Appointment?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Delete appointment for "${appointment.animalName}"? '
          'This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: mutedText),
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

    final success = await _appointmentService.deleteAppointment(appointment.id);

    if (success && mounted) {
      _showSnackBar('🗑️ Appointment deleted!', color: softRed);
      _loadAppointments();
    } else if (mounted) {
      _showSnackBar('❌ Failed to delete', color: softRed);
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'My Appointments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              _buildSortItem('date_desc', 'Newest First', Icons.arrow_downward),
              _buildSortItem('date_asc', 'Oldest First', Icons.arrow_upward),
              _buildSortItem('name', 'Animal Name', Icons.sort_by_alpha),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: 'Pending (${_getPending().length})'),
            Tab(text: 'Confirmed (${_getConfirmed().length})'),
            Tab(text: 'Cancelled (${_getCancelled().length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsAndSearch(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_getPending(), showActions: true),
                      _buildList(_getConfirmed(), showActions: false),
                      _buildList(_getCancelled(), showActions: false),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ================= STATS + SEARCH =================
  Widget _buildStatsAndSearch() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  icon: Icons.event_note_rounded,
                  label: 'Total',
                  value: '$_totalCount',
                  color: softBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  icon: Icons.today_rounded,
                  label: 'Today',
                  value: '$_todayCount',
                  color: primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  icon: Icons.pending_actions_rounded,
                  label: 'Pending',
                  value: '$_pendingCount',
                  color: softAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search animal, status...',
              hintStyle: const TextStyle(fontSize: 13, color: mutedText),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: mutedText,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18, color: mutedText),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(
    String value,
    String label,
    IconData icon,
  ) {
    final selected = _sortBy == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: selected ? primaryGreen : mutedText),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? primaryGreen : darkText,
            ),
          ),
          if (selected) ...[
            const Spacer(),
            const Icon(Icons.check, size: 16, color: primaryGreen),
          ],
        ],
      ),
    );
  }

  // ================= LIST =================
  Widget _buildList(
    List<AppointmentModel> appointments, {
    bool showActions = false,
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
                      color: primaryGreen.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _searchQuery.isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.event_busy_rounded,
                      size: 44,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No results found'
                        : 'No appointments yet',
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Try a different search term'
                        : 'Pull down to refresh',
                    style: const TextStyle(color: mutedText, fontSize: 12),
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
          return _buildAppointmentCard(
            appointments[index],
            showActions: showActions,
          );
        },
      ),
    );
  }

  // ================= APPOINTMENT CARD =================
  Widget _buildAppointmentCard(
    AppointmentModel appointment, {
    bool showActions = false,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final apptDate = DateTime(
      appointment.date.year,
      appointment.date.month,
      appointment.date.day,
    );
    final isToday = apptDate == today;
    final isTomorrow = apptDate == today.add(const Duration(days: 1));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? primaryGreen.withValues(alpha: 0.5) : borderGrey,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pets, color: primaryGreen, size: 24),
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
                            appointment.animalName,
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
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
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
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
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ================= BADGES =================
          Row(
            children: [
              _buildStatusBadge(appointment.status),
              const SizedBox(width: 6),
              _buildTypeBadge(appointment.type),
            ],
          ),

          // ================= NOTES =================
          if (appointment.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded, size: 14, color: mutedText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      appointment.notes,
                      style: const TextStyle(
                        fontSize: 11.5,
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

          // ================= ACTION BUTTONS (for Pending) =================
          if (showActions) ...[
            const SizedBox(height: 12),
            _buildActionButtons(appointment),
          ],

          // ================= DELETE FOR CONFIRMED/CANCELLED (RED FILLED) =================
          if (!showActions) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () => _deleteAppointment(appointment),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Delete Appointment',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: softRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================= ACTION BUTTONS (Book Appointment Style) =================
  Widget _buildActionButtons(AppointmentModel appointment) {
    return Row(
      children: [
        Expanded(
          child: _buildIconButton(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: softRed,
            onTap: () => _deleteAppointment(appointment),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildIconButton(
            icon: Icons.block_rounded,
            label: 'Cancel',
            color: softAmber,
            onTap: () => _updateStatus(appointment.id, 'cancelled'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildIconButton(
            icon: Icons.check_rounded,
            label: 'Confirm',
            color: primaryGreen,
            onTap: () => _updateStatus(appointment.id, 'confirmed'),
          ),
        ),
      ],
    );
  }

  // ================= ✅ SOLID COLOR BUTTON =================
  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // ================= STATUS BADGE =================
  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'confirmed':
        color = primaryGreen;
        label = 'Confirmed';
        break;
      case 'pending':
        color = softAmber;
        label = 'Pending';
        break;
      case 'completed':
        color = softBlue;
        label = 'Completed';
        break;
      case 'cancelled':
        color = softRed;
        label = 'Cancelled';
        break;
      default:
        color = primaryGreen;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ================= TYPE BADGE =================
  Widget _buildTypeBadge(String type) {
    final isOnline = type.toLowerCase() == 'online';
    final color = isOnline ? softBlue : primaryGreen;
    final label = isOnline ? 'Online' : 'On-site';
    final icon = isOnline ? Icons.videocam_rounded : Icons.home_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ================= MONTH NAME =================
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
