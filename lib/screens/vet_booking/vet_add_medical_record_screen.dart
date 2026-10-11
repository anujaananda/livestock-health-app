// lib/screens/vet_booking/vet_add_medical_record_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/medical_record_model.dart';
import '../../services/auth_service.dart';
import '../../services/medical_record_service.dart';

class VetAddMedicalRecordScreen extends StatefulWidget {
  final String animalId;
  final String animalName;
  final String ownerId;

  const VetAddMedicalRecordScreen({
    super.key,
    required this.animalId,
    required this.animalName,
    required this.ownerId,
  });

  @override
  State<VetAddMedicalRecordScreen> createState() =>
      _VetAddMedicalRecordScreenState();
}

class _VetAddMedicalRecordScreenState extends State<VetAddMedicalRecordScreen> {
  static const Color primaryGreen = Color(0xFF20B769);
  static const Color emergencyRed = Color(0xFFEF4444);

  final _formKey = GlobalKey<FormState>();
  final _recordNameController = TextEditingController();
  final _fileUrlController = TextEditingController();
  final _notesController = TextEditingController();

  String _recordType = 'Diagnosis';
  DateTime _recordDate = DateTime.now();
  bool _isSaving = false;
  final MedicalRecordService _service = MedicalRecordService();

  final List<String> _recordTypes = [
    'Diagnosis',
    'Lab Report',
    'X-Ray',
    'Blood Test',
    'Prescription',
    'Surgery Report',
    'Other',
  ];

  @override
  void dispose() {
    _recordNameController.dispose();
    _fileUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _recordDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final vetEmail = authService.currentUser?.email ?? 'Vet';

    final vetNote = '\n\n--- Added by: $vetEmail ---';
    final finalNotes = (_notesController.text.trim() + vetNote).trim();

    final record = MedicalRecordModel(
      id: const Uuid().v4(),
      animalId: widget.animalId,
      ownerId: widget.ownerId,
      recordType: _recordType,
      recordName: _recordNameController.text.trim(),
      recordDate: _recordDate,
      fileUrl: _fileUrlController.text.trim().isEmpty
          ? null
          : _fileUrlController.text.trim(),
      notes: finalNotes.isEmpty ? null : finalNotes,
    );

    final success = await _service.saveMedicalRecord(record);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Medical record added!'),
          backgroundColor: primaryGreen,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to save'),
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
          'Add Medical Record',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= ANIMAL BANNER =================
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.pets,
                        color: primaryGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Adding record for',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF697A71),
                            ),
                          ),
                          Text(
                            widget.animalName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3027),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ================= RECORD TYPE =================
              const Text(
                'Record Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _recordType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: _recordTypes
                        .map(
                          (t) => DropdownMenuItem<String>(
                            value: t,
                            child: Text(t),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _recordType = v ?? 'Diagnosis'),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ================= RECORD NAME =================
              const Text(
                'Record Name / Title',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _recordNameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Blood test results',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: primaryGreen,
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Record name is required'
                    : null,
              ),

              const SizedBox(height: 16),

              // ================= RECORD DATE =================
              const Text(
                'Record Date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_recordDate.day}/${_recordDate.month}/${_recordDate.year}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3027),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF697A71),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ================= FILE URL =================
              const Text(
                'File URL (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fileUrlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: 'https://...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(
                    Icons.link,
                    color: Color(0xFF697A71),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: primaryGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ================= NOTES =================
              const Text(
                'Notes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Diagnosis details, observations...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: primaryGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ================= SAVE =================
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Record',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
