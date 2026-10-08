import 'package:flutter/material.dart';
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
  static const Color primaryGreen = Color(0xFF20B769);

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _farmNameController;

  String _farmType = 'Dairy & Cattle';
  bool _isLoading = false;

  final List<String> _farmTypes = [
    'Dairy & Cattle',
    'Poultry',
    'Goat Farming',
    'Mixed Farming',
    'Pig Farming',
  ];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.profile?['full_name'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.profile?['phone'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.profile?['email'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.profile?['location'] ?? '',
    );
    _farmNameController = TextEditingController(
      text: widget.profile?['farm_name'] ?? '',
    );
    _farmType = widget.profile?['farm_type'] ?? 'Dairy & Cattle';
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
              'phone': _phoneController.text.trim(),
              'location': _addressController.text.trim(),
              'farm_name': _farmNameController.text.trim(),
              'farm_type': _farmType,
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
            SnackBar(
              content: Text('Failed to update profile: $e'),
              backgroundColor: Colors.red,
            ),
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

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
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
            children: [
              const SizedBox(height: 10),

              // ================= PROFILE IMAGE =================
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 55,
                    backgroundColor: Color(0xFFE5F7EA),
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?img=13',
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
                    const SnackBar(content: Text('Change photo coming soon')),
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

              // ================= PHONE =================
              _buildTextField(
                controller: _phoneController,
                label: 'Phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // ================= EMAIL =================
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: false,
              ),
              const SizedBox(height: 16),

              // ================= ADDRESS =================
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on_outlined,
              ),

              const SizedBox(height: 24),

              // ================= FARM INFORMATION =================
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Farm Information',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3027),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ================= FARM NAME =================
              _buildTextField(
                controller: _farmNameController,
                label: 'Farm Name',
                icon: Icons.agriculture_outlined,
              ),
              const SizedBox(height: 16),

              // ================= FARM TYPE =================
              DropdownButtonFormField<String>(
                value: _farmType,
                decoration: InputDecoration(
                  labelText: 'Farm Type',
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF697A71),
                  ),
                  prefixIcon: const Icon(
                    Icons.category_outlined,
                    size: 20,
                    color: Color(0xFF697A71),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                ),
                items: _farmTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _farmType = v!),
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
                      ? const CircularProgressIndicator(color: Colors.white)
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
