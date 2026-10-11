import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const Color primaryGreen = Color(0xFF20B769);

  // ================= FAQ DATA =================
  List<Map<String, String>> get _faqs => [
    {
      'question': 'How do I add a new animal?',
      'answer': 'Go to "My Animals" and tap the "Add Animal" button. Fill in the details and save.',
    },
    {
      'question': 'How do I book a vet appointment?',
      'answer': 'Go to "Consult a Vet", select a vet, and tap "Book Appointment". Choose a date and time.',
    },
    {
      'question': 'How do I request an emergency vet?',
      'answer': 'Go to "Emergency" and tap on the emergency contact number, or use "Emergency Request".',
    },
    {
      'question': 'How do I set vaccination reminders?',
      'answer': 'Go to "Reminders" and tap "Add Reminder". Fill in the details and save.',
    },
    {
      'question': 'How do I view my appointments?',
      'answer':
          'Go to "Appointments" to see your upcoming and past appointments.',
    },
    {
      'question': 'How do I edit my profile?',
      'answer': 'Go to "My Profile" and tap the edit icon on the top right.',
    },
  ];

  // ================= CONTACT =================
  Future<void> _call(BuildContext context, String number) async {
    final Uri url = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _email(BuildContext context, String email) async {
    final Uri url = Uri.parse('mailto:$email');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
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
          'Help & Support',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ================= CONTACT SECTION =================
            _buildSectionTitle('Contact Us'),

            _buildContactCard(
              icon: Icons.phone_outlined,
              title: 'Call Support',
              subtitle: '+94 11 234 5678',
              onTap: () => _call(context, '+94112345678'),
            ),

            _buildContactCard(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@farmcare.com',
              onTap: () => _email(context, 'support@farmcare.com'),
            ),

            _buildContactCard(
              icon: Icons.chat_outlined,
              title: 'Live Chat',
              subtitle: 'Chat with our team',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Live Chat coming soon')),
                );
              },
            ),

            const SizedBox(height: 24),

            // ================= FAQ SECTION =================
            _buildSectionTitle('Frequently Asked Questions'),

            ..._faqs.map((faq) {
              return _buildFaqCard(faq['question']!, faq['answer']!);
            }).toList(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ================= SECTION TITLE =================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3027),
        ),
      ),
    );
  }

  // ================= CONTACT CARD =================
  Widget _buildContactCard({
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
            vertical: 6,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryGreen, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3027),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF697A71)),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  // ================= FAQ CARD =================
  Widget _buildFaqCard(String question, String answer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5F0E9)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3027),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF697A71),
                height: 1.5,
              ),
            ),
          ),
        ],
        iconColor: primaryGreen,
        collapsedIconColor: primaryGreen,
      ),
    );
  }
}
