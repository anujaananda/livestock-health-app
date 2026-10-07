import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../data/local_data.dart';

class TreatmentHistoryTab extends StatefulWidget {
  const TreatmentHistoryTab({super.key});

  @override
  State<TreatmentHistoryTab> createState() => _TreatmentHistoryTabState();
}

class _TreatmentHistoryTabState extends State<TreatmentHistoryTab> {
  final LocalData _data = LocalData();

  void _showAddEditDialog([Treatment? existing]) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String status = existing?.status ?? 'Completed';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Treatment' : 'Edit Treatment'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Medicine Name'),
                  validator: (value) => value!.trim().isEmpty
                      ? 'Medicine Name is required'
                      : null,
                ),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dosage / Instructions',
                  ),
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Dosage is required' : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: ['Completed', 'Ongoing']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => status = val!,
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  if (existing == null) {
                    _data.addTreatment(
                      Treatment(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        animalId: _data.currentAnimal.id,
                        date: DateTime.now(),
                        title: titleCtrl.text,
                        description: descCtrl.text,
                        status: status,
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Treatment added successfully'),
                      ),
                    );
                  } else {
                    _data.updateTreatment(
                      Treatment(
                        id: existing.id,
                        animalId: existing.animalId,
                        date: existing.date,
                        title: titleCtrl.text,
                        description: descCtrl.text,
                        status: status,
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Treatment updated successfully'),
                      ),
                    );
                  }
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Treatment'),
        content: const Text('Are you sure you want to delete this treatment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _data.deleteTreatment(id);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Treatment deleted successfully')),
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
    final treatments = _data.treatments;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.medical_services,
                  color: Colors.green,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Treatment History',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'List of past treatments and medications.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => _showAddEditDialog(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: treatments.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final t = treatments[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.vaccines, color: Colors.grey, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('yyyy-MM-dd').format(t.date),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.description,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          t.status,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onSelected: (value) {
                            if (value == 'edit') _showAddEditDialog(t);
                            if (value == 'delete') _confirmDelete(t.id);
                          },
                          itemBuilder: (context) => [
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
