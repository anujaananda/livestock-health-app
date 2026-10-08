import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/consultation_service.dart';
import 'my_appointments_screen.dart';

class RequestConsultationScreen extends StatefulWidget {
  const RequestConsultationScreen({super.key});

  @override
  State<RequestConsultationScreen> createState() =>
      _RequestConsultationScreenState();
}

class _RequestConsultationScreenState extends State<RequestConsultationScreen> {
  static const Color primaryGreen = Color(0xFF20B769);

  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();

  String _selectedAnimal = 'Bella (Cow)';
  String _consultationType = 'online';
  bool _isLoading = false;

  final List<String> _animals = [
    'Bella (Cow)',
    'Goaty (Goat)',
    'Moo (Cow)',
    'Snowy (Sheep)',
  ];

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authService = Provider.of<AuthService>(context, listen: false);
      final consultationService = ConsultationService();

      final success = await consultationService.createConsultation(
        farmerId: authService.currentUser!.id,
        symptoms: _symptomsController.text.trim(),
        urgency: _consultationType == 'online' ? 'Normal' : 'Urgent',
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Request Consultation',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Select Animal
              const Text(
                'Select Animal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAnimal,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: _animals.map((animal) {
                      return DropdownMenuItem<String>(
                        value: animal,
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 14,
                              backgroundColor: Color(0xFFE5F7EA),
                              child: Icon(
                                Icons.pets,
                                size: 16,
                                color: primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(animal),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedAnimal = v!),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Describe Problem
              const Text(
                'Describe the Problem',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _symptomsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe symptoms, duration, or any additional changes...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Please describe the problem' : null,
              ),

              const SizedBox(height: 20),

              // Add Photos
              const Text(
                'Add Photos (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Photo upload coming soon')),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD1D5DB),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5F7EA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to add photos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF697A71),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Consultation Type
              const Text(
                'Consultation Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 12),

              _buildConsultationType(
                value: 'online',
                title: 'Online Consultation',
                subtitle: 'Instant audio or video session',
                icon: Icons.videocam_outlined,
              ),
              const SizedBox(height: 12),
              _buildConsultationType(
                value: 'onsite',
                title: 'On-site Farm Visit',
                subtitle: 'Doctor visits your location',
                icon: Icons.home_outlined,
              ),

              const SizedBox(height: 32),

              // Submit Request
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsultationType({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _consultationType == value;

    return GestureDetector(
      onTap: () => setState(() => _consultationType = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FBF5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryGreen : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryGreen : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryGreen,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              size: 22,
              color: isSelected ? primaryGreen : const Color(0xFF697A71),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3027),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF697A71),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
