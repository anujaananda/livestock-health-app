import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicalRecordsTab extends StatefulWidget {
  final Map<String, dynamic> animal;

  const MedicalRecordsTab({super.key, required this.animal});

  @override
  State<MedicalRecordsTab> createState() => _MedicalRecordsTabState();
}

class _MedicalRecordsTabState extends State<MedicalRecordsTab> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('medical_records')
          .select()
          .eq('animal_id', widget.animal['id'].toString())
          .order('record_date', ascending: false);

      setState(() {
        _records = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load medical records: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddEditDialog([Map<String, dynamic>? existing]) {
    final titleCtrl = TextEditingController(
      text: existing?['record_name'] ?? '',
    );
    final notesCtrl = TextEditingController(text: existing?['notes'] ?? '');
    String recordType = existing?['record_type'] ?? 'General';

    DateTime selectedDate = DateTime.now();
    if (existing?['record_date'] != null) {
      selectedDate =
          DateTime.tryParse(existing!['record_date']) ?? DateTime.now();
    }

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Add Medical Record' : 'Edit Medical Record',
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
                          labelText: 'Record Name',
                        ),
                        validator: (value) => value!.trim().isEmpty
                            ? 'Medical record name is required.'
                            : null,
                      ),
                      DropdownButtonFormField<String>(
                        value:
                            [
                              'General',
                              'Test',
                              'Diagnosis',
                              'Prescription',
                              'Other',
                            ].contains(recordType)
                            ? recordType
                            : 'General',
                        items:
                            [
                                  'General',
                                  'Test',
                                  'Diagnosis',
                                  'Prescription',
                                  'Other',
                                ]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => recordType = val!,
                        decoration: const InputDecoration(
                          labelText: 'Record Type',
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
                      TextFormField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                        ),
                        maxLines: 3,
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
                              ScaffoldMessenger.of(statefulContext)
                                  .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Medical record date cannot be in the future.',
                                      ),
                                    ),
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
                              'record_type': recordType,
                              'record_name': titleCtrl.text.trim(),
                              'record_date': DateFormat('yyyy-MM-dd')
                                  .format(selectedDate),
                              'notes': notesCtrl.text.trim().isEmpty
                                  ? null
                                  : notesCtrl.text.trim(),
                            };

                            try {
                              if (existing == null) {
                                await Supabase.instance.client
                                    .from('medical_records')
                                    .insert(data);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Medical record added successfully',
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                await Supabase.instance.client
                                    .from('medical_records')
                                    .update(data)
                                    .eq('id', existing['id']);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Medical record updated successfully',
                                      ),
                                    ),
                                  );
                                }
                              }
                              if (mounted) {
                                Navigator.pop(dialogContext);
                                _fetchRecords();
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
        title: const Text('Delete Medical Record'),
        content: const Text('Are you sure you want to delete this record?'),
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
                    .from('medical_records')
                    .delete()
                    .eq('id', id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Medical record deleted successfully'),
                    ),
                  );
                  _fetchRecords();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting medical record: $e'),
                    ),
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

    IconData getIconForType(String type) {
      final t = type.toLowerCase();
      if (t.contains('general') || t.contains('health'))
        return Icons.health_and_safety;
      if (t.contains('test') || t.contains('blood')) return Icons.science;
      if (t.contains('diagnosis')) return Icons.medical_information;
      if (t.contains('prescription')) return Icons.medication;
      return Icons.description;
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
                    Icons.description,
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
                        'Medical Records',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E5936),
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'View detailed medical test records.',
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
          _records.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    'No medical records found.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final r = _records[index];
                    final dateStr = r['record_date'] as String?;
                    final date = dateStr != null
                        ? DateTime.tryParse(dateStr)
                        : null;
                    final formattedDate = date != null
                        ? DateFormat('yyyy-MM-dd').format(date)
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            getIconForType(r['record_type'] ?? ''),
                            color: const Color(0xFF6B7280),
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['record_name'] ?? 'Unnamed',
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text(
                                    'Medical Record Details',
                                    style: TextStyle(
                                      color: Color(0xFF1E5936),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Record Name: ${r['record_name'] ?? 'Unnamed'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Type: ${r['record_type'] ?? 'General'}',
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Date: $formattedDate'),
                                      if (r['notes'] != null &&
                                          r['notes'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text('Notes: ${r['notes']}'),
                                      ],
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        'Close',
                                        style: TextStyle(
                                          color: Color(0xFF1E7D42),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF1E7D42),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 32),
                              backgroundColor: const Color(0xFFE6F4EA),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'View',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
                              if (value == 'edit') _showAddEditDialog(r);
                              if (value == 'delete') _confirmDelete(r['id']);
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
                    );
                  },
                ),
        ],
      ),
    );
  }
}
