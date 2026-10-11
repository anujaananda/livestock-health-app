// lib/screens/vet_booking/edit_farmer_profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';

class EditFarmerProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profile;

  const EditFarmerProfileScreen({super.key, this.profile});

  @override
  State<EditFarmerProfileScreen> createState() =>
      _EditFarmerProfileScreenState();
}

class _EditFarmerProfileScreenState extends State<EditFarmerProfileScreen> {
  // ================= BOOK APPOINTMENT THEME =================
  static const Color primaryGreen = Color(0xFF24B86A);
  static const Color darkText = Color(0xFF1E3027);
  static const Color mutedText = Color(0xFF697A71);
  static const Color inputBg = Color(0xFFF9FAFB);
  static const Color disabledBg = Color(0xFFF3F4F6);

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _farmNameController = TextEditingController();

  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  String? _profileImageUrl;
  File? _newImageFile;

  @override
  void initState() {
    super.initState();

    if (widget.profile != null) {
      _loadFromWidget();
    } else {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _farmNameController.dispose();
    super.dispose();
  }

  // ✅ Widget එකෙන් data load කරන්න
  void _loadFromWidget() {
    _nameController.text = widget.profile!['full_name'] ?? '';
    _phoneController.text = widget.profile!['phone'] ?? '';
    _emailController.text = widget.profile!['email'] ?? '';
    _locationController.text = widget.profile!['location'] ?? '';
    _farmNameController.text = widget.profile!['farm_name'] ?? '';
    _profileImageUrl = widget.profile!['profile_image_url'];
    _isLoading = false;
  }

  // ================= LOAD PROFILE =================
  Future<void> _loadProfile() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser!.id;
      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        _nameController.text = data['full_name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _emailController.text = data['email'] ?? '';
        _locationController.text = data['location'] ?? '';
        _farmNameController.text = data['farm_name'] ?? '';
        _profileImageUrl = data['profile_image_url'];
      }
    } catch (e) {
      print('❌ Load profile error: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
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

  // ================= ✅ SHOW IMAGE SOURCE SHEET =================
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

  // ================= ✅ UPLOAD PHOTO =================
  Future<String?> _uploadPhoto(File file, String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final fileExt = file.path.split('.').last;
      final fileName =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

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
      final updates = <String, dynamic>{
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'farm_name': _farmNameController.text.trim(),
      };
      if (newPhotoUrl != null) {
        updates['profile_image_url'] = newPhotoUrl;
      }

      await supabase.from('profiles').update(updates).eq('id', userId);

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
      print('❌ Save profile error: $e');
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
          'Edit Farmer Profile',
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

                    _buildTextField(
                      controller: _locationController,
                      label: 'Location',
                      icon: Icons.location_on_outlined,
                      validator: _validateLocation,
                    ),
                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: _farmNameController,
                      label: 'Farm Name (Optional)',
                      icon: Icons.agriculture_outlined,
                      validator: _validateFarmName,
                    ),

                    const SizedBox(height: 24),

                    // ================= SAVE BUTTON =================
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

  // ================= ✅ PROFILE IMAGE =================
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

        // ✅ Camera badge
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

        // ✅ "NEW" badge
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
    final nameRegex = RegExp(r'^[a-zA-Z\s\.\-]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, dots and hyphens';
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
    final phoneRegex = RegExp(r'^[0-9]+$');
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Phone must contain only numbers';
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

  String? _validateFarmName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    if (value.trim().length < 3) {
      return 'Farm name must be at least 3 characters';
    }
    if (value.trim().length > 50) {
      return 'Farm name must be less than 50 characters';
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
}
