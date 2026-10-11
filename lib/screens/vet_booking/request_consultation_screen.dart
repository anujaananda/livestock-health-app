// lib/screens/vet_booking/request_consultation_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/animal_model.dart';
import '../../models/vet_model.dart';
import '../../services/animal_service.dart';
import '../../services/auth_service.dart';
import '../../services/consultation_service.dart';
import 'my_appointments_screen.dart';

class RequestConsultationScreen extends StatefulWidget {
  final VetModel? vet;
  final AnimalModel? selectedAnimal; // ✅ Book Appointment එකෙන් pass වෙනවා

  const RequestConsultationScreen({super.key, this.vet, this.selectedAnimal});

  @override
  State<RequestConsultationScreen> createState() =>
      _RequestConsultationScreenState();
}

class _RequestConsultationScreenState extends State<RequestConsultationScreen> {
  static const Color primaryGreen = Color(0xFF20B769);

  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  final AnimalService _animalService = AnimalService();

  AnimalModel? _selectedAnimal;
  bool _isLoadingAnimals = true;

  String _consultationType = 'online';
  bool _isLoading = false;

  final List<File> _selectedPhotos = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // ✅ Book Appointment එකෙන් pass කරපු animal එක use කරන්න
    if (widget.selectedAnimal != null) {
      _selectedAnimal = widget.selectedAnimal;
      _isLoadingAnimals = false;
    } else {
      // ⚠️ Fallback — animal pass නොකළොත් DB එකෙන් load
      _loadAnimals();
    }
  }

  // ================= LOAD FARMER'S ANIMALS (Fallback) =================
  Future<void> _loadAnimals() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final farmerId = authService.currentUser!.id;

    final animals = await _animalService.getFarmerAnimals(farmerId);

    if (!mounted) return;

    setState(() {
      if (animals.isNotEmpty) {
        _selectedAnimal = animals.first;
      }
      _isLoadingAnimals = false;
    });
  }

  // ================= PICK IMAGES =================
  Future<void> _pickImages() async {
    try {
      if (_selectedPhotos.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 5 photos allowed'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3027),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F7EA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: primaryGreen,
                      size: 20,
                    ),
                  ),
                  title: const Text('Take a Photo'),
                  subtitle: const Text('Use camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromSource(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F7EA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: primaryGreen,
                      size: 20,
                    ),
                  ),
                  title: const Text('Choose from Gallery'),
                  subtitle: const Text('Pick from photos'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromSource(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('❌ Error in _pickImages: $e');
    }
  }

  Future<void> _pickFromSource(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1080,
      );

      if (picked != null) {
        setState(() {
          _selectedPhotos.add(File(picked.path));
        });
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() => _selectedPhotos.removeAt(index));
  }

  // ================= SUBMIT =================
  Future<void> _submitRequest() async {
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
    final consultationService = ConsultationService();

    final vetId = widget.vet?.effectiveUserId;

    debugPrint('📝 Submit Request:');
    debugPrint('   vet: ${widget.vet?.name}');
    debugPrint('   vetId: "$vetId"');
    debugPrint('   photos: ${_selectedPhotos.length}');

    final success = await consultationService.createConsultation(
      farmerId: authService.currentUser!.id,
      vetId: (vetId != null && vetId.isNotEmpty) ? vetId : null,
      symptoms: _symptomsController.text.trim(),
      urgency: _consultationType == 'online' ? 'Normal' : 'Urgent',
      consultationType: _consultationType,
      animalName: _selectedAnimal!.displayName,
      animalId: _selectedAnimal!.id,
      photos: _selectedPhotos,
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
        MaterialPageRoute(builder: (_) => MyAppointmentsScreen()),
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

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
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
              // VET CARD
              if (widget.vet != null) ...[
                _buildVetCard(),
                const SizedBox(height: 20),
              ],

              // ✅ SELECTED ANIMAL — Dropdown අයින් කළා
              const Text(
                'Animal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
              const SizedBox(height: 8),

              if (_isLoadingAnimals)
                _buildAnimalLoading()
              else if (_selectedAnimal == null)
                _buildNoAnimalsCard()
              else
                _buildSelectedAnimalPreview(_selectedAnimal!),

              const SizedBox(height: 20),

              // DESCRIBE PROBLEM
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
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please describe the problem'
                    : null,
              ),

              const SizedBox(height: 20),

              // ADD PHOTOS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Photos (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3027),
                    ),
                  ),
                  if (_selectedPhotos.isNotEmpty)
                    Text(
                      '${_selectedPhotos.length}/5',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF697A71),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (_selectedPhotos.isNotEmpty) ...[
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedPhotos.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _selectedPhotos.length) {
                        return _buildAddPhotoButton();
                      }
                      return _buildPhotoThumbnail(index);
                    },
                  ),
                ),
              ] else ...[
                GestureDetector(
                  onTap: _pickImages,
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
              ],

              const SizedBox(height: 20),

              // CONSULTATION TYPE
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

              // SUBMIT
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

  // ================= VET CARD =================
  Widget _buildVetCard() {
    final vet = widget.vet!;

    final String imageUrl =
        (vet.profileImageUrl != null && vet.profileImageUrl!.isNotEmpty)
        ? vet.profileImageUrl!
        : 'https://i.pravatar.cc/150?img=12';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FBF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5F7EA), width: 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFE5F7EA),
            backgroundImage: NetworkImage(imageUrl),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consultation with:',
                  style: TextStyle(fontSize: 10, color: Color(0xFF697A71)),
                ),
                const SizedBox(height: 2),
                Text(
                  vet.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3027),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  vet.specialization,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF697A71),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.verified, color: primaryGreen, size: 20),
        ],
      ),
    );
  }

  // ================= ANIMAL AVATAR =================
  Widget _buildAnimalAvatar(AnimalModel animal, {double radius = 14}) {
    final hasImage = animal.imageUrl != null && animal.imageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE5F7EA),
      backgroundImage: hasImage ? NetworkImage(animal.imageUrl!) : null,
      onBackgroundImageError: hasImage ? (_, __) {} : null,
      child: hasImage
          ? null
          : Icon(Icons.pets, size: radius * 1.1, color: primaryGreen),
    );
  }

  // ================= ✅ SELECTED ANIMAL PREVIEW =================
  Widget _buildSelectedAnimalPreview(AnimalModel animal) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FBF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
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
          const Icon(Icons.check_circle, color: primaryGreen, size: 24),
        ],
      ),
    );
  }

  // ================= ANIMAL LOADING =================
  Widget _buildAnimalLoading() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
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

  // ================= NO ANIMALS CARD =================
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
              'No animal selected. Please go back and book an appointment.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ADD PHOTO BUTTON =================
  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 90,
        height: 90,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: primaryGreen, size: 24),
            SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(fontSize: 11, color: Color(0xFF697A71)),
            ),
          ],
        ),
      ),
    );
  }

  // ================= PHOTO THUMBNAIL =================
  Widget _buildPhotoThumbnail(int index) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5F0E9)),
            image: DecorationImage(
              image: FileImage(_selectedPhotos[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 14,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // ================= CONSULTATION TYPE CARD =================
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
