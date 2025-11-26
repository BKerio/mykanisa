import 'package:flutter/material.dart';
import 'package:pcea_church/screen/digital_card.dart';
import 'package:pcea_church/screen/login.dart';
import 'package:pcea_church/screen/profile.dart';
import 'package:pcea_church/screen/view_dependents.dart';
import 'package:pcea_church/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool darkMode = false;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        elevation: 10,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.black,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Logout of the app',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.4),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(
              Icons.check_circle_outline,
              size: 18,
              color: Colors.white,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
            ),
            onPressed: () {
              Navigator.pop(ctx, true);
              _logout();
            },
            label: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        elevation: 2,
        centerTitle: true,
        title: const Text(
          "Application Settings",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Ensures back arrow or icons stay white
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account update
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('Update my account'),
              subtitle: const Text('Edit personal details and profile images'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.group_rounded),
              title: const Text('Manage my dependents'),
              subtitle: const Text('Add, edit or remove dependents'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DependentFormScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.card_membership_rounded),
              title: const Text('My Membership'),
              subtitle: const Text('View my digital membership card'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DigitalCardScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF0A1F44)),
              title: const Text('Logout'),
              subtitle: const Text('Sign out of this device'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _confirmLogout,
            ),
          ),
          const SizedBox(height: 16),

          // Accessibility Mode
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.all(0),
                    secondary: const Icon(Icons.accessibility_new_rounded),
                    title: const Text('Accessibility Mode'),
                    subtitle: const Text(
                      'Larger text and higher contrast throughout the app',
                    ),
                    value: ThemeController.instance.accessibilityEnabled,
                    onChanged: (enabled) async {
                      await ThemeController.instance.setAccessibilityEnabled(
                        enabled,
                      );
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.format_size_rounded),
                    title: const Text('Text size'),
                    subtitle: Slider(
                      value: ThemeController.instance.textScaleFactor,
                      min: 0.9,
                      max: 1.8,
                      divisions: 7,
                      label:
                          '${ThemeController.instance.textScaleFactor.toStringAsFixed(1)}x',
                      onChanged: (v) async {
                        await ThemeController.instance.setTextScale(v);
                        setState(() {});
                      },
                    ),
                    trailing: Text(
                      '${ThemeController.instance.textScaleFactor.toStringAsFixed(1)}x',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.all(0),
                    secondary: const Icon(Icons.format_bold_rounded),
                    title: const Text('Bold text'),
                    value: ThemeController.instance.boldText,
                    onChanged: (val) async {
                      await ThemeController.instance.setBoldText(val);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
