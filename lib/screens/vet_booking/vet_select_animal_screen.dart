// lib/screens/vet_booking/vet_select_animal_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/animal_model.dart';
import 'vet_add_medical_record_screen.dart';

class VetSelectAnimalScreen extends StatefulWidget {
  const VetSelectAnimalScreen({super.key});

  @override
  State<VetSelectAnimalScreen> createState() => _VetSelectAnimalScreenState();
}

class _VetSelectAnimalScreenState extends State<VetSelectAnimalScreen> {
  static const Color primaryGreen = Color(0xFF20B769);

  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _farmers = [];
  List<AnimalModel> _animals = [];

  Map<String, dynamic>? _selectedFarmer;
  AnimalModel? _selectedAnimal;

  bool _isLoadingFarmers = true;
  bool _isLoadingAnimals = false;

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  Future<void> _loadFarmers() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('id, full_name, email')
          .eq('user_type', 'Farmer / Livestock Owner')
          .order('full_name');

      if (!mounted) return;
      setState(() {
        _farmers = (data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _isLoadingFarmers = false;
      });
    } catch (e) {
      print('❌ Load farmers error: $e');
      if (!mounted) return;
      setState(() => _isLoadingFarmers = false);
    }
  }

  Future<void> _loadAnimalsForFarmer(String farmerId) async {
    setState(() {
      _isLoadingAnimals = true;
      _animals = [];
      _selectedAnimal = null;
    });

    try {
      final data = await _supabase
          .from('animals')
          .select()
          .eq('owner_id', farmerId)
          .order('name');

      if (!mounted) return;
      setState(() {
        _animals = (data as List)
            .map(
              (e) => AnimalModel.fromMap(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        _isLoadingAnimals = false;
      });
    } catch (e) {
      print('❌ Load animals error: $e');
      if (!mounted) return;
      setState(() => _isLoadingAnimals = false);
    }
  }

  void _onFarmerChanged(Map<String, dynamic>? farmer) {
    if (farmer == null) return;
    setState(() {
      _selectedFarmer = farmer;
      _selectedAnimal = null;
    });
    _loadAnimalsForFarmer(farmer['id']);
  }

  Future<void> _proceed() async {
    if (_selectedFarmer == null || _selectedAnimal == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VetAddMedicalRecordScreen(
          animalId: _selectedAnimal!.id,
          animalName: _selectedAnimal!.displayName,
          ownerId: _selectedFarmer!['id'],
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Record added successfully!'),
          backgroundColor: primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF9),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Medical Record',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoadingFarmers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= INFO BANNER =================
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: primaryGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Select a farmer, then choose an animal to add a medical record.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E3027),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ================= SELECT FARMER =================
                  const Text(
                    'Select Farmer',
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
                      child: DropdownButton<Map<String, dynamic>>(
                        value: _selectedFarmer,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        hint: const Text('Choose a farmer'),
                        items: _farmers.map((farmer) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: farmer,
                            child: Row(
                              children: [
                                // ✅ Farmer avatar
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: primaryGreen,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    farmer['full_name']?.toString() ??
                                        'Unknown',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _onFarmerChanged,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ================= SELECT ANIMAL =================
                  if (_selectedFarmer != null) ...[
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
                      Container(
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
                      )
                    else if (_animals.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFFF59E0B),
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'This farmer has no animals registered.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
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
                            hint: const Text('Choose an animal'),
                            items: _animals.map((animal) {
                              return DropdownMenuItem<AnimalModel>(
                                value: animal,
                                child: Row(
                                  children: [
                                    // ✅ Animal profile photo in dropdown
                                    _buildAnimalAvatar(animal, radius: 16),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            animal.displayName,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1E3027),
                                            ),
                                          ),
                                          if (animal.breed != null &&
                                              animal.breed!.isNotEmpty)
                                            Text(
                                              animal.breed!,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF697A71),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _selectedAnimal = v),
                          ),
                        ),
                      ),

                    // ✅ Selected Animal Preview (with photo)
                    if (_selectedAnimal != null) ...[
                      const SizedBox(height: 16),
                      _buildSelectedAnimalPreview(_selectedAnimal!),
                    ],
                  ],

                  const SizedBox(height: 32),

                  // ================= PROCEED BUTTON =================
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed:
                          (_selectedFarmer != null && _selectedAnimal != null)
                          ? _proceed
                          : null,
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        disabledBackgroundColor: const Color(0xFFD1D5DB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ================= ✅ ANIMAL AVATAR WITH PHOTO =================
  Widget _buildAnimalAvatar(AnimalModel animal, {double radius = 18}) {
    final hasImage = animal.imageUrl != null && animal.imageUrl!.isNotEmpty;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryGreen.withValues(alpha: 0.12),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                animal.imageUrl!,
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: radius * 0.6,
                      height: radius * 0.6,
                      child: const CircularProgressIndicator(
                        color: primaryGreen,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.pets, color: primaryGreen, size: radius * 0.9),
              )
            : Icon(Icons.pets, color: primaryGreen, size: radius * 0.9),
      ),
    );
  }

  // ================= ✅ SELECTED ANIMAL PREVIEW =================
  Widget _buildSelectedAnimalPreview(AnimalModel animal) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // ✅ Larger animal photo
          _buildAnimalAvatar(animal, radius: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animal.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3027),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  animal.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF697A71),
                  ),
                ),
                if (animal.breed != null && animal.breed!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Breed: ${animal.breed}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF697A71),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: primaryGreen, size: 22),
        ],
      ),
    );
  }
}
