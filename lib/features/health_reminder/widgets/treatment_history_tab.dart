import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'top_toast.dart';

class TreatmentHistoryTab extends StatefulWidget {
  final Map<String, dynamic> animal;

  const TreatmentHistoryTab({super.key, required this.animal});

  @override
  State<TreatmentHistoryTab> createState() => _TreatmentHistoryTabState();
}

class _TreatmentHistoryTabState extends State<TreatmentHistoryTab> {
  List<Map<String, dynamic>> _treatments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTreatments();
  }

  Future<void> _fetchTreatments() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('treatments')
          .select()
          .eq('animal_id', widget.animal['id'].toString())
          .order('treatment_date', ascending: false);

      setState(() {
        _treatments = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        TopToast.show(context, 'Failed to load treatments: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddEditDialog([Map<String, dynamic>? existing]) {
    final titleCtrl = TextEditingController(
      text: existing?['treatment_name'] ?? '',
    );
    final medicineCtrl = TextEditingController(
      text: existing?['medicine'] ?? '',
    );
    final descCtrl = TextEditingController(text: existing?['dosage'] ?? '');
    String status = existing?['status'] ?? 'Completed';
    final formKey = GlobalKey<FormState>();

    DateTime selectedDate = DateTime.now();
    if (existing?['treatment_date'] != null) {
      selectedDate =
          DateTime.tryParse(existing!['treatment_date']) ?? DateTime.now();
    }

    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Add Treatment' : 'Edit Treatment',
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Treatment Name',
                        ),
                        validator: (value) => value!.trim().isEmpty
                            ? 'Please enter a treatment name.'
                            : null,
                      ),
                      TextFormField(
                        controller: medicineCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Medicine Name',
                        ),
                      ),
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Dosage / Instructions',
                        ),
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
                                });
                              }
                            },
                            child: const Text('Select Date'),
                          ),
                        ],
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        items: ['Completed', 'Ongoing']
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
                              TopToast.show(
                                statefulContext,
                                'Treatment date cannot be in the future.',
                                isError: true,
                              );
                              return;
                            }

                            setDialogState(() => isSaving = true);

                            final userId =
                                Supabase.instance.client.auth.currentUser!.id;
                            final animalId = widget.animal['id'].toString();

                            final Map<String, dynamic> data = {
                              'animal_id': animalId,
                              'owner_id': userId,
                              'treatment_name': titleCtrl.text.trim(),
                              'medicine': medicineCtrl.text.trim().isEmpty
                                  ? null
                                  : medicineCtrl.text.trim(),
                              'dosage': descCtrl.text.trim().isEmpty
                                  ? null
                                  : descCtrl.text.trim(),
                              'status': status,
                              'treatment_date': DateFormat('yyyy-MM-dd')
                                  .format(selectedDate),
                            };

                            try {
                              if (existing == null) {
                                await Supabase.instance.client
                                    .from('treatments')
                                    .insert(data);
                                if (mounted) {
                                  TopToast.show(
                                    context,
                                    'Treatment added successfully',
                                  );
                                }
                              } else {
                                await Supabase.instance.client
                                    .from('treatments')
                                    .update(data)
                                    .eq('id', existing['id']);
                                if (mounted) {
                                  TopToast.show(
                                    context,
                                    'Treatment updated successfully',
                                  );
                                }
                              }
                              if (mounted) {
                                Navigator.pop(dialogContext);
                                _fetchTreatments();
                              }
                            } catch (e) {
                              if (mounted) {
                                TopToast.show(
                                  context,
                                  'Error: $e',
                                  isError: true,
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
        title: const Text('Delete Treatment'),
        content: const Text('Are you sure you want to delete this treatment?'),
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
                    .from('treatments')
                    .delete()
                    .eq('id', id);
                if (mounted) {
                  TopToast.show(context, 'Treatment deleted successfully');
                  _fetchTreatments();
                }
              } catch (e) {
                if (mounted) {
                  TopToast.show(
                    context,
                    'Error deleting treatment: $e',
                    isError: true,
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

    IconData getIconForTreatment(String name, String dosage) {
      final text = '${name.toLowerCase()} ${dosage.toLowerCase()}';
      if (text.contains('antibiotic') ||
          text.contains('pill') ||
          text.contains('med'))
        return Icons.medication;
      if (text.contains('deworm')) return Icons.vaccines;
      if (text.contains('wound') || text.contains('injury'))
        return Icons.health_and_safety;
      if (text.contains('pain')) return Icons.healing;
      if (text.contains('injection') || text.contains('vaccine'))
        return Icons.vaccines;
      return Icons.medical_services;
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
                    Icons.medical_services,
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
                        'Treatment History',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E5936),
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'List of past treatments and medications.',
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
          _treatments.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    'No treatment records found.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _treatments.length,
                  itemBuilder: (context, index) {
                    final t = _treatments[index];
                    final dateStr = t['treatment_date'] as String?;
                    final date = dateStr != null
                        ? DateTime.tryParse(dateStr)
                        : null;
                    final formattedDate = date != null
                        ? DateFormat('yyyy-MM-dd').format(date)
                        : 'Unknown';

                    final medicine = t['medicine']?.toString().trim() ?? '';
                    final dosage = t['dosage']?.toString().trim() ?? '';
                    String secondaryText = '';
                    if (medicine.isNotEmpty && dosage.isNotEmpty) {
                      secondaryText = '$medicine • $dosage';
                    } else if (medicine.isNotEmpty) {
                      secondaryText = medicine;
                    } else if (dosage.isNotEmpty) {
                      secondaryText = dosage;
                    }

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
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Icon(
                              getIconForTreatment(
                                t['treatment_name'] ?? '',
                                (t['medicine'] ?? t['dosage'] ?? '').toString(),
                              ),
                              color: const Color(0xFF6B7280),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t['treatment_name'] ?? 'Unnamed',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                if (secondaryText.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    secondaryText,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
                                  color: (t['status'] == 'Completed')
                                      ? const Color(0xFFE6F4EA)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  t['status'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: (t['status'] == 'Completed')
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
                                  if (value == 'edit') _showAddEditDialog(t);
                                  if (value == 'delete')
                                    _confirmDelete(t['id']);
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
