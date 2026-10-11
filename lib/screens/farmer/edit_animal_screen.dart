// lib/screens/farmer/edit_animal_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditAnimalScreen extends StatefulWidget {
  final Map<String, dynamic> animal;

  const EditAnimalScreen({super.key, required this.animal});

  @override
  State<EditAnimalScreen> createState() => _EditAnimalScreenState();
}

class _EditAnimalScreenState extends State<EditAnimalScreen> {
  static const Color primaryGreen = Color(0xFF24B86A);

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _tagController;
  late TextEditingController _speciesController;
  late TextEditingController _breedController;
  late TextEditingController _ageController;

  String _selectedGender = 'Male';
  bool _isSaving = false;

  final List<String> _speciesList = [
    'Cow',
    'Buffalo',
    'Goat',
    'Sheep',
    'Chicken',
    'Pig',
    'Horse',
    'Dog',
    'Cat',
    'Other',
  ];

  final List<String> _genderList = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    final a = widget.animal;
    _nameController = TextEditingController(text: (a['name'] ?? '').toString());
    _tagController = TextEditingController(
      text: (a['animal_id_tag'] ?? '').toString(),
    );
    _speciesController = TextEditingController(
      text: (a['species'] ?? '').toString(),
    );
    _breedController = TextEditingController(
      text: (a['breed'] ?? '').toString(),
    );
    _ageController = TextEditingController(text: (a['age']?.toString() ?? ''));

    final g = (a['gender'] ?? 'Male').toString();
    _selectedGender = _genderList.contains(g) ? g : 'Male';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // ================= SAVE =================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final animalId = widget.animal['id'];

    if (animalId == null) {
      _showMessage('Animal ID not found.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedData = {
        'name': _nameController.text.trim(),
        'animal_id_tag': _tagController.text.trim(),
        'species': _speciesController.text.trim(),
        'breed': _breedController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'gender': _selectedGender,
      };

      await Supabase.instance.client
          .from('animals')
          .update(updatedData)
          .eq('id', animalId);

      if (!mounted) return;

      final merged = {...widget.animal, ...updatedData};
      Navigator.pop(context, merged);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _showMessage('Could not save: ${e.message}', isError: true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not save. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Animal',
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
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                icon: Icons.pets_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _tagController,
                label: 'Animal ID Tag',
                icon: Icons.tag,
              ),
              const SizedBox(height: 14),
              _buildDropdown(
                label: 'Species',
                icon: Icons.category_outlined,
                value: _speciesList.contains(_speciesController.text)
                    ? _speciesController.text
                    : null,
                items: _speciesList,
                onChanged: (v) =>
                    setState(() => _speciesController.text = v ?? ''),
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _breedController,
                label: 'Breed',
                icon: Icons.workspace_premium_outlined,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _ageController,
                label: 'Age (years)',
                icon: Icons.calendar_month_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              _buildDropdown(
                label: 'Gender',
                icon: Icons.transgender_rounded,
                value: _selectedGender,
                items: _genderList,
                onChanged: (v) => setState(() => _selectedGender = v ?? 'Male'),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
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
            ],
          ),
        ),
      ),
    );
  }

  // ================= TEXT FIELD =================
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF697A71)),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF697A71)),
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
    );
  }

  // ================= DROPDOWN =================
  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF697A71)),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF697A71)),
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
      items: items
          .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
