import 'package:flutter/material.dart';
import 'package:pcea_church/components/responsive_layout.dart';

class ResponsiveSamplePage extends StatelessWidget {
  static const routeName = '/responsive-sample';

  const ResponsiveSamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        title: const Text('Responsive Layout Preview'),
      ),
      body: ResponsiveLayout(
        mobile: const _MobileSampleView(),
        desktop: const _DesktopSampleView(),
      ),
    );
  }
}

class _MobileSampleView extends StatelessWidget {
  const _MobileSampleView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SampleHeader(
          title: 'Mobile Layout',
          subtitle:
              'Current experience is preserved for phones and small tablets.',
          icon: Icons.phone_android,
          pillText: 'Width < 1024px',
        ),
        const SizedBox(height: 20),
        ..._featureCards(context),
      ],
    );
  }
}

class _DesktopSampleView extends StatelessWidget {
  const _DesktopSampleView();

  @override
  Widget build(BuildContext context) {
    return DesktopScaffoldFrame(
      title: '',
      primaryColor: const Color(0xFF35C2C1),
      child: DesktopPageShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SampleHeader(
              title: 'Desktop Layout',
              subtitle:
                  'Adaptive padding, wider cards and navigation rail ready UI.',
              icon: Icons.desktop_windows_rounded,
              pillText: 'Width ≥ 1024px',
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                SizedBox(
                  width: 360,
                  child: _SampleFeatureCard(
                    title: 'Platform aware',
                    description: ResponsiveLayout.isDesktopPlatform()
                        ? 'Running on desktop platform'
                        : 'Running on mobile platform',
                    icon: Icons.devices_other_outlined,
                  ),
                ),
                SizedBox(
                  width: 360,
                  child: _SampleFeatureCard(
                    title: 'Generous spacing',
                    description:
                        'Desktop shell adds 64px horizontal padding by default.',
                    icon: Icons.space_dashboard_outlined,
                  ),
                ),
                SizedBox(
                  width: 360,
                  child: _SampleFeatureCard(
                    title: 'Max width guardrails',
                    description:
                        'Content stays readable with a max width of 1200px.',
                    icon: Icons.width_full_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String pillText;

  const _SampleHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.pillText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1F44).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 40, color: const Color(0xFF0A1F44)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1F44).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      pillText,
                      style: const TextStyle(
                        color: Color(0xFF0A1F44),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(subtitle, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}

List<Widget> _featureCards(BuildContext context) {
  const features = [
    (
      'Responsive wrapper',
      'Single widget exposes both mobile and desktop children.',
      Icons.compare_arrows_rounded,
    ),
    (
      'Platform detection',
      'Easily switch logic for Windows, macOS, Linux or Web.',
      Icons.devices,
    ),
    (
      'Desktop shell',
      'Center content with consistent max-width and padding.',
      Icons.view_week,
    ),
  ];

  return features
      .map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _SampleFeatureCard(
            title: item.$1,
            description: item.$2,
            icon: item.$3,
          ),
        ),
      )
      .toList();
}

class _SampleFeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _SampleFeatureCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1F44).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF0A1F44)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A1F44),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}





