import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../vet_booking/find_vet_screen.dart';
import 'emergency_request_screen.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  static const Color primaryGreen = Color(0xFF20B769);
  static const Color emergencyRed = Color(0xFFE15B5B);

  // ================= EMERGENCY CONTACTS =================
  List<Map<String, dynamic>> get _emergencyContacts => [
    {
      'name': 'Emergency Vet Hotline',
      'number': '1919',
      'icon': Icons.local_hospital,
      'color': const Color(0xFFE15B5B),
      'bgColor': const Color(0xFFFFE5E5),
    },
    {
      'name': 'Ambulance Service',
      'number': '1990',
      'icon': Icons.emergency,
      'color': const Color(0xFFF59E0B),
      'bgColor': const Color(0xFFFFF4E5),
    },
    {
      'name': 'Animal Hospital',
      'number': '+94112345678',
      'icon': Icons.medical_services,
      'color': const Color(0xFF3B82F6),
      'bgColor': const Color(0xFFE5F0FA),
    },
    {
      'name': 'Police Emergency',
      'number': '119',
      'icon': Icons.local_police,
      'color': const Color(0xFF7652A8),
      'bgColor': const Color(0xFFF0EBFA),
    },
  ];

  // ================= QUICK ACTIONS =================
  List<Map<String, dynamic>> get _quickActions => [
    {
      'title': 'Find Nearest Vet',
      'subtitle': 'Locate vets near you',
      'icon': Icons.location_on,
      'color': const Color(0xFF20B769),
      'bgColor': const Color(0xFFE5F7EA),
      'action': 'find_vet',
    },
    {
      'title': 'Emergency Request',
      'subtitle': 'Request urgent vet visit',
      'icon': Icons.emergency,
      'color': const Color(0xFFE15B5B),
      'bgColor': const Color(0xFFFFE5E5),
      'action': 'emergency_request',
    },
    {
      'title': 'Animal First Aid',
      'subtitle': 'Basic first aid guide',
      'icon': Icons.medical_information,
      'color': const Color(0xFFF59E0B),
      'bgColor': const Color(0xFFFFF4E5),
      'action': 'first_aid',
    },
    {
      'title': 'Disease Alert',
      'subtitle': 'Check disease outbreaks',
      'icon': Icons.warning_amber,
      'color': const Color(0xFFEF4444),
      'bgColor': const Color(0xFFFFE5E5),
      'action': 'disease_alert',
    },
  ];

  // ================= CALL PHONE =================
  Future<void> _callNumber(BuildContext context, String number) async {
    final Uri url = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Cannot call $number')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ================= SHOW MESSAGE =================
  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: primaryGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF9),
      appBar: AppBar(
        backgroundColor: emergencyRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Emergency',
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
            // ================= ALERT BANNER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE15B5B), Color(0xFFEF4444)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emergency,
                      color: emergencyRed,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Emergency Help',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Quick access to emergency veterinary services',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= EMERGENCY CONTACTS =================
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3027),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: _emergencyContacts.map((contact) {
                  return _buildContactCard(context, contact);
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // ================= QUICK ACTIONS =================
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3027),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: _quickActions.map((action) {
                  return _buildQuickActionCard(context, action);
                }).toList(),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ================= CONTACT CARD =================
  Widget _buildContactCard(BuildContext context, Map<String, dynamic> contact) {
    return GestureDetector(
      onTap: () => _callNumber(context, contact['number']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5F0E9)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: contact['bgColor'],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(contact['icon'], color: contact['color'], size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['name'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3027),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact['number'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF697A71),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: contact['bgColor'],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.phone, color: contact['color'], size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ================= QUICK ACTION CARD =================
  Widget _buildQuickActionCard(
    BuildContext context,
    Map<String, dynamic> action,
  ) {
    return GestureDetector(
      onTap: () {
        if (action['action'] == 'find_vet') {
          // ✅ Find a Vet
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FindVetScreen()),
          );
        } else if (action['action'] == 'emergency_request') {
          // ✅ Emergency Request - NEW SCREEN
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmergencyRequestScreen()),
          );
        } else if (action['action'] == 'first_aid') {
          _showMessage(context, 'Animal First Aid coming soon');
        } else if (action['action'] == 'disease_alert') {
          _showMessage(context, 'Disease Alert coming soon');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: action['bgColor'],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(action['icon'], color: action['color'], size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              action['title'],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3027),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              action['subtitle'],
              style: const TextStyle(fontSize: 10, color: Color(0xFF697A71)),
            ),
          ],
        ),
      ),
    );
  }
}
