import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'edit_farmer_profile_screen.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  static const Color primaryGreen = Color(0xFF20B769);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profile = await authService.getUserProfile();

    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF9),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Farmer Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditFarmerProfileScreen(profile: _profile),
                ),
              );

              if (result == true) {
                _loadProfile(); // Reload profile after edit
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
                  // ================= COVER IMAGE + PROFILE =================
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Cover Image
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      // Profile Image
                      Positioned(
                        bottom: -50,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: const Color(0xFFE5F7EA),
                            backgroundImage: const NetworkImage(
                              'https://i.pravatar.cc/150?img=13',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // ================= NAME + TYPE + LOCATION =================
                  Text(
                    _profile?['full_name'] ?? 'Unknown User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3027),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _profile?['user_type'] ?? 'Farmer',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF697A71),
                    ),
                  ),

                  const SizedBox(height: 6),

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
                        _profile?['location'] ?? 'Sri Lanka',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF697A71),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ================= STATS ROW =================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildStatItem('12', 'Animals'),
                          _buildDivider(),
                          _buildStatItem('5', 'Appointments'),
                          _buildDivider(),
                          _buildStatItem('8', 'Health Records'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ================= PERSONAL INFORMATION =================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3027),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Full Name
                        _buildInfoCard(
                          icon: Icons.person_outline,
                          label: 'Full Name',
                          value: _profile?['full_name'] ?? 'N/A',
                        ),

                        // Phone
                        _buildInfoCard(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: _profile?['phone'] ?? 'N/A',
                        ),

                        // Email
                        _buildInfoCard(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: _profile?['email'] ?? 'N/A',
                        ),

                        // Address
                        _buildInfoCard(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: _profile?['location'] ?? 'Sri Lanka',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ================= LOGOUT BUTTON =================
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

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ================= STAT ITEM =================
  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3027),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF697A71),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ================= DIVIDER =================
  Widget _buildDivider() {
    return Container(width: 1, height: 30, color: const Color(0xFFE5E7EB));
  }

  // ================= INFO CARD =================
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                    fontWeight: FontWeight.w500,
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
