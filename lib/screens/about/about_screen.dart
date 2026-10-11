import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const Color primaryGreen = Color(0xFF20B769);

  // ================= OPEN URL =================
  Future<void> _openUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF9),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ================= APP LOGO =================
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F7EA),
                shape: BoxShape.circle,
                border: Border.all(color: primaryGreen, width: 3),
              ),
              child: const Icon(Icons.pets, color: primaryGreen, size: 50),
            ),

            const SizedBox(height: 16),

            // ================= APP NAME =================
            const Text(
              'FarmCare',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3027),
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Livestock Health Tracking & Vet Consultation',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF697A71)),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F7EA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: primaryGreen,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ================= DESCRIPTION =================
            _buildSectionTitle('About the App'),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5F0E9)),
                ),
                child: const Text(
                  'FarmCare is a mobile application designed to help livestock farmers manage animal health records, book veterinary appointments, and access emergency services. It connects farmers with veterinarians for remote consultations and provides tools for tracking vaccinations, treatments, and medical history.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF697A71),
                    height: 1.6,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ================= FEATURES =================
            _buildSectionTitle('Key Features'),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5F0E9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureItem(
                      icon: Icons.pets,
                      text: 'Animal Health Records',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      icon: Icons.vaccines,
                      text: 'Vaccination Tracking',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      icon: Icons.medical_services,
                      text: 'Vet Consultation',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      icon: Icons.calendar_month,
                      text: 'Appointment Booking',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      icon: Icons.emergency,
                      text: 'Emergency Services',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      icon: Icons.campaign,
                      text: 'Reminders & Notifications',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ================= LINKS =================
            _buildSectionTitle('Connect With Us'),

            _buildLinkTile(
              icon: Icons.language,
              title: 'Website',
              subtitle: 'www.farmcare.lk',
              onTap: () => _openUrl(context, 'https://www.farmcare.lk'),
            ),

            _buildLinkTile(
              icon: Icons.code,
              title: 'GitHub',
              subtitle: 'github.com/anujaananda/livestock-health-app',
              onTap: () => _openUrl(
                context,
                'https://github.com/anujaananda/livestock-health-app',
              ),
            ),

            _buildLinkTile(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: 'info@farmcare.lk',
              onTap: () => _openUrl(context, 'mailto:info@farmcare.lk'),
            ),

            const SizedBox(height: 24),

            // ================= COPYRIGHT =================
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                '© 2026 FarmCare. All rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ================= SECTION TITLE =================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3027),
          ),
        ),
      ),
    );
  }

  // ================= FEATURE ITEM =================
  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFE5F7EA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryGreen, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1E3027),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ================= LINK TILE =================
  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5F0E9)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryGreen, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3027),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF697A71)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(
            Icons.open_in_new,
            size: 14,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}
