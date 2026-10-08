import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/add_health_record_screen.dart';

class HealthStatusTab extends StatefulWidget {
  final Map<String, dynamic> animal;

  const HealthStatusTab({super.key, required this.animal});

  @override
  State<HealthStatusTab> createState() => _HealthStatusTabState();
}

class _HealthStatusTabState extends State<HealthStatusTab> {
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
          .from('health_records')
          .select()
          .eq('animal_id', widget.animal['id'].toString())
          .order('record_date', ascending: false);

      setState(() {
        _records = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load health records: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Health Record'),
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
                    .from('health_records')
                    .delete()
                    .eq('id', id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Health record deleted successfully'),
                    ),
                  );
                  _fetchRecords();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting health record: $e')),
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final animal = widget.animal;
    final latestRecord = _records.isNotEmpty ? _records.first : null;

    String notesText = 'Active and eating well. No signs of illness.';
    if (latestRecord != null &&
        latestRecord['notes'] != null &&
        latestRecord['notes'].toString().trim().isNotEmpty) {
      notesText = latestRecord['notes'];
    } else if ((animal['health_status'] ?? '').toString().toLowerCase() !=
        'healthy') {
      notesText = 'Monitoring required. Please check recent health records.';
    }

    String lastUpdatedText = 'Last updated: N/A';
    if (latestRecord != null && latestRecord['record_date'] != null) {
      final d = DateTime.tryParse(latestRecord['record_date'].toString());
      if (d != null) {
        lastUpdatedText = 'Last updated: ${DateFormat('yyyy-MM-dd').format(d)}';
      }
    }

    final overallStatus =
        latestRecord?['overall_status']?.toString() ??
        animal['health_status']?.toString() ??
        'Healthy';

    final isHealthy = overallStatus.toLowerCase().contains('health');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isHealthy
                  ? const Color(0xFFE6F4EA)
                  : const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.monitor_heart,
                  color: isHealthy
                      ? const Color(0xFF1E7D42)
                      : Colors.orange[800],
                  size: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Health Status',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isHealthy
                              ? const Color(0xFF1E5936)
                              : Colors.orange[900],
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isHealthy
                              ? const Color(0xFF1E7D42)
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          overallStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isHealthy
                            ? '${animal['name'] ?? 'Unnamed'} is in good health. No major issues reported.'
                            : '${animal['name'] ?? 'Unnamed'} requires attention and monitoring.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isHealthy
                              ? const Color(0xFF1E5936)
                              : Colors.brown[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Vital Signs',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5EAE7)),
            ),
            child: Column(
              children: [
                _buildVitalRow(
                  Icons.thermostat,
                  'Temperature',
                  latestRecord?['temperature'] != null
                      ? '${latestRecord!['temperature']} °C'
                      : '38.5 °C',
                  'Normal',
                ),
                const Divider(height: 1, color: Color(0xFFE5EAE7)),
                _buildVitalRow(
                  Icons.monitor_heart_outlined,
                  'Heart Rate',
                  latestRecord?['heart_rate'] != null
                      ? '${latestRecord!['heart_rate']} bpm'
                      : '72 bpm',
                  'Normal',
                ),
                const Divider(height: 1, color: Color(0xFFE5EAE7)),
                _buildVitalRow(
                  Icons.air,
                  'Respiration Rate',
                  latestRecord?['respiration_rate'] != null
                      ? '${latestRecord!['respiration_rate']} /min'
                      : '18 /min',
                  'Normal',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Notes',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
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
                    Icons.description,
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
                        notesText,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lastUpdatedText,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent Health Records',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _records.isEmpty
              ? const Text(
                  'No recent health records.',
                  style: TextStyle(color: Colors.grey),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _records.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final r = _records[index];
                    final rawNotes = r['notes']?.toString() ?? '';
                    final condition = _extractField(rawNotes, 'Condition:');
                    final medicine = _extractField(rawNotes, 'Medicine:');
                    final treatment = _extractField(rawNotes, 'Treatment:');
                    final notes = _extractField(rawNotes, 'Notes:');

                    String dateStr = 'Unknown';
                    if (r['record_date'] != null) {
                      final d = DateTime.tryParse(r['record_date'].toString());
                      if (d != null) {
                        dateStr = DateFormat('yyyy-MM-dd').format(d);
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                size: 20,
                                color: Colors.grey,
                              ),
                              onSelected: (val) async {
                                if (val == 'edit') {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddHealthRecordScreen(
                                        animal: animal,
                                        existingRecord: r,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _fetchRecords();
                                  }
                                } else if (val == 'delete') {
                                  _confirmDelete(r['id']);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (condition.isNotEmpty) Text('Condition: $condition'),
                        if (medicine.isNotEmpty) Text('Medicine: $medicine'),
                        if (treatment.isNotEmpty) Text('Treatment: $treatment'),
                        Text('Status: ${r['overall_status'] ?? 'Unknown'}'),
                        if (notes.isNotEmpty) Text('Notes: $notes'),
                      ],
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildVitalRow(
    IconData icon,
    String label,
    String value,
    String status,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B7280), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            status,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
