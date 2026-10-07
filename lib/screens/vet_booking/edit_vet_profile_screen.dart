import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/vet_model.dart';
import '../../services/auth_service.dart';

class EditVetProfileScreen extends StatefulWidget {
  final VetModel? vet; // ← Optional (required නෙවෙයි)

  const EditVetProfileScreen({super.key, this.vet});

  @override
  State<EditVetProfileScreen> createState() => _EditVetProfileScreenState();
}

class _EditVetProfileScreenState extends State<EditVetProfileScreen> {
  static const Color primaryGreen = Color(0xFF20B769);

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    if (widget.vet != null) {
      // Vet model එකෙන් load කරන්න
      _nameController.text = widget.vet!.name;
      _specializationController.text = widget.vet!.specialization;
      _locationController.text = widget.vet!.location;
      _phoneController.text = widget.vet!.phone;
      _emailController.text = widget.vet!.email;
      _experienceController.text = widget.vet!.experience.toString();
      _feeController.text = widget.vet!.consultationFee.toString();
      _isLoading = false;
    } else {
      // Logged-in user ගේ profile එකෙන් load කරන්න
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profile = await authService.getUserProfile();

    if (profile != null) {
      _nameController.text = profile['full_name'] ?? '';
      _specializationController.text = profile['specialization'] ?? '';
      _locationController.text = profile['location'] ?? '';
      _phoneController.text = profile['phone'] ?? '';
      _emailController.text = profile['email'] ?? '';
      _experienceController.text = (profile['experience'] ?? 0).toString();
      _feeController.text = (profile['consultation_fee'] ?? 0).toString();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authService = Provider.of<AuthService>(context, listen: false);

      try {
        final supabase = Supabase.instance.client;

        await supabase
            .from('profiles')
            .update({
              'full_name': _nameController.text.trim(),
              'specialization': _specializationController.text.trim(),
              'location': _locationController.text.trim(),
              'phone': _phoneController.text.trim(),
              'experience': int.tryParse(_experienceController.text) ?? 0,
              'consultation_fee': double.tryParse(_feeController.text) ?? 0,
            })
            .eq('id', authService.currentUser!.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
          );
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
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
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // ================= PROFILE IMAGE =================
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 55,
                          backgroundColor: Color(0xFFE5F7EA),
                          backgroundImage: NetworkImage(
                            'https://i.pravatar.cc/150?img=12',
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Change photo coming soon'),
                          ),
                        );
                      },
                      child: const Text(
                        'Change Photo',
                        style: TextStyle(
                          color: primaryGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ================= FULL NAME =================
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),

                    // ================= SPECIALIZATION =================
                    _buildTextField(
                      controller: _specializationController,
                      label: 'Specialization',
                      icon: Icons.medical_services_outlined,
                    ),
                    const SizedBox(height: 16),

                    // ================= LOCATION =================
                    _buildTextField(
                      controller: _locationController,
                      label: 'Location',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 16),

                    // ================= PHONE =================
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // ================= EMAIL (disabled) =================
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // ================= EXPERIENCE =================
                    _buildTextField(
                      controller: _experienceController,
                      label: 'Experience (Years)',
                      icon: Icons.workspace_premium_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // ================= CONSULTATION FEE =================
                    _buildTextField(
                      controller: _feeController,
                      label: 'Consultation Fee (Rs.)',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 32),

                    // ================= SAVE BUTTON =================
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Save Changes',
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

  // ================= TEXT FIELD WIDGET =================
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF697A71)),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF697A71)),
        filled: true,
        fillColor: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        return null;
      },
    );
  }
}
