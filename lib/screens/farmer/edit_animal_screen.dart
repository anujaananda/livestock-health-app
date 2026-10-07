import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditAnimalScreen extends StatefulWidget {
  final Map<String, dynamic> animal;

  const EditAnimalScreen({
    super.key,
    required this.animal,
  });

  @override
  State<EditAnimalScreen> createState() =>
      _EditAnimalScreenState();
}

class _EditAnimalScreenState extends State<EditAnimalScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _animalIdController;
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _ageController;
  late final TextEditingController _dobController;

  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedSpecies;
  String? _selectedGender;
  String? _selectedHealthStatus;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  String _currentImageUrl = '';

  bool _isSaving = false;

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
  void initState() {
    super.initState();

    _animalIdController = TextEditingController(
      text: widget.animal['animal_id_tag']?.toString() ?? '',
    );

    _nameController = TextEditingController(
      text: widget.animal['name']?.toString() ?? '',
    );

    _breedController = TextEditingController(
      text: widget.animal['breed']?.toString() ?? '',
    );

    _ageController = TextEditingController(
      text: widget.animal['age']?.toString() ?? '',
    );

    _dobController = TextEditingController(
      text: _formatDateForForm(
        widget.animal['date_of_birth']?.toString(),
      ),
    );

    _selectedSpecies =
        widget.animal['species']?.toString();

    _selectedGender =
        widget.animal['gender']?.toString();

    _selectedHealthStatus =
        widget.animal['health_status']?.toString();

    _currentImageUrl =
        widget.animal['image_url']?.toString() ?? '';
  }

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
  // PICK NEW PHOTO
  // ============================================================

  Future<void> _pickImage() async {
    if (_isSaving) return;

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
  // UPLOAD NEW PHOTO
  // ============================================================

  Future<String?> _uploadNewPhoto(String userId) async {
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
        '$userId/${animalTag}_edit_$timestamp.$extension';

    await Supabase.instance.client.storage
        .from('animal-photos')
        .uploadBinary(
          filePath,
          _selectedImageBytes!,
          fileOptions: const FileOptions(
            upsert: false,
          ),
        );

    final publicUrl = Supabase.instance.client.storage
        .from('animal-photos')
        .getPublicUrl(filePath);

    return publicUrl;
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate() async {
    DateTime initialDate = DateTime.now();

    final existingDate =
        widget.animal['date_of_birth']?.toString();

    if (existingDate != null &&
        existingDate.isNotEmpty) {
      initialDate =
          DateTime.tryParse(existingDate) ??
              DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    final day =
        picked.day.toString().padLeft(2, '0');

    final month =
        picked.month.toString().padLeft(2, '0');

    if (!mounted) return;

    setState(() {
      _dobController.text =
          '$day/$month/${picked.year}';
    });
  }

  // ============================================================
  // SAVE CHANGES
  // ============================================================

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSpecies == null ||
        _selectedGender == null ||
        _selectedHealthStatus == null) {
      _showMessage(
        'Please complete all required fields.',
        isError: true,
      );
      return;
    }

    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please login again.',
        isError: true,
      );
      return;
    }

    final animalDatabaseId = widget.animal['id'];

    if (animalDatabaseId == null) {
      _showMessage(
        'Animal ID not found.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // --------------------------------------------------------
      // DATE
      // --------------------------------------------------------

      String? dateOfBirth;

      final dob = _dobController.text.trim();

      if (dob.isNotEmpty) {
        final parts = dob.split('/');

        if (parts.length == 3) {
          dateOfBirth =
              '${parts[2]}-${parts[1]}-${parts[0]}';
        }
      }

      // --------------------------------------------------------
      // PHOTO
      // --------------------------------------------------------

      String imageUrl = _currentImageUrl;

      // Only upload when user selected a NEW photo
      if (_selectedImage != null &&
          _selectedImageBytes != null) {
        final newImageUrl =
            await _uploadNewPhoto(user.id);

        if (newImageUrl != null) {
          imageUrl = newImageUrl;
        }
      }

      // --------------------------------------------------------
      // UPDATE DATA
      // --------------------------------------------------------

      final updatedData = <String, dynamic>{
        'animal_id_tag':
            _animalIdController.text.trim(),

        'name':
            _nameController.text.trim(),

        'species':
            _selectedSpecies,

        'breed':
            _breedController.text.trim(),

        'age':
            int.parse(
              _ageController.text.trim(),
            ),

        'gender':
            _selectedGender,

        'date_of_birth':
            dateOfBirth,

        'health_status':
            _selectedHealthStatus,

        'image_url':
            imageUrl.isEmpty ? null : imageUrl,
      };

      final response = await Supabase.instance.client
          .from('animals')
          .update(updatedData)
          .eq(
            'id',
            animalDatabaseId,
          )
          .eq(
            'owner_id',
            user.id,
          )
          .select()
          .single();

      if (!mounted) return;

      _showMessage(
        'Animal updated successfully!',
      );

      // Return updated animal to profile
      Navigator.pop(
        context,
        Map<String, dynamic>.from(response),
      );
    } on StorageException catch (e) {
      if (!mounted) return;

      _showMessage(
        'Photo upload failed: ${e.message}',
        isError: true,
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      _showMessage(
        'Update failed: ${e.message}',
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not update animal. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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
      backgroundColor: const Color(0xFFF8FBF9),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FBF9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        title: const Text(
          'Edit Animal',
          style: TextStyle(
            color: Color(0xFF176B43),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          10,
          24,
          30,
        ),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ==================================================
              // ANIMAL PHOTO
              // ==================================================

              Center(
                child: InkWell(
                  onTap:
                      _isSaving ? null : _pickImage,

                  borderRadius:
                      BorderRadius.circular(70),

                  child: Stack(
                    children: [
                      Container(
                        width: 130,
                        height: 130,

                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFEAF7EF),

                          shape: BoxShape.circle,

                          border: Border.all(
                            color:
                                const Color(0xFFB9E4C9),
                            width: 3,
                          ),
                        ),

                        child: ClipOval(
                          child: _buildAnimalPhoto(),
                        ),
                      ),

                      Positioned(
                        right: 3,
                        bottom: 3,

                        child: Container(
                          width: 38,
                          height: 38,

                          decoration:
                              const BoxDecoration(
                            color:
                                Color(0xFF24B86A),
                            shape: BoxShape.circle,
                          ),

                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Center(
                child: Text(
                  'Tap photo to change',
                  style: TextStyle(
                    color: Color(0xFF7B8A82),
                    fontSize: 11,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // ANIMAL ID
              // ==================================================

              _label('Animal ID'),

              _textField(
                controller:
                    _animalIdController,
                hint: 'Animal ID',
                icon: Icons.sell_outlined,
              ),

              // ==================================================
              // NAME
              // ==================================================

              _label('Name'),

              _textField(
                controller: _nameController,
                hint: 'Animal Name',
                icon: Icons.pets_outlined,
              ),

              // ==================================================
              // SPECIES
              // ==================================================

              _label('Species'),

              DropdownButtonFormField<String>(
                value: _selectedSpecies,

                decoration: _decoration(
                  'Select Species',
                  Icons.pets,
                ),

                items: _species.map((value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),

                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _selectedSpecies =
                              value;
                        });
                      },

                validator: (value) {
                  if (value == null) {
                    return 'Species is required';
                  }

                  return null;
                },
              ),

              // ==================================================
              // BREED
              // ==================================================

              _label('Breed'),

              _textField(
                controller: _breedController,
                hint: 'Breed',
                icon:
                    Icons.workspace_premium_outlined,
              ),

              // ==================================================
              // AGE
              // ==================================================

              _label('Age'),

              _textField(
                controller: _ageController,
                hint: 'Age',
                icon:
                    Icons.calendar_month_outlined,
                number: true,
              ),

              // ==================================================
              // GENDER
              // ==================================================

              _label('Gender'),

              DropdownButtonFormField<String>(
                value: _selectedGender,

                decoration: _decoration(
                  'Select Gender',
                  Icons.transgender,
                ),

                items: _genders.map((value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),

                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _selectedGender =
                              value;
                        });
                      },

                validator: (value) {
                  if (value == null) {
                    return 'Gender is required';
                  }

                  return null;
                },
              ),

              // ==================================================
              // HEALTH STATUS
              // ==================================================

              _label('Health Status'),

              DropdownButtonFormField<String>(
                value:
                    _selectedHealthStatus,

                decoration: _decoration(
                  'Select Health Status',
                  Icons
                      .health_and_safety_outlined,
                ),

                items:
                    _healthStatuses.map((value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),

                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _selectedHealthStatus =
                              value;
                        });
                      },

                validator: (value) {
                  if (value == null) {
                    return 'Health Status is required';
                  }

                  return null;
                },
              ),

              // ==================================================
              // DATE OF BIRTH
              // ==================================================

              _label('Date of Birth'),

              TextFormField(
                controller: _dobController,
                readOnly: true,
                enabled: !_isSaving,

                onTap: _selectDate,

                decoration: _decoration(
                  'dd/mm/yyyy',
                  Icons.cake_outlined,
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // SAVE BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 54,

                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : _saveChanges,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF24B86A),

                    foregroundColor:
                        Colors.white,

                    disabledBackgroundColor:
                        const Color(0xFF9EDDBB),

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              14),
                    ),
                  ),

                  child: _isSaving
                      ? const Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,

                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth: 2,
                              ),
                            ),

                            SizedBox(width: 10),

                            Text(
                              'Saving...',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children: [
                            Icon(
                              Icons
                                  .save_outlined,
                              size: 20,
                            ),

                            SizedBox(width: 8),

                            Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPLAY PHOTO
  // ============================================================

  Widget _buildAnimalPhoto() {
    // User selected a NEW photo
    if (_selectedImageBytes != null) {
      return Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
      );
    }

    // Existing photo from Supabase
    if (_currentImageUrl.isNotEmpty) {
      return Image.network(
        _currentImageUrl,
        fit: BoxFit.cover,

        loadingBuilder: (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress == null) {
            return child;
          }

          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF24B86A),
              strokeWidth: 2,
            ),
          );
        },

        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return const Icon(
            Icons.pets_rounded,
            size: 52,
            color: Color(0xFF24B86A),
          );
        },
      );
    }

    // No photo
    return const Icon(
      Icons.pets_rounded,
      size: 52,
      color: Color(0xFF24B86A),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 18,
        bottom: 7,
      ),

      child: Text(
        '$text *',

        style: const TextStyle(
          color: Color(0xFF285F42),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool number = false,
  }) {
    return TextFormField(
      controller: controller,

      enabled: !_isSaving,

      keyboardType: number
          ? TextInputType.number
          : TextInputType.text,

      decoration:
          _decoration(hint, icon),

      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return '$hint is required';
        }

        if (number) {
          final age =
              int.tryParse(value.trim());

          if (age == null || age < 0) {
            return 'Enter a valid age';
          }
        }

        return null;
      },
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _decoration(
    String hint,
    IconData icon,
  ) {
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

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),

        borderSide: const BorderSide(
          color: Color(0xFFD8E1DC),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),

        borderSide: const BorderSide(
          color: Color(0xFF24B86A),
          width: 1.4,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),

        borderSide: const BorderSide(
          color: Color(0xFFE15B5B),
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),

        borderSide: const BorderSide(
          color: Color(0xFFE15B5B),
          width: 1.4,
        ),
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDateForForm(
    String? date,
  ) {
    if (date == null || date.isEmpty) {
      return '';
    }

    try {
      final parsed =
          DateTime.parse(date);

      final day =
          parsed.day.toString().padLeft(
                2,
                '0',
              );

      final month =
          parsed.month.toString().padLeft(
                2,
                '0',
              );

      return '$day/$month/${parsed.year}';
    } catch (_) {
      return '';
    }
  }
}