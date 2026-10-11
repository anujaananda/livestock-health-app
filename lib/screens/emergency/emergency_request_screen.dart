import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/animal_model.dart';
import '../../services/animal_service.dart';
import '../../services/auth_service.dart';
import '../../services/emergency_service.dart';

class EmergencyRequestScreen extends StatefulWidget {
  const EmergencyRequestScreen({super.key});

  @override
  State<EmergencyRequestScreen> createState() => _EmergencyRequestScreenState();
}

class _EmergencyRequestScreenState extends State<EmergencyRequestScreen> {
  static const Color primaryGreen = Color(0xFF20B769);
  static const Color emergencyRed = Color(0xFFD32F2F);

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final AnimalService _animalService = AnimalService();
  final EmergencyService _emergencyService = EmergencyService();

  List<AnimalModel> _animals = [];
  AnimalModel? _selectedAnimal;
  bool _isLoadingAnimals = true;

  String _urgency = 'High';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final farmerId = authService.currentUser!.id;

    final animals = await _animalService.getFarmerAnimals(farmerId);

    if (!mounted) return;

    setState(() {
      _animals = animals;
      if (animals.isNotEmpty) {
        _selectedAnimal = animals.first;
      }
      _isLoadingAnimals = false;
    });
  }

  // ================= SUBMIT =================
  Future<void> _submitEmergency() async {
    if (_selectedAnimal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an animal'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    // ✅ Broadcast to ALL vets
    final success = await _emergencyService.broadcastAlert(
      farmerId: authService.currentUser!.id,
      animalName: _selectedAnimal!.displayName,
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      urgency: _urgency,
      farmerName: authService.currentUser?.email ?? 'Farmer',
      condition: _selectedAnimal!.species,
      animalId: _selectedAnimal!.id,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5F7EA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: primaryGreen,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Emergency Alert Sent!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'All available vets have been notified. The first vet to respond will handle your case.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF697A71)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send emergency alert'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF9),
      appBar: AppBar(
        backgroundColor: emergencyRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Emergency Request',
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
              // Warning banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFC7C7)),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: emergencyRed,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This will alert ALL available vets. The first to respond will handle your case.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB71C1C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SELECT ANIMAL
              const Text(
                'Select Animal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 8),

              if (_isLoadingAnimals)
                _buildLoadingBox()
              else if (_animals.isEmpty)
                _buildNoAnimalsCard()
              else
                _buildAnimalDropdown(),

              const SizedBox(height: 20),

              // URGENCY
              const Text(
                'Urgency Level',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildUrgencyChip(
                      value: 'Medium',
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildUrgencyChip(
                      value: 'High',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildUrgencyChip(
                      value: 'Critical',
                      color: emergencyRed,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // DESCRIPTION
              const Text(
                'Describe the Emergency',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe the emergency situation, symptoms, etc.',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: emergencyRed,
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Please describe the emergency' : null,
              ),

              const SizedBox(height: 20),

              // LOCATION
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Enter farm location',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF697A71),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: emergencyRed,
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Please enter location' : null,
              ),

              const SizedBox(height: 32),

              // SUBMIT
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitEmergency,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.emergency_rounded,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isLoading ? 'Sending...' : 'Send Emergency Alert',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emergencyRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  // ================= ANIMAL DROPDOWN =================
  Widget _buildAnimalDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AnimalModel>(
          value: _selectedAnimal,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _animals.map((animal) {
            return DropdownMenuItem<AnimalModel>(
              value: animal,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFFE5F7EA),
                    child: Icon(Icons.pets, size: 16, color: primaryGreen),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      animal.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedAnimal = value),
        ),
      ),
    );
  }

  Widget _buildUrgencyChip({required String value, required Color color}) {
    final isSelected = _urgency == value;
    return GestureDetector(
      onTap: () => setState(() => _urgency = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : const Color(0xFF697A71),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBox() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildNoAnimalsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No animals found. Please add an animal first.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}
