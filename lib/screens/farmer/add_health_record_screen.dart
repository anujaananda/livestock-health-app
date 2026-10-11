// lib/screens/farmer/add_health_record_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/health_record_model.dart';
import '../../services/auth_service.dart';
import '../../services/health_record_service.dart';

class AddHealthRecordScreen extends StatefulWidget {
  final String animalId;
  final HealthRecordModel? existingRecord; // null = add, non-null = edit

  const AddHealthRecordScreen({
    super.key,
    required this.animalId,
    this.existingRecord,
  });

  @override
  State<AddHealthRecordScreen> createState() => _AddHealthRecordScreenState();
}

class _AddHealthRecordScreenState extends State<AddHealthRecordScreen> {
  static const Color primaryGreen = Color(0xFF20B769);
  static const Color emergencyRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);

  final _formKey = GlobalKey<FormState>();
  final _temperatureController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _respirationController = TextEditingController();
  final _notesController = TextEditingController();

  String _overallStatus = 'Healthy';
  DateTime _recordDate = DateTime.now();
  bool _isSaving = false;
  final HealthRecordService _service = HealthRecordService();

  @override
  void initState() {
    super.initState();

    // ✅ Edit mode — fill existing data
    if (widget.existingRecord != null) {
      final r = widget.existingRecord!;
      _temperatureController.text = r.temperature?.toString() ?? '';
      _heartRateController.text = r.heartRate?.toString() ?? '';
      _respirationController.text = r.respirationRate?.toString() ?? '';
      _notesController.text = r.notes ?? '';
      _overallStatus = r.overallStatus;
      _recordDate = r.recordDate;
    }
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _heartRateController.dispose();
    _respirationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ================= PICK DATE =================
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E3027),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _recordDate = picked);
    }
  }

  // ================= SAVE =================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    final record = HealthRecordModel(
      id: widget.existingRecord?.id ?? const Uuid().v4(),
      animalId: widget.animalId,
      ownerId: widget.existingRecord?.ownerId ?? authService.currentUser!.id,
      overallStatus: _overallStatus,
      temperature: _temperatureController.text.trim().isEmpty
          ? null
          : double.tryParse(_temperatureController.text.trim()),
      heartRate: _heartRateController.text.trim().isEmpty
          ? null
          : int.tryParse(_heartRateController.text.trim()),
      respirationRate: _respirationController.text.trim().isEmpty
          ? null
          : int.tryParse(_respirationController.text.trim()),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      recordDate: _recordDate,
    );

    final success = widget.existingRecord == null
        ? await _service.saveHealthRecord(record)
        : await _service.updateHealthRecord(record);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingRecord == null
                ? '✅ Health record added!'
                : '✅ Health record updated!',
          ),
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
    final isEdit = widget.existingRecord != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF9),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Health Record' : 'Add Health Record',
          style: const TextStyle(
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

              const SizedBox(height: 20),

              // ================= OVERALL STATUS =================
              const Text(
                'Overall Health Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 8),
              _buildStatusOption(
                value: 'Healthy',
                color: primaryGreen,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 8),
              _buildStatusOption(
                value: 'Need Attention',
                color: warningAmber,
                icon: Icons.warning_amber_rounded,
              ),
              const SizedBox(height: 8),
              _buildStatusOption(
                value: 'Under Treatment',
                color: emergencyRed,
                icon: Icons.medical_services_outlined,
              ),

              const SizedBox(height: 20),

              // ================= VITAL SIGNS =================
              const Text(
                'Vital Signs',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 8),

              _buildNumberField(
                controller: _temperatureController,
                label: 'Temperature (°C)',
                hint: 'e.g. 38.5',
                icon: Icons.thermostat,
                isDecimal: true,
              ),
              const SizedBox(height: 12),

              _buildNumberField(
                controller: _heartRateController,
                label: 'Heart Rate (bpm)',
                hint: 'e.g. 60',
                icon: Icons.favorite_border,
                isDecimal: false,
              ),
              const SizedBox(height: 12),

              _buildNumberField(
                controller: _respirationController,
                label: 'Respiration Rate (/min)',
                hint: 'e.g. 20',
                icon: Icons.air,
                isDecimal: false,
              ),

              const SizedBox(height: 20),

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
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Additional notes, observations...',
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

              const SizedBox(height: 24),

              // ================= SAVE BUTTON =================
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
                      : Icon(
                          isEdit ? Icons.save : Icons.add,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : (isEdit ? 'Update Record' : 'Save Record'),
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

  Widget _buildStatusOption({
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _overallStatus == value;

    return GestureDetector(
      onTap: () => setState(() => _overallStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : const Color(0xFF1E3027),
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20)
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD1D5DB),
                    width: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDecimal,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        prefixIcon: Icon(icon, color: const Color(0xFF697A71), size: 20),
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
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF697A71)),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        if (isDecimal) {
          if (double.tryParse(v.trim()) == null) {
            return 'Enter a valid number';
          }
        } else {
          if (int.tryParse(v.trim()) == null) {
            return 'Enter a valid number';
          }
        }
        return null;
      },
    );
  }
}
