import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../screens/farmer/my_animals_screen.dart';
import '../../../screens/vet_booking/find_vet_screen.dart';
import '../../../screens/vet_booking/my_appointments_screen.dart';
import '../../../screens/vet_booking/farmer_profile_screen.dart';

void _showTopFeedback(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isError ? Colors.red[700] : const Color(0xFF1E7D42),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 3), () {
    if (entry.mounted) entry.remove();
  });
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _animals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnimals();
    _fetchReminders();
  }

  Future<void> _fetchAnimals() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('animals')
          .select('name, animal_id_tag')
          .eq('owner_id', user.id);

      if (mounted) {
        setState(() {
          _animals = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      if (mounted) {
        _showTopFeedback(context, 'Failed to load animals: $e', isError: true);
      }
    }
  }

  Future<void> _fetchReminders() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('reminders')
          .select()
          .eq('owner_id', user.id);

      final List<Map<String, dynamic>> fetched =
          List<Map<String, dynamic>>.from(response);

      // Sort: Pending first, then completed. Then by date/time
      fetched.sort((a, b) {
        final aCompleted = a['is_completed'] == true;
        final bCompleted = b['is_completed'] == true;

        if (aCompleted != bCompleted) {
          return aCompleted ? 1 : -1;
        }

        final aDateStr = a['reminder_date']?.toString() ?? '';
        final aTimeStr = a['reminder_time']?.toString() ?? '';
        final bDateStr = b['reminder_date']?.toString() ?? '';
        final bTimeStr = b['reminder_time']?.toString() ?? '';

        final aDateTime =
            DateTime.tryParse('$aDateStr $aTimeStr') ?? DateTime.now();
        final bDateTime =
            DateTime.tryParse('$bDateStr $bTimeStr') ?? DateTime.now();

        return aDateTime.compareTo(bDateTime);
      });

      if (mounted) {
        setState(() {
          _reminders = fetched;
        });
      }
    } catch (e) {
      if (mounted) {
        _showTopFeedback(
          context,
          'Failed to load reminders: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteReminder(String id) async {
    try {
      await Supabase.instance.client.from('reminders').delete().eq('id', id);
      if (mounted) {
        _showTopFeedback(context, 'Reminder deleted successfully');
      }
      _fetchReminders();
    } catch (e) {
      if (mounted) {
        _showTopFeedback(context, 'Error deleting reminder: $e', isError: true);
      }
    }
  }

  Future<void> _toggleCompletion(String id, bool currentStatus) async {
    try {
      await Supabase.instance.client
          .from('reminders')
          .update({'is_completed': !currentStatus})
          .eq('id', id);
      _fetchReminders();
    } catch (e) {
      if (mounted) {
        _showTopFeedback(context, 'Error updating status: $e', isError: true);
      }
    }
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteReminder(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openMyAnimals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyAnimalsScreen()),
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

  void _openReminderForm({Map<String, dynamic>? existingReminder}) {
    if (_animals.isEmpty) {
      _showTopFeedback(
        context,
        'You must add an animal first to create a reminder.',
        isError: true,
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _ReminderFormSheet(
        animals: _animals,
        existingReminder: existingReminder,
        onSave: _fetchReminders,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reminders')),
        body: const Center(child: Text('Please log in to view reminders.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reminders',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
          ? const Center(
              child: Text(
                'No reminders found.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final r = _reminders[index];
                final isCompleted = r['is_completed'] == true;
                final title = r['title']?.toString() ?? 'Reminder';
                final animalName =
                    r['animal_name']?.toString() ?? 'Unknown Animal';
                final date = r['reminder_date']?.toString() ?? '';
                final time = r['reminder_time']?.toString() ?? '';
                final type = r['type']?.toString() ?? 'General';
                final id = r['id'].toString();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: isCompleted ? Colors.grey[50] : Colors.green[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isCompleted
                                      ? Colors.grey
                                      : Colors.black,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? Colors.grey[200]
                                    : Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isCompleted ? 'Completed' : 'Pending',
                                style: TextStyle(
                                  color: isCompleted
                                      ? Colors.grey[700]
                                      : Colors.deepOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.grey,
                              ),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openReminderForm(existingReminder: r);
                                } else if (value == 'delete') {
                                  _showDeleteConfirmation(id);
                                } else if (value == 'toggle') {
                                  _toggleCompletion(id, isCompleted);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Text(
                                    isCompleted
                                        ? 'Mark as Pending'
                                        : 'Mark as Completed',
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.pets,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              animalName,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.category,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              type,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              date,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              time,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openReminderForm(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Home is active
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF20B769), // primaryGreen from home
        unselectedItemColor: const Color(0xFF7D8B83),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context); // Go back to Home
          } else if (index == 1) {
            _openMyAnimals();
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
}

class _ReminderFormSheet extends StatefulWidget {
  final List<Map<String, dynamic>> animals;
  final Map<String, dynamic>? existingReminder;
  final VoidCallback onSave;

  const _ReminderFormSheet({
    required this.animals,
    this.existingReminder,
    required this.onSave,
  });

  @override
  State<_ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends State<_ReminderFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  String? _selectedAnimalName;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedType;

  final List<String> _types = [
    'Health Check',
    'Vaccination',
    'Treatment',
    'Medication',
    'Other',
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReminder != null) {
      _titleController.text =
          widget.existingReminder!['title']?.toString() ?? '';
      _selectedAnimalName = widget.existingReminder!['animal_name']?.toString();
      _selectedType = widget.existingReminder!['type']?.toString();

      final dateStr = widget.existingReminder!['reminder_date']?.toString();
      if (dateStr != null && dateStr.isNotEmpty) {
        _selectedDate = DateTime.tryParse(dateStr);
      }

      final timeStr = widget.existingReminder!['reminder_time']?.toString();
      if (timeStr != null && timeStr.isNotEmpty) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          int h = int.tryParse(parts[0]) ?? 0;
          int m = int.tryParse(parts[1].split(' ')[0]) ?? 0;
          if (timeStr.toLowerCase().contains('pm') && h < 12) h += 12;
          if (timeStr.toLowerCase().contains('am') && h == 12) h = 0;
          _selectedTime = TimeOfDay(hour: h, minute: m);
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate == null || _selectedDate!.isBefore(today)
          ? today
          : _selectedDate!,
      firstDate: today,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAnimalName == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      _showTopFeedback(
        context,
        'Please fill all required fields (Animal, Date, Time).',
        isError: true,
      );
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedD = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );

    final isCompleted = widget.existingReminder?['is_completed'] == true;
    if (!isCompleted && selectedD.isBefore(today)) {
      _showTopFeedback(
        context,
        'Reminder date cannot be in the past.',
        isError: true,
      );
      return;
    }

    if (selectedD.isAtSameMomentAs(today) && !isCompleted) {
      final nowTime = TimeOfDay.now();
      if (_selectedTime!.hour < nowTime.hour ||
          (_selectedTime!.hour == nowTime.hour &&
              _selectedTime!.minute <= nowTime.minute)) {
        _showTopFeedback(
          context,
          'Reminder time must be later than the current time.',
          isError: true,
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      final dt = DateTime(
        2000,
        1,
        1,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final timeStr = DateFormat('hh:mm a').format(dt);

      final Map<String, dynamic> data = {
        'title': _titleController.text.trim(),
        'animal_name': _selectedAnimalName,
        'reminder_date': dateStr,
        'reminder_time': timeStr,
        'type': _selectedType ?? 'General',
      };

      if (widget.existingReminder != null) {
        await Supabase.instance.client
            .from('reminders')
            .update(data)
            .eq('id', widget.existingReminder!['id']);
      } else {
        data['owner_id'] = user.id;
        data['is_completed'] = false;
        await Supabase.instance.client.from('reminders').insert(data);
      }

      if (mounted) {
        Navigator.pop(context); // close sheet
        widget.onSave();
        _showTopFeedback(
          context,
          widget.existingReminder != null
              ? 'Reminder updated successfully'
              : 'Reminder added successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        _showTopFeedback(context, 'Error saving reminder: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existingReminder != null
                    ? 'Edit Reminder'
                    : 'Add Reminder',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Reminder title is required.'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Animal Name *'),
                value: _selectedAnimalName,
                items: widget.animals.map((a) {
                  final name = a['name']?.toString() ?? '';
                  final tag = a['animal_id_tag']?.toString() ?? '';
                  final label = tag.isNotEmpty ? '$name ($tag)' : name;
                  return DropdownMenuItem(value: name, child: Text(label));
                }).toList(),
                onChanged: (val) => setState(() => _selectedAnimalName = val),
                validator: (val) => val == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date *'),
                        child: Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Time *'),
                        child: Text(
                          _selectedTime == null
                              ? 'Select Time'
                              : _selectedTime!.format(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Type'),
                value: _selectedType,
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedType = val),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.existingReminder != null
                              ? 'Update Reminder'
                              : 'Save Reminder',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
