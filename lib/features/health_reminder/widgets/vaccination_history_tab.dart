import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VaccinationHistoryTab extends StatefulWidget {
  final Map<String, dynamic> animal;

  const VaccinationHistoryTab({super.key, required this.animal});

  @override
  State<VaccinationHistoryTab> createState() => _VaccinationHistoryTabState();
}

class _VaccinationHistoryTabState extends State<VaccinationHistoryTab> {
  List<Map<String, dynamic>> _vaccinations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVaccinations();
  }

  Future<void> _fetchVaccinations() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('vaccinations')
          .select()
          .eq('animal_id', widget.animal['id'].toString())
          .order('vaccination_date', ascending: false);

      setState(() {
        _vaccinations = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load vaccinations: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddEditDialog([Map<String, dynamic>? existing]) {
    final nameCtrl = TextEditingController(
      text: existing?['vaccine_name'] ?? '',
    );
    String status = existing?['status'] ?? 'Completed';
    final formKey = GlobalKey<FormState>();

    DateTime selectedDate = DateTime.now();
    if (existing?['vaccination_date'] != null) {
      selectedDate =
          DateTime.tryParse(existing!['vaccination_date']) ?? DateTime.now();
    }

    DateTime? nextDueDate;
    if (existing?['next_due_date'] != null) {
      nextDueDate = DateTime.tryParse(existing!['next_due_date']);
    }

    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Add Vaccination' : 'Edit Vaccination',
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Vaccine Name',
                        ),
                        validator: (value) => value!.trim().isEmpty
                            ? 'Please enter a vaccine name.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final now = DateTime.now();
                              final today = DateTime(
                                now.year,
                                now.month,
                                now.day,
                              );
                              final picked = await showDatePicker(
                                context: statefulContext,
                                initialDate: selectedDate.isAfter(today)
                                    ? today
                                    : selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: today,
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  selectedDate = picked;
                                  if (nextDueDate != null &&
                                      !nextDueDate!.isAfter(selectedDate)) {
                                    nextDueDate = null;
                                  }
                                });
                              }
                            },
                            child: const Text('Select Date'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nextDueDate != null
                                  ? 'Next Due: ${DateFormat('yyyy-MM-dd').format(nextDueDate!)}'
                                  : 'Next Due: Not set',
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: statefulContext,
                                initialDate:
                                    nextDueDate ??
                                    selectedDate.add(const Duration(days: 1)),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  nextDueDate = picked;
                                });
                              }
                            },
                            child: const Text('Select Due Date'),
                          ),
                        ],
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        items: ['Completed', 'Pending']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (val) => status = val!,
                        decoration: const InputDecoration(labelText: 'Status'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            final now = DateTime.now();
                            final today = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );
                            final selected = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                            );
                            if (selected.isAfter(today)) {
                              ScaffoldMessenger.of(
                                statefulContext,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Vaccination date cannot be in the future.',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (nextDueDate != null) {
                              final next = DateTime(
                                nextDueDate!.year,
                                nextDueDate!.month,
                                nextDueDate!.day,
                              );
                              if (!next.isAfter(selected)) {
                                ScaffoldMessenger.of(statefulContext)
                                    .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Next due date must be after the vaccination date.',
                                        ),
                                      ),
                                    );
                                return;
                              }
                            }

                            setDialogState(() => isSaving = true);

                            final userId =
                                Supabase.instance.client.auth.currentUser!.id;
                            final animalId = widget.animal['id'].toString();

                            final Map<String, dynamic> data = {
                              'animal_id': animalId,
                              'owner_id': userId,
                              'vaccine_name': nameCtrl.text.trim(),
                              'status': status,
                              'vaccination_date': DateFormat('yyyy-MM-dd')
                                  .format(selectedDate),
                            };

                            if (nextDueDate != null) {
                              data['next_due_date'] = DateFormat('yyyy-MM-dd')
                                  .format(nextDueDate!);
                            } else {
                              data['next_due_date'] = null;
                            }

                            try {
                              if (existing == null) {
                                await Supabase.instance.client
                                    .from('vaccinations')
                                    .insert(data);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vaccination added successfully',
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                await Supabase.instance.client
                                    .from('vaccinations')
                                    .update(data)
                                    .eq('id', existing['id']);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vaccination updated successfully',
                                      ),
                                    ),
                                  );
                                }
                              }
                              if (mounted) {
                                Navigator.pop(dialogContext);
                                _fetchVaccinations();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setDialogState(() => isSaving = false);
                              }
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Vaccination'),
        content: const Text(
          'Are you sure you want to delete this vaccination?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await Supabase.instance.client
                    .from('vaccinations')
                    .delete()
                    .eq('id', id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vaccination deleted successfully'),
                    ),
                  );
                  _fetchVaccinations();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting vaccination: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.colorize,
                    color: Color(0xFF1E7D42),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Vaccination History',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E5936),
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'List of vaccinations and due dates.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E5936),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Color(0xFF1E7D42),
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showAddEditDialog(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _vaccinations.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    'No vaccination records found.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _vaccinations.length,
                  itemBuilder: (context, index) {
                    final v = _vaccinations[index];
                    final dateStr = v['vaccination_date'] as String?;
                    final date = dateStr != null
                        ? DateTime.tryParse(dateStr)
                        : null;
                    final formattedDate = date != null
                        ? DateFormat('yyyy-MM-dd').format(date)
                        : 'Unknown';

                    final nextDueStr = v['next_due_date'] as String?;
                    final nextDue = nextDueStr != null
                        ? DateTime.tryParse(nextDueStr)
                        : null;
                    final formattedNextDue = nextDue != null
                        ? DateFormat('yyyy-MM-dd').format(nextDue)
                        : 'Unknown';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 8.0,
                        top: 12.0,
                        bottom: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5EAE7)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Icon(
                              Icons.calendar_today,
                              color: Color(0xFF6B7280),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v['vaccine_name'] ?? 'Unnamed',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Next due: $formattedNextDue',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (v['status'] == 'Completed')
                                      ? const Color(0xFFE6F4EA)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  v['status'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: (v['status'] == 'Completed')
                                        ? const Color(0xFF1E7D42)
                                        : const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  size: 20,
                                  color: Color(0xFF6B7280),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onSelected: (value) {
                                  if (value == 'edit') _showAddEditDialog(v);
                                  if (value == 'delete')
                                    _confirmDelete(v['id']);
                                },
                                itemBuilder: (context) => [
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
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
