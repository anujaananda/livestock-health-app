// lib/screens/farmer/medical_records_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/medical_record_model.dart';
import '../../services/medical_record_service.dart';

class MedicalRecordsScreen extends StatefulWidget {
  final String animalId;

  const MedicalRecordsScreen({super.key, required this.animalId});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  static const Color primaryGreen = Color(0xFF20B769);

  final MedicalRecordService _service = MedicalRecordService();
  List<MedicalRecordModel> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await _service.getMedicalRecords(widget.animalId);
    if (!mounted) return;
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _openFile(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No file attached')));
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Cannot open: $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: primaryGreen,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Medical Records',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your vet can add medical records here',
                style: TextStyle(fontSize: 12, color: Color(0xFF697A71)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecords,
      color: primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _records.length,
        itemBuilder: (context, index) => _buildRecordCard(_records[index]),
      ),
    );
  }

  Widget _buildRecordCard(MedicalRecordModel record) {
    final typeColor = _typeColor(record.recordType);
    final typeIcon = _typeIcon(record.recordType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5F0E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, color: typeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.recordType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.recordName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3027),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: Color(0xFF697A71),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(record.recordDate),
                style: const TextStyle(fontSize: 11, color: Color(0xFF697A71)),
              ),
            ],
          ),

          if (record.notes != null && record.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                record.notes!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                  height: 1.4,
                ),
              ),
            ),
          ],

          if (record.fileUrl != null && record.fileUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openFile(record.fileUrl),
                icon: const Icon(Icons.attach_file, size: 16),
                label: const Text(
                  'View Attached File',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGreen,
                  side: BorderSide(color: primaryGreen.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'diagnosis':
        return const Color(0xFF3B82F6);
      case 'lab report':
        return const Color(0xFF8B5CF6);
      case 'x-ray':
        return const Color(0xFF06B6D4);
      case 'blood test':
        return const Color(0xFFEF4444);
      case 'prescription':
        return const Color(0xFFF59E0B);
      case 'surgery report':
        return const Color(0xFFEC4899);
      default:
        return primaryGreen;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'diagnosis':
        return Icons.medical_information_outlined;
      case 'lab report':
        return Icons.science_outlined;
      case 'x-ray':
        return Icons.image_outlined;
      case 'blood test':
        return Icons.bloodtype_outlined;
      case 'prescription':
        return Icons.medication_outlined;
      case 'surgery report':
        return Icons.medical_services_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
