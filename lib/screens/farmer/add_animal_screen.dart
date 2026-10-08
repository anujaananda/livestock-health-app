import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({super.key});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _animalIdController =
      TextEditingController();
  final TextEditingController _nameController =
      TextEditingController();
  final TextEditingController _breedController =
      TextEditingController();
  final TextEditingController _ageController =
      TextEditingController();
  final TextEditingController _dobController =
      TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedSpecies;
  String? _selectedGender;
  String? _selectedHealthStatus;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  bool _isLoading = false;

  final List<String> _species = [
    'Cattle',
    'Goat',
    'Sheep',
    'Buffalo',
    'Pig',
    'Other',
  ];

  final List<String> _genders = [
    'Male',
    'Female',
  ];

  final List<String> _healthStatuses = [
    'Healthy',
    'Need Attention',
    'Under Treatment',
  ];

  @override
  void dispose() {
    _animalIdController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    final day =
        pickedDate.day.toString().padLeft(2, '0');
    final month =
        pickedDate.month.toString().padLeft(2, '0');
    final year = pickedDate.year.toString();

    if (!mounted) return;

    setState(() {
      _dobController.text = '$day/$month/$year';
    });
  }

  // ============================================================
  // PICK ANIMAL PHOTO
  // ============================================================

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not select the photo. Please try again.',
        isError: true,
      );
    }
  }

  // ============================================================
  // UPLOAD PHOTO TO SUPABASE STORAGE
  // ============================================================

  Future<String?> _uploadAnimalPhoto(
    String userId,
  ) async {
    // Photo is optional
    if (_selectedImage == null ||
        _selectedImageBytes == null) {
      return null;
    }

    final originalName = _selectedImage!.name;

    String extension = 'jpg';

    if (originalName.contains('.')) {
      extension =
          originalName.split('.').last.toLowerCase();
    }

    if (![
      'jpg',
      'jpeg',
      'png',
      'webp',
    ].contains(extension)) {
      extension = 'jpg';
    }

    final animalTag = _animalIdController.text
        .trim()
        .replaceAll(
          RegExp(r'[^a-zA-Z0-9_-]'),
          '_',
        );

    final timestamp =
        DateTime.now().millisecondsSinceEpoch;

    final filePath =
        '$userId/${animalTag}_$timestamp.$extension';

    await Supabase.instance.client.storage
        .from('animal-photos')
        .uploadBinary(
          filePath,
          _selectedImageBytes!,
          fileOptions: const FileOptions(
            upsert: false,
          ),
        );

    return Supabase.instance.client.storage
        .from('animal-photos')
        .getPublicUrl(filePath);
  }

  // ============================================================
  // ADD ANIMAL
  // ============================================================

  Future<void> _addAnimal() async {
    if (_isLoading) return;

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSpecies == null) {
      _showMessage(
        'Please select a species.',
        isError: true,
      );
      return;
    }

    if (_selectedGender == null) {
      _showMessage(
        'Please select a gender.',
        isError: true,
      );
      return;
    }

    if (_selectedHealthStatus == null) {
      _showMessage(
        'Please select a health status.',
        isError: true,
      );
      return;
    }

    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please login before adding an animal.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ========================================================
      // CONVERT DATE
      // ========================================================

      String? dateOfBirth;

      final dobText = _dobController.text.trim();

      if (dobText.isNotEmpty) {
        final parts = dobText.split('/');

        if (parts.length == 3) {
          dateOfBirth =
              '${parts[2]}-${parts[1]}-${parts[0]}';
        }
      }

      // ========================================================
      // UPLOAD PHOTO
      // ========================================================

      String? imageUrl;

      if (_selectedImage != null &&
          _selectedImageBytes != null) {
        imageUrl =
            await _uploadAnimalPhoto(user.id);
      }

      // ========================================================
      // SAVE ANIMAL TO SUPABASE
      // ========================================================

      await Supabase.instance.client
          .from('animals')
          .insert({
        'owner_id': user.id,
        'animal_id_tag':
            _animalIdController.text.trim(),
        'name': _nameController.text.trim(),
        'species': _selectedSpecies,
        'breed': _breedController.text.trim(),
        'age':
            int.parse(_ageController.text.trim()),
        'gender': _selectedGender,
        'date_of_birth': dateOfBirth,
        'image_url': imageUrl,
        'health_status': _selectedHealthStatus,
      });

      if (!mounted) return;

      // ========================================================
      // SUCCESS
      // ========================================================

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Animal added successfully!',
          ),
          backgroundColor: Color(0xFF176B43),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // ========================================================
      // GO BACK TO MY ANIMALS
      // ========================================================

      Navigator.pop(context, true);
    } on StorageException catch (e) {
      if (!mounted) return;

      _showMessage(
        'Photo upload failed: ${e.message}',
        isError: true,
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to add animal: ${e.message}',
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Something went wrong. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? const Color(0xFFE15B5B)
            : const Color(0xFF176B43),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFA),

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                14,
                20,
                10,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Color(0xFF234C37),
                    ),
                  ),

                  const SizedBox(width: 5),

                  const Text(
                    'Add Animal',
                    style: TextStyle(
                      color: Color(0xFF176B43),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // FORM
            // ==================================================

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  8,
                  24,
                  30,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // ========================================
                      // PHOTO
                      // ========================================

                      Center(
                        child: InkWell(
                          onTap:
                              _isLoading ? null : _pickImage,
                          borderRadius:
                              BorderRadius.circular(18),
                          child: Container(
                            width: 135,
                            height: 120,
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFF2FBF5),
                              borderRadius:
                                  BorderRadius.circular(18),
                              border: Border.all(
                                color:
                                    const Color(0xFF72CC98),
                                width: 1.2,
                              ),
                            ),
                            child: _selectedImageBytes != null
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(
                                            17),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.memory(
                                          _selectedImageBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          right: 6,
                                          bottom: 6,
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            decoration:
                                                const BoxDecoration(
                                              color:
                                                  Color(0xFF176B43),
                                              shape:
                                                  BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: DecoratedBox(
                                          decoration:
                                              BoxDecoration(
                                            color:
                                                Color(0xFFE1F7E9),
                                            shape:
                                                BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons
                                                .add_a_photo_outlined,
                                            color:
                                                Color(0xFF20B769),
                                            size: 23,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 9),
                                      Text(
                                        'Upload Animal Photo',
                                        style: TextStyle(
                                          color:
                                              Color(0xFF52635A),
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Optional',
                                        style: TextStyle(
                                          color:
                                              Color(0xFF95A29B),
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      if (_selectedImageBytes != null) ...[
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Tap photo to change',
                            style: TextStyle(
                              color: Color(0xFF7B8A82),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 25),

                      // ========================================
                      // ANIMAL ID
                      // ========================================

                      _buildLabel(
                        'Animal ID',
                        requiredField: true,
                      ),

                      const SizedBox(height: 7),

                      _buildTextField(
                        controller: _animalIdController,
                        hint: 'e.g. C001',
                        icon: Icons.sell_outlined,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Animal ID is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // ========================================
                      // NAME
                      // ========================================

                      _buildLabel(
                        'Name',
                        requiredField: true,
                      ),

                      const SizedBox(height: 7),

                      _buildTextField(
                        controller: _nameController,
                        hint: 'e.g. Daisy',
                        icon: Icons.pets_outlined,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Animal name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // ========================================
                      // SPECIES
                      // ========================================

                      _buildLabel(
                        'Species',
                        requiredField: true,
                      ),

                      const SizedBox(height: 7),

                      DropdownButtonFormField<String>(
                        value: _selectedSpecies,
                        decoration: _inputDecoration(
                          hint: 'Select Species',
                          icon: Icons.pets_rounded,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF63736A),
                        ),
                        items: _species.map((species) {
                          return DropdownMenuItem<String>(
                            value: species,
                            child: Text(species),
                          );
                        }).toList(),
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedSpecies = value;
                                });
                              },
                        validator: (value) {
                          if (value == null) {
                            return 'Species is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // ========================================
                      // BREED
                      // ========================================

                      _buildLabel(
                        'Breed',
                        requiredField: true,
                      ),

                      const SizedBox(height: 7),

                      _buildTextField(
                        controller: _breedController,
                        hint: 'e.g. Jersey / Boer',
                        icon:
                            Icons.workspace_premium_outlined,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Breed is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // ========================================
                      // AGE
                      // ========================================

                      _buildLabel(
                        'Age (Years)',
                        requiredField: true,
                      ),

                      const SizedBox(height: 7),

                      _buildTextField(
                        controller: _ageController,
                        hint: 'e.g. 3',
                        icon:
                            Icons.calendar_month_outlined,
                        keyboardType:
                            TextInputType.number,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Age is required';
                          }

                          final age =
                              int.tryParse(value.trim());

                          if (age == null || age < 0) {
                            return 'Enter a valid age';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // ========================================
                      // GENDER
                      // ========================================

                      _buildLabel(
                        'Gender',
                        requiredField: true,
                      ),

                      const SizedBox(height: 7),

                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: _inputDecoration(
                          hint: 'Select Gender',
                          icon: Icons.transgender_rounded,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF63736A),
                        ),
                        items: _genders.map((gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              },
                        validator: (value) {
                          if (value == null) {
                            return 'Gender is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // ========================================
                      // HEALTH STATUS
                      // ========================================

                      _buildLabel(
                        'Health Status',
                        requiredField: true,
                      ),

                      const SizedBox(height: 7),

                      DropdownButtonFormField<String>(
                        value: _selectedHealthStatus,
                        decoration: _inputDecoration(
                          hint: 'Select Health Status',
                          icon: Icons
                              .health_and_safety_outlined,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF63736A),
                        ),
                        items:
                            _healthStatuses.map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedHealthStatus =
                                      value;
                                });
                              },
                        validator: (value) {
                          if (value == null) {
                            return 'Health status is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // ========================================
                      // DATE OF BIRTH
                      // ========================================

                      _buildLabel(
                        'Date of Birth',
                        requiredField: false,
                      ),

                      const SizedBox(height: 7),

                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        onTap:
                            _isLoading ? null : _selectDate,
                        decoration: _inputDecoration(
                          hint: 'dd/mm/yyyy',
                          icon: Icons
                              .calendar_today_outlined,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ========================================
                      // ADD BUTTON
                      // ========================================

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : _addAnimal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF24B86A),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFF9EDDBB),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Adding Animal...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      size: 20,
                                    ),
                                    SizedBox(width: 7),
                                    Text(
                                      'Add Animal',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(
    String text, {
    required bool requiredField,
  }) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF285F42),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (requiredField)
          const Text(
            ' *',
            style: TextStyle(
              color: Color(0xFF159957),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      enabled: !_isLoading,
      decoration: _inputDecoration(
        hint: hint,
        icon: icon,
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9AA69F),
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF53645B),
        size: 20,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD8E1DC),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF24B86A),
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE15B5B),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE15B5B),
          width: 1.4,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFD8E1DC),
        ),
      ),
    );
  }
}