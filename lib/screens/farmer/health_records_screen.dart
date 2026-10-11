// lib/screens/farmer/health_records_screen.dart
import 'package:flutter/material.dart';

import '../../models/health_record_model.dart';
import '../../services/health_record_service.dart';
import 'add_health_record_screen.dart';
import 'treatment_history_screen.dart';
import 'vaccination_history_screen.dart';
import 'medical_records_screen.dart';

class HealthRecordsScreen extends StatefulWidget {
  final String animalId;
  final String animalName;
  final String? animalImageUrl; // ✅ NEW

  const HealthRecordsScreen({
    super.key,
    required this.animalId,
    required this.animalName,
    this.animalImageUrl, // ✅ NEW
  });

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF20B769);
  static const Color emergencyRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);

  late TabController _tabController;
  final HealthRecordService _service = HealthRecordService();

  HealthRecordModel? _healthRecord;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHealthRecord();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthRecord() async {
    setState(() => _isLoading = true);
    final record = await _service.getHealthRecord(widget.animalId);
    if (!mounted) return;
    setState(() {
      _healthRecord = record;
      _isLoading = false;
    });
  }

  // ================= OPEN ADD =================
  Future<void> _openAddScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddHealthRecordScreen(animalId: widget.animalId),
      ),
    );
    if (result == true) _loadHealthRecord();
  }

  // ================= OPEN EDIT =================
  Future<void> _openEditScreen() async {
    if (_healthRecord == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddHealthRecordScreen(
          animalId: widget.animalId,
          existingRecord: _healthRecord,
        ),
      ),
    );
    if (result == true) _loadHealthRecord();
  }

  // ================= DELETE =================
  Future<void> _deleteRecord() async {
    if (_healthRecord == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: emergencyRed, size: 26),
            SizedBox(width: 10),
            Text(
              'Delete Record?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this health record? '
          'This action cannot be undone.',
          style: TextStyle(fontSize: 13, color: Color(0xFF697A71)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF697A71)),
            ),
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
              backgroundColor: emergencyRed,
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

    final success = await _service.deleteHealthRecord(_healthRecord!.id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Record deleted'),
          backgroundColor: emergencyRed,
        ),
      );
      _loadHealthRecord();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to delete'),
          backgroundColor: emergencyRed,
        ),
      );
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
          'Health Record',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Health Records'),
            Tab(text: 'Treatment History'),
            Tab(text: 'Vaccinations History'),
            Tab(text: 'Medical Records'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHealthRecordTab(),
                TreatmentHistoryScreen(animalId: widget.animalId),
                VaccinationHistoryScreen(animalId: widget.animalId),
                MedicalRecordsScreen(animalId: widget.animalId),
              ],
            ),
      floatingActionButton: _healthRecord == null
          ? FloatingActionButton.extended(
              onPressed: _openAddScreen,
              backgroundColor: primaryGreen,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Record',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  // ================= HEALTH RECORD TAB =================
  Widget _buildHealthRecordTab() {
    if (_healthRecord == null) {
      return _buildEmptyState();
    }

    final statusColor = _statusColor(_healthRecord!.overallStatus);
    final statusIcon = _statusIcon(_healthRecord!.overallStatus);

    return RefreshIndicator(
      onRefresh: _loadHealthRecord,
      color: primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= ANIMAL HEADER (with photo) =================
            _buildAnimalHeader(),
            const SizedBox(height: 20),

            // ================= OVERALL STATUS =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overall Health Status',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF697A71),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _healthRecord!.overallStatus,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= VITAL SIGNS =================
            const Text(
              'Vital Signs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3027),
              ),
            ),
            const SizedBox(height: 12),
            _buildVitalSign(
              icon: Icons.thermostat,
              label: 'Temperature',
              value: _healthRecord?.temperature != null
                  ? '${_healthRecord!.temperature} °C'
                  : 'N/A',
            ),
            const SizedBox(height: 10),
            _buildVitalSign(
              icon: Icons.favorite,
              label: 'Heart Rate',
              value: _healthRecord?.heartRate != null
                  ? '${_healthRecord!.heartRate} bpm'
                  : 'N/A',
            ),
            const SizedBox(height: 10),
            _buildVitalSign(
              icon: Icons.air,
              label: 'Respiration Rate',
              value: _healthRecord?.respirationRate != null
                  ? '${_healthRecord!.respirationRate} /min'
                  : 'N/A',
            ),

            const SizedBox(height: 24),

            // ================= NOTES =================
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3027),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5F0E9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.note_outlined,
                        color: primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _healthRecord?.notes ?? 'No notes available',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF697A71),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Last updated: ${_formatDate(_healthRecord?.recordDate)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= ACTION BUTTONS =================
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _deleteRecord,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: emergencyRed,
                      size: 18,
                    ),
                    label: const Text(
                      'Delete',
                      style: TextStyle(
                        color: emergencyRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: emergencyRed, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openEditScreen,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ================= EMPTY STATE (with photo) =================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ Animal profile pic
            _buildAnimalAvatar(radius: 50),
            const SizedBox(height: 20),
            const Text(
              'No Health Record',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3027),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a health record to track this animal\'s health status, vital signs, and notes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF697A71),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openAddScreen,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Health Record',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ✅ ANIMAL AVATAR (with image) =================
  Widget _buildAnimalAvatar({double radius = 35}) {
    final imageUrl = widget.animalImageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      width: radius * 2,
      height: radius * 2,
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
                width: radius * 2,
                height: radius * 2,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: radius * 0.6,
                      height: radius * 0.6,
                      child: const CircularProgressIndicator(
                        color: primaryGreen,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.pets, color: primaryGreen, size: radius * 0.9),
              )
            : Icon(Icons.pets, color: primaryGreen, size: radius * 0.9),
      ),
    );
  }

  // ================= ANIMAL HEADER (with photo) =================
  Widget _buildAnimalHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5F0E9)),
      ),
      child: Row(
        children: [
          // ✅ Actual animal photo
          _buildAnimalAvatar(radius: 35),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.animalName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3027),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Health Status',
                  style: TextStyle(fontSize: 12, color: Color(0xFF697A71)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= VITAL SIGN =================
  Widget _buildVitalSign({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5F0E9)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryGreen, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF697A71)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3027),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'need attention':
        return warningAmber;
      case 'under treatment':
        return emergencyRed;
      case 'healthy':
      default:
        return primaryGreen;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'need attention':
        return Icons.warning_amber_rounded;
      case 'under treatment':
        return Icons.medical_services_outlined;
      case 'healthy':
      default:
        return Icons.check_circle_outline;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
