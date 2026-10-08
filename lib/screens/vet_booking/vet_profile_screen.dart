import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/vet_model.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'edit_vet_profile_screen.dart';

class VetProfileScreen extends StatefulWidget {
  final VetModel? vet;

  const VetProfileScreen({super.key, this.vet});

  @override
  State<VetProfileScreen> createState() => _VetProfileScreenState();
}

class _VetProfileScreenState extends State<VetProfileScreen> {
  int _selectedTab = 0;
  static const Color primaryGreen = Color(0xFF20B769);

  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.vet == null) {
      _loadProfile();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profile = await authService.getUserProfile();

    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  String get _name =>
      widget.vet?.name ?? _profile?['full_name'] ?? 'Unknown Vet';

  String get _specialization =>
      widget.vet?.specialization ??
      _profile?['specialization'] ??
      'General Veterinarian';

  String get _location =>
      widget.vet?.location ?? _profile?['location'] ?? 'Sri Lanka';

  int get _experience => widget.vet?.experience ?? _profile?['experience'] ?? 0;

  String get _phone => widget.vet?.phone ?? _profile?['phone'] ?? '';

  String get _email => widget.vet?.email ?? _profile?['email'] ?? '';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isOwner = widget.vet == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        automaticallyImplyLeading: !isOwner,
        leading: !isOwner
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Vet Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditVetProfileScreen(),
                  ),
                );
                if (result == true) {
                  _loadProfile();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFE5F7EA),
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?img=12',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3027),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _specialization,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF697A71),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Color(0xFF697A71),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF697A71),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star,
                        size: 18,
                        color: Color(0xFFFFC107),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '4.8',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3027),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '(120+ reviews)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF697A71),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildTab('Overview', 0),
                        _buildTab('Services', 1),
                        _buildTab('Availability', 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                title: '$_experience+ Years',
                                subtitle: 'EXPERIENCE',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                title: '4.0/5.0',
                                subtitle: 'RATING',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                title: _location,
                                subtitle: 'LOCATION',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                title: 'Mon - Fri',
                                subtitle: 'AVAILABILITY',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About Doctor',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3027),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Livestock specialist focused on animal healthcare, disease prevention, treatment and farm animal management.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF697A71),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (isOwner) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildContactCard(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: _phone.isEmpty ? 'N/A' : _phone,
                          ),
                          const SizedBox(height: 10),
                          _buildContactCard(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: _email.isEmpty ? 'N/A' : _email,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            await authService.signOut();
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? primaryGreen : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? primaryGreen : const Color(0xFF697A71),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3027),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF697A71),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5F0E9)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryGreen, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF697A71),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3027),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
