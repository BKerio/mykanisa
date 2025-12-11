import 'package:flutter/material.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/screen/attendance_history.dart';
import 'package:pcea_church/screen/digital_card.dart';
import 'package:pcea_church/screen/login.dart';
import 'package:pcea_church/screen/profile.dart';
import 'package:pcea_church/screen/responsive_sample_page.dart';
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
    // Show toast message when logout starts
    if (mounted) {
      API.showSnack(context, 'Logging out...', success: true);
    }

    try {
      // Call backend logout endpoint to delete token on server
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null && token.isNotEmpty) {
        try {
          await API().postRequest(
            url: Uri.parse('${Config.baseUrl}/members/logout'),
            data: {},
          );
        } catch (e) {
          // Continue with logout even if API call fails
          debugPrint('Logout API call failed: $e');
        }
      }

      // Clear all local storage
      await prefs.clear();
    } catch (e) {
      // If anything fails, still clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }

    // Show success toast message
    if (mounted) {
      API.showSnack(context, 'Logged out successfully', success: true);
      // Wait a moment for the toast to be visible before navigating
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  void _confirmLogout() {
    const Color primaryColor = Color(0xFF0A1F44);

    showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: curved,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 26),
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 6),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.08),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: primaryColor,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Are you sure you want to log out?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.35,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 26),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Stay',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context, true);
                            await _logout();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 6,
                            shadowColor: primaryColor.withOpacity(0.25),
                            backgroundColor: primaryColor,
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
              leading: const Icon(Icons.card_membership_rounded),
              title: const Text('My Attendance History'),
              subtitle: const Text('View my attendance records'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AttendanceHistoryPage(),
                  ),
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

          Card(
            child: ListTile(
              leading: const Icon(Icons.desktop_windows_rounded),
              title: const Text('Responsive preview'),
              subtitle: const Text(
                'See how layouts adapt on Windows, macOS or Linux',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ResponsiveSamplePage(),
                  ),
                );
              },
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
