import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/local_data.dart';
import '../screens/add_health_record_screen.dart';

class HealthStatusTab extends StatefulWidget {
  final Map<String, dynamic> animal;

  const HealthStatusTab({super.key, required this.animal});

  @override
  State<HealthStatusTab> createState() => _HealthStatusTabState();
}

class _HealthStatusTabState extends State<HealthStatusTab> {
  final LocalData _data = LocalData();

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Health Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _data.deleteHealthRecord(id);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Health record deleted successfully'),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    final records = _data.healthRecords
        .where((r) => r.animalId == animal['id'].toString())
        .toList();
    records.sort((a, b) => b.date.compareTo(a.date));
    final latestRecord = records.isNotEmpty ? records.first : null;

    String notesText = 'Active and eating well. No signs of illness.';
    if (latestRecord != null && latestRecord.notes.trim().isNotEmpty) {
      notesText = latestRecord.notes;
    } else if ((animal['health_status'] ?? '').toString().toLowerCase() !=
        'healthy') {
      notesText = 'Monitoring required. Please check recent health records.';
    }

    String lastUpdatedText = latestRecord != null
        ? 'Last updated: ${DateFormat('yyyy-MM-dd').format(latestRecord.date)}'
        : 'Last updated: N/A';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  (animal['health_status'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains('health')
                  ? Colors.green[50]
                  : Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    (animal['health_status'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains('health')
                    ? Colors.green[200]!
                    : Colors.orange[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color:
                      (animal['health_status'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains('health')
                      ? Colors.green
                      : Colors.orange,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Health Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (animal['health_status'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .contains('health')
                              ? Colors.green
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (animal['health_status'] ?? 'Healthy').toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (animal['health_status'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains('health')
                            ? '${animal['name'] ?? 'Unnamed'} is in good health. No major issues reported.'
                            : '${animal['name'] ?? 'Unnamed'} requires attention and monitoring.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Vital Signs',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildVitalRow(Icons.thermostat, 'Temperature', '38.5 °C', 'Normal'),
          const Divider(),
          _buildVitalRow(
            Icons.favorite_border,
            'Heart Rate',
            '72 bpm',
            'Normal',
          ),
          const Divider(),
          _buildVitalRow(Icons.air, 'Respiration Rate', '18 /min', 'Normal'),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notes, color: Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notesText,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastUpdatedText,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent Health Records',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          records.isEmpty
              ? const Text(
                  'No recent health records.',
                  style: TextStyle(color: Colors.grey),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: records.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final r = records[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd').format(r.date),
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
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddHealthRecordScreen(
                                        animalId: animal['id'].toString(),
                                        existingRecord: r,
                                      ),
                                    ),
                                  );
                                  setState(() {});
                                } else if (val == 'delete') {
                                  _confirmDelete(r.id);
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
                        Text('Condition: ${r.condition}'),
                        if (r.medicine.trim().isNotEmpty)
                          Text('Medicine: ${r.medicine}'),
                        Text('Treatment: ${r.treatment}'),
                        Text('Status: ${r.status}'),
                        if (r.notes.trim().isNotEmpty)
                          Text('Notes: ${r.notes}'),
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black87)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Text(
            status,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
