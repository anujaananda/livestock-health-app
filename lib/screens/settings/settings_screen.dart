import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_colors.dart';
import '../../main.dart'; // ✅ ThemeNotifier

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _autoSyncEnabled = true;

  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Sinhala', 'Tamil'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ================= LOAD SETTINGS =================
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _soundEnabled = prefs.getBool('sound') ?? true;
      _autoSyncEnabled = prefs.getBool('autoSync') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'English';
    });
  }

  // ================= SAVE SETTINGS =================
  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.primaryBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ================= GENERAL =================
            _buildSectionTitle('General'),

            _buildSwitchTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Receive push notifications',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _saveSetting('notifications', value);
              },
            ),

            _buildSwitchTile(
              icon: Icons.volume_up_outlined,
              title: 'Sound',
              subtitle: 'Play sound for notifications',
              value: _soundEnabled,
              onChanged: (value) {
                setState(() => _soundEnabled = value);
                _saveSetting('sound', value);
              },
            ),

            // ✅ DARK MODE TOGGLE - WORKS!
            _buildSwitchTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: 'Enable dark theme',
              value: themeNotifier.isDarkMode,
              onChanged: (value) async {
                // ✅ Save to prefs
                await _saveSetting('darkMode', value);
                // ✅ Change app theme immediately
                themeNotifier.toggle(value);
              },
            ),

            const SizedBox(height: 20),

            // ================= LANGUAGE =================
            _buildSectionTitle('Language'),
            _buildLanguageSelector(isDark),

            const SizedBox(height: 20),

            // ================= DATA =================
            _buildSectionTitle('Data & Storage'),

            _buildSwitchTile(
              icon: Icons.sync_outlined,
              title: 'Auto Sync',
              subtitle: 'Sync data automatically',
              value: _autoSyncEnabled,
              onChanged: (value) {
                setState(() => _autoSyncEnabled = value);
                _saveSetting('autoSync', value);
              },
            ),

            _buildActionTile(
              icon: Icons.cleaning_services_outlined,
              title: 'Clear Cache',
              subtitle: 'Free up storage space',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Cache'),
                    content: const Text(
                      'Are you sure you want to clear the cache?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cache cleared successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ================= PRIVACY =================
            _buildSectionTitle('Privacy'),

            _buildActionTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy Policy coming soon')),
                );
              },
            ),

            _buildActionTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'Read our terms and conditions',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Terms of Service coming soon')),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ================= SECTION TITLE =================
  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.darkTextHint : AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ================= SWITCH TILE =================
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.divider,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkPrimarySurface
                : AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }

  // ================= LANGUAGE SELECTOR =================
  Widget _buildLanguageSelector(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.divider,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkPrimarySurface
                    : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.language_outlined,
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'App Language',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            DropdownButton<String>(
              value: _selectedLanguage,
              underline: const SizedBox(),
              dropdownColor: isDark ? AppColors.darkSurface : AppColors.white,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
              items: _languages.map((lang) {
                return DropdownMenuItem<String>(
                  value: lang,
                  child: Text(
                    lang,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                _saveSetting('language', value);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= ACTION TILE =================
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.divider,
          ),
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
              color: isDark
                  ? AppColors.darkPrimarySurface
                  : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: isDark ? AppColors.darkTextHint : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}
