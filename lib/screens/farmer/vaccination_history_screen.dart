import 'package:flutter/material.dart';

import '../../models/vaccination_model.dart';
import '../../services/vaccination_service.dart';

class VaccinationHistoryScreen extends StatefulWidget {
  final String animalId;

  const VaccinationHistoryScreen({super.key, required this.animalId});

  @override
  State<VaccinationHistoryScreen> createState() =>
      _VaccinationHistoryScreenState();
}

class _VaccinationHistoryScreenState extends State<VaccinationHistoryScreen> {
  static const Color primaryGreen = Color(0xFF20B769);

  final VaccinationService _service = VaccinationService();
  List<VaccinationModel> _vaccinations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVaccinations();
  }

  Future<void> _loadVaccinations() async {
    final vaccinations = await _service.getVaccinations(widget.animalId);
    setState(() {
      _vaccinations = vaccinations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vaccinations.isEmpty) {
      return const Center(
        child: Text(
          'No vaccination records',
          style: TextStyle(color: Color(0xFF697A71)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _vaccinations.length,
      itemBuilder: (context, index) {
        return _buildVaccinationCard(_vaccinations[index]);
      },
    );
  }

  Widget _buildVaccinationCard(VaccinationModel vaccination) {
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
              Icons.vaccines_outlined,
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
                  vaccination.vaccineName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3027),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: ${vaccination.vaccinationDate.toString().split(' ')[0]}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF697A71),
                  ),
                ),
                if (vaccination.nextDueDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Next due: ${vaccination.nextDueDate.toString().split(' ')[0]}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF697A71),
                    ),
                  ),
                ],
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
              vaccination.status,
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
