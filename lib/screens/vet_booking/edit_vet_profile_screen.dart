// lib/screens/vet_booking/edit_vet_profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/vet_model.dart';
import '../../services/auth_service.dart';

class EditVetProfileScreen extends StatefulWidget {
  final VetModel? vet;

  const EditVetProfileScreen({super.key, this.vet});

  @override
  State<EditVetProfileScreen> createState() => _EditVetProfileScreenState();
}

class _EditVetProfileScreenState extends State<EditVetProfileScreen> {
  static const Color primaryGreen = Color(0xFF24B86A);
  static const Color darkText = Color(0xFF1E3027);
  static const Color mutedText = Color(0xFF697A71);
  static const Color inputBg = Color(0xFFF9FAFB);
  static const Color disabledBg = Color(0xFFF3F4F6);

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  String? _profileImageUrl;
  File? _newImageFile;

  @override
  void initState() {
    super.initState();

    if (widget.vet != null) {
      _nameController.text = widget.vet!.name;
      _specializationController.text = widget.vet!.specialization;
      _locationController.text = widget.vet!.location;
      _phoneController.text = widget.vet!.phone;
      _emailController.text = widget.vet!.email;
      _experienceController.text = widget.vet!.experience.toString();
      _feeController.text = (widget.vet!.consultationFee ?? 0).toString();
      _bioController.text = widget.vet!.bio ?? '';
      _profileImageUrl = widget.vet!.profileImageUrl;
      _isLoading = false;
    } else {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ================= LOAD PROFILE =================
  Future<void> _loadProfile() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser!.id;
      final supabase = Supabase.instance.client;

      // ✅ Load from profiles
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profileData != null) {
        _nameController.text = profileData['full_name'] ?? '';
        _phoneController.text = profileData['phone'] ?? '';
        _emailController.text = profileData['email'] ?? '';
        _profileImageUrl = profileData['profile_image_url'];
      }

      // ✅ Load from vet_profiles
      final data = await supabase
          .from('vet_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null) {
        if (_nameController.text.isEmpty) {
          _nameController.text = data['full_name'] ?? '';
        }
        _specializationController.text = data['specialization'] ?? '';
        _locationController.text = data['location'] ?? '';

        if (_phoneController.text.isEmpty) {
          _phoneController.text = data['phone'] ?? '';
        }
        if (_emailController.text.isEmpty) {
          _emailController.text = data['email'] ?? '';
        }

        _experienceController.text = (data['experience'] ?? 0).toString();
        _feeController.text = (data['consultation_fee'] ?? 0).toString();
        _bioController.text = data['bio'] ?? '';

        if (_profileImageUrl == null || _profileImageUrl!.isEmpty) {
          _profileImageUrl = data['profile_image_url'];
        }
      }
    } catch (e) {
      debugPrint('❌ Load profile error: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ================= ✅ PICK IMAGE =================
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (picked != null && mounted) {
        setState(() {
          _newImageFile = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint('❌ Pick image error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  // ================= ✅ SHOW IMAGE SOURCE OPTIONS =================
  void _showImageSourceSheet() {
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
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.12),
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
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.12),
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
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ================= ✅ UPLOAD PHOTO TO SUPABASE STORAGE =================
  Future<String?> _uploadPhoto(File file, String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final fileExt = file.path.split('.').last;
      final fileName =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload to storage
      await supabase.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      // Get public URL
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      debugPrint('✅ Photo uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Upload photo error: $e');
      return null;
    }
  }

  // ================= SAVE PROFILE =================
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final supabase = Supabase.instance.client;
      final userId = authService.currentUser!.id;

      // ✅ 1. Upload new photo if exists
      String? newPhotoUrl;
      if (_newImageFile != null) {
        setState(() => _isUploadingPhoto = true);
        newPhotoUrl = await _uploadPhoto(_newImageFile!, userId);
        setState(() => _isUploadingPhoto = false);

        if (newPhotoUrl == null) {
          throw Exception('Photo upload failed');
        }
      }

      // ✅ 2. Update profiles table
      final profileUpdate = <String, dynamic>{
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
      if (newPhotoUrl != null) {
        profileUpdate['profile_image_url'] = newPhotoUrl;
      }

      await supabase.from('profiles').update(profileUpdate).eq('id', userId);

      // ✅ 3. Update vet_profiles table
      final vetUpdate = <String, dynamic>{
        'full_name': _nameController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'location': _locationController.text.trim(),
        'phone': _phoneController.text.trim(),
        'experience': int.tryParse(_experienceController.text) ?? 0,
        'consultation_fee': double.tryParse(_feeController.text) ?? 0,
        'bio': _bioController.text.trim(),
      };
      if (newPhotoUrl != null) {
        vetUpdate['profile_image_url'] = newPhotoUrl;
      }

      await supabase
          .from('vet_profiles')
          .update(vetUpdate)
          .eq('user_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Profile updated successfully!'),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Save profile error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: const Color(0xFFE15B5B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isUploadingPhoto = false;
      });
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
          'Edit Vet Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // ================= PROFILE IMAGE =================
                    _buildProfileImage(),

                    const SizedBox(height: 8),

                    TextButton.icon(
                      onPressed: _isUploadingPhoto
                          ? null
                          : _showImageSourceSheet,
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        size: 16,
                        color: primaryGreen,
                      ),
                      label: Text(
                        _isUploadingPhoto ? 'Uploading...' : 'Change Photo',
                        style: const TextStyle(
                          color: primaryGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: _validateName,
                    ),
                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _specializationController,
                      label: 'Specialization',
                      icon: Icons.medical_services_outlined,
                      validator: _validateSpecialization,
                    ),
                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _locationController,
                      label: 'Location',
                      icon: Icons.location_on_outlined,
                      validator: _validateLocation,
                    ),
                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      enabled: false,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _experienceController,
                            label: 'Experience (Years)',
                            icon: Icons.workspace_premium_outlined,
                            keyboardType: TextInputType.number,
                            validator: _validateExperience,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _feeController,
                            label: 'Fee (Rs.)',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: _validateFee,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildBioField(),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveProfile,
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
                                Icons.save,
                                color: Colors.white,
                                size: 20,
                              ),
                        label: Text(
                          _isLoading ? 'Saving...' : 'Save Changes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          elevation: 0,
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

  // ================= ✅ PROFILE IMAGE (with preview) =================
  Widget _buildProfileImage() {
    final hasNewImage = _newImageFile != null;
    final hasExistingImage =
        _profileImageUrl != null && _profileImageUrl!.isNotEmpty;

    return Stack(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryGreen.withValues(alpha: 0.12),
            border: Border.all(
              color: primaryGreen.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
          child: ClipOval(
            // ✅ Show new picked image first
            child: hasNewImage
                ? Image.file(
                    _newImageFile!,
                    fit: BoxFit.cover,
                    width: 110,
                    height: 110,
                  )
                : hasExistingImage
                ? Image.network(
                    _profileImageUrl!,
                    fit: BoxFit.cover,
                    width: 110,
                    height: 110,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: primaryGreen,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, color: primaryGreen, size: 50),
                  )
                : const Icon(Icons.person, color: primaryGreen, size: 50),
          ),
        ),

        // ✅ Camera badge (tap to change)
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploadingPhoto ? null : _showImageSourceSheet,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: _isUploadingPhoto
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ),

        // ✅ "NEW" badge if picked new photo
        if (hasNewImage)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // VALIDATION FUNCTIONS
  // ============================================================

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
  }

  String? _validateSpecialization(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Specialization is required';
    }
    if (value.trim().length < 3) {
      return 'Specialization must be at least 3 characters';
    }
    if (value.trim().length > 50) {
      return 'Specialization must be less than 50 characters';
    }
    return null;
  }

  String? _validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Location is required';
    }
    if (value.trim().length < 2) {
      return 'Location must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Location must be less than 50 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+94')) {
      if (cleaned.length != 12) {
        return 'Enter valid phone (e.g. +94771234567)';
      }
    } else if (cleaned.startsWith('0')) {
      if (cleaned.length != 10) {
        return 'Enter valid phone (e.g. 0771234567)';
      }
    } else {
      return 'Phone must start with 0 or +94';
    }
    return null;
  }

  String? _validateExperience(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Experience is required';
    }
    final number = int.tryParse(value.trim());
    if (number == null) {
      return 'Enter a valid number';
    }
    if (number < 0) {
      return 'Experience cannot be negative';
    }
    if (number > 60) {
      return 'Experience cannot exceed 60 years';
    }
    return null;
  }

  String? _validateFee(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Consultation fee is required';
    }
    final fee = double.tryParse(value.trim());
    if (fee == null) {
      return 'Enter a valid amount';
    }
    if (fee < 100) {
      return 'Fee must be at least Rs. 100';
    }
    if (fee > 50000) {
      return 'Fee cannot exceed Rs. 50,000';
    }
    return null;
  }

  String? _validateBio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (value.trim().length < 20) {
      return 'Bio must be at least 20 characters';
    }
    if (value.trim().length > 500) {
      return 'Bio must be less than 500 characters';
    }
    return null;
  }

  // ================= TEXT FIELD =================
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: darkText,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: mutedText,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: enabled ? mutedText : mutedText.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: enabled ? inputBg : disabledBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE15B5B), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE15B5B), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 14,
        ),
      ),
    );
  }

  // ================= BIO FIELD =================
  Widget _buildBioField() {
    return TextFormField(
      controller: _bioController,
      maxLines: 5,
      minLines: 4,
      maxLength: 500,
      validator: _validateBio,
      style: const TextStyle(fontSize: 13, color: darkText, height: 1.5),
      decoration: InputDecoration(
        labelText: 'About Me (Bio)',
        labelStyle: const TextStyle(
          fontSize: 12,
          color: mutedText,
          fontWeight: FontWeight.w500,
        ),
        hintText:
            'Tell farmers about your experience, services, and expertise...',
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        alignLabelWithHint: true,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 80),
          child: Icon(Icons.description_outlined, size: 20, color: mutedText),
        ),
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE15B5B), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE15B5B), width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(14),
        counterStyle: const TextStyle(fontSize: 10, color: mutedText),
      ),
    );
  }
}
