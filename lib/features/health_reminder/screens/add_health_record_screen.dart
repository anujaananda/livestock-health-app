import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../data/local_data.dart';

class AddHealthRecordScreen extends StatefulWidget {
  final String animalId;
  final HealthRecord? existingRecord;

  const AddHealthRecordScreen({
    super.key,
    required this.animalId,
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
  String _status = 'Follow Up'; // Default status
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _animalId = widget.animalId;
    if (widget.existingRecord != null) {
      _selectedDate = widget.existingRecord!.date;
      _conditionController.text = widget.existingRecord!.condition;
      _medicineController.text = widget.existingRecord!.medicine;
      _treatmentController.text = widget.existingRecord!.treatment;
      _notesController.text = widget.existingRecord!.notes;
      _status = widget.existingRecord!.status;
    }
    _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate);
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate);
      });
    }
  }

  void _saveRecord() {
    if (_formKey.currentState!.validate()) {
      final record = HealthRecord(
        id:
            widget.existingRecord?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        animalId: _animalId,
        date: _selectedDate,
        condition: _conditionController.text,
        medicine: _medicineController.text,
        treatment: _treatmentController.text,
        notes: _notesController.text,
        status: _status,
      );

      if (widget.existingRecord == null) {
        LocalData().addHealthRecord(record);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health record added successfully')),
        );
      } else {
        LocalData().updateHealthRecord(record);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health record updated successfully')),
        );
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingRecord == null
              ? 'Add Health Record'
              : 'Edit Health Record',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
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
              const Text(
                'Animal ID',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _animalId,
                readOnly: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Date *',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    color: Colors.grey,
                  ),
                ),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Please select a date' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Condition *',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _conditionController,
                decoration: InputDecoration(
                  hintText: 'e.g., Mastitis with swelling...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Condition is required' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Medicine',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _medicineController,
                decoration: InputDecoration(
                  hintText: 'e.g., Amoxicillin - 500mg (7 days)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Treatment *',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _treatmentController,
                decoration: InputDecoration(
                  hintText: 'e.g., Antibiotic course + hot compress',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Treatment is required' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Notes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Monitor swelling and temperature daily',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _status,
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
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Health Record',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
