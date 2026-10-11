import 'package:flutter/material.dart';

import '../../models/treatment_model.dart';
import '../../services/treatment_service.dart';

class TreatmentHistoryScreen extends StatefulWidget {
  final String animalId;

  const TreatmentHistoryScreen({super.key, required this.animalId});

  @override
  State<TreatmentHistoryScreen> createState() => _TreatmentHistoryScreenState();
}

class _TreatmentHistoryScreenState extends State<TreatmentHistoryScreen> {
  static const Color primaryGreen = Color(0xFF20B769);

  final TreatmentService _service = TreatmentService();
  List<TreatmentModel> _treatments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTreatments();
  }

  Future<void> _loadTreatments() async {
    final treatments = await _service.getTreatments(widget.animalId);
    setState(() {
      _treatments = treatments;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_treatments.isEmpty) {
      return const Center(
        child: Text(
          'No treatment records',
          style: TextStyle(color: Color(0xFF697A71)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _treatments.length,
      itemBuilder: (context, index) {
        final treatment = _treatments[index];
        return _buildTreatmentCard(treatment);
      },
    );
  }

  Widget _buildTreatmentCard(TreatmentModel treatment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5F0E9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medication_outlined,
              color: primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${treatment.treatmentDate.toString().split(' ')[0]}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  treatment.treatmentName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3027),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  treatment.medicine ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF697A71),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7EA),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              treatment.status,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF20B769),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
