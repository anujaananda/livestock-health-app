import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../screens/home/farmer_home_screen.dart';
import '../../../screens/vet_booking/find_vet_screen.dart';
import '../../../screens/vet_booking/my_appointments_screen.dart';
import '../../../screens/vet_booking/farmer_profile_screen.dart';
import '../../../screens/farmer/my_animals_screen.dart';

class AddHealthRecordScreen extends StatefulWidget {
  final Map<String, dynamic> animal;
  final Map<String, dynamic>? existingRecord;

  const AddHealthRecordScreen({
    super.key,
    required this.animal,
    this.existingRecord,
  });

  @override
  State<AddHealthRecordScreen> createState() => _AddHealthRecordScreenState();
}

class _AddHealthRecordScreenState extends State<AddHealthRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _conditionController = TextEditingController();
  final _medicineController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _notesController = TextEditingController();

  String _animalId = '';
  String _displayId = '';
  String _status = 'Follow Up';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _animalId = widget.animal['id'].toString();
    _displayId = widget.animal['animal_id_tag']?.toString() ?? _animalId;

    if (widget.existingRecord != null) {
      final r = widget.existingRecord!;
      if (r['record_date'] != null) {
        _selectedDate =
            DateTime.tryParse(r['record_date'].toString()) ?? DateTime.now();
      }
      _status = r['overall_status']?.toString() ?? 'Follow Up';
      final rawNotes = r['notes']?.toString() ?? '';
      _conditionController.text = _extractField(rawNotes, 'Condition:');
      _medicineController.text = _extractField(rawNotes, 'Medicine:');
      _treatmentController.text = _extractField(rawNotes, 'Treatment:');
      _notesController.text = _extractField(rawNotes, 'Notes:');
    }
    _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate);
  }

  String _extractField(String raw, String fieldName) {
    final lines = raw.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith(fieldName)) {
        String value = lines[i].substring(fieldName.length).trim();
        if (fieldName == 'Notes:') {
          List<String> rest = [value];
          if (i + 1 < lines.length) {
            rest.addAll(lines.sublist(i + 1));
          }
          return rest.join('\n').trim();
        }
        return value;
      }
    }
    return '';
  }

  @override
  void dispose() {
    _dateController.dispose();
    _conditionController.dispose();
    _medicineController.dispose();
    _treatmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(today) ? today : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate);
      });
    }
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selected = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      if (selected.isAfter(today)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health record date cannot be in the future.'),
          ),
        );
        return;
      }

      setState(() => _isSaving = true);

      final userId = Supabase.instance.client.auth.currentUser!.id;
      final combinedNotes =
          'Condition: ${_conditionController.text.trim()}\n'
          'Medicine: ${_medicineController.text.trim()}\n'
          'Treatment: ${_treatmentController.text.trim()}\n'
          'Notes: ${_notesController.text.trim()}';

      final Map<String, dynamic> data = {
        'animal_id': _animalId,
        'owner_id': userId,
        'record_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'overall_status': _status,
        'notes': combinedNotes,
      };

      try {
        if (widget.existingRecord == null) {
          await Supabase.instance.client.from('health_records').insert(data);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Health record added successfully')),
            );
          }
        } else {
          await Supabase.instance.client
              .from('health_records')
              .update(data)
              .eq('id', widget.existingRecord!['id']);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Health record updated successfully'),
              ),
            );
          }
        }
        if (mounted) {
          Navigator.pop(context, true); // true indicates success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  void _openFarmerHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const FarmerHomeScreen()),
      (route) => false,
    );
  }

  void _openFindVet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindVetScreen()),
    );
  }

  void _openMyAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyAppointmentsScreen()),
    );
  }

  void _openFarmerProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FarmerProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FCF9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E7D42)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingRecord == null
              ? 'Add Health Record'
              : 'Edit Health Record',
          style: const TextStyle(
            color: Color(0xFF1E5936),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Animal ID *'),
              const SizedBox(height: 6),
              TextFormField(
                initialValue: _displayId,
                readOnly: true,
                style: const TextStyle(fontSize: 14),
                decoration: _buildInputDecoration(
                  hintText: '',
                  icon: Icons.local_offer_outlined,
                ),
              ),
              const SizedBox(height: 12),

              _buildLabel('Date *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                style: const TextStyle(fontSize: 14),
                decoration: _buildInputDecoration(
                  hintText: '',
                  icon: Icons.calendar_today_outlined,
                ),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Please select a date' : null,
              ),
              const SizedBox(height: 12),

              _buildLabel('Condition *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _conditionController,
                style: const TextStyle(fontSize: 14),
                decoration: _buildInputDecoration(
                  hintText: 'e.g., Mastitis with swelling...',
                  icon: Icons.medical_information_outlined,
                ),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Condition is required' : null,
              ),
              const SizedBox(height: 12),

              _buildLabel('Medicine'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _medicineController,
                style: const TextStyle(fontSize: 14),
                decoration: _buildInputDecoration(
                  hintText: 'e.g., Amoxicillin - 500mg (7 days)',
                  icon: Icons.medication_outlined,
                ),
              ),
              const SizedBox(height: 12),

              _buildLabel('Treatment *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _treatmentController,
                style: const TextStyle(fontSize: 14),
                decoration: _buildInputDecoration(
                  hintText: 'e.g., Antibiotic course + hot compress',
                  icon: Icons.healing_outlined,
                ),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Treatment is required' : null,
              ),
              const SizedBox(height: 12),

              _buildLabel('Notes'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
                decoration: _buildInputDecoration(
                  hintText: 'Monitor swelling and temperature daily.',
                  icon: Icons.description_outlined,
                ),
              ),
              const SizedBox(height: 12),

              _buildLabel('Status'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _status,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF6B7280),
                ),
                items: ['Follow Up', 'Completed', 'Ongoing'].map((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _status = newValue!;
                  });
                },
                decoration: _buildInputDecoration(
                  hintText: '',
                  icon: Icons.schedule_outlined,
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveRecord,
                  icon: _isSaving
                      ? const SizedBox.shrink()
                      : const Icon(
                          Icons.save_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                  label: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Health Record',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E7D42),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Animals is active
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF20B769), // primaryGreen from home
        unselectedItemColor: const Color(0xFF7D8B83),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          if (index == 0) {
            _openFarmerHome();
          } else if (index == 1) {
            // Already in Animals flow, do nothing or pop to root
          } else if (index == 2) {
            _openFindVet();
          } else if (index == 3) {
            _openMyAppointments();
          } else if (index == 4) {
            _openFarmerProfile();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_rounded),
            label: 'Animals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            label: 'Consult',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Color(0xFF1E5936),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: const Color(0xFF1E5936), size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5EAE7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5EAE7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E7D42), width: 1.5),
      ),
    );
  }
}
