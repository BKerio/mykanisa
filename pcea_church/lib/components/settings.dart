import 'package:flutter/material.dart';
import 'package:pcea_church/screen/profile.dart';
import 'package:pcea_church/screen/view_dependents.dart';
import 'package:pcea_church/theme/theme_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
                      max: 1.6,
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
                  SwitchListTile(
                    contentPadding: const EdgeInsets.all(0),
                    secondary: const Icon(Icons.contrast_rounded),
                    title: const Text('High contrast'),
                    value: ThemeController.instance.highContrast,
                    onChanged: (val) async {
                      await ThemeController.instance.setHighContrast(val);
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
