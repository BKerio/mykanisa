import 'package:flutter/material.dart';
import 'package:pcea_church/screen/base_dashboard.dart';
import 'package:pcea_church/screen/members.dart';
import 'package:pcea_church/screen/elder_message_form.dart';
import 'package:pcea_church/screen/church_contribution.dart';
import 'package:pcea_church/screen/elder_events_list.dart';
import 'package:pcea_church/screen/digital_storage.dart';

class ElderDashboard extends BaseDashboard {
  const ElderDashboard({super.key});

  @override
  String getRoleTitle() => 'Elder';

  @override
  String getRoleDescription() =>
      'Church elder with oversight responsibilities for spiritual guidance and church governance';

  @override
  List<DashboardCard> getDashboardCards(BuildContext context) {
    return [
      DashboardCard(
        icon: Icons.campaign_rounded,
        title: 'Church Communication',
        color: Colors.teal,
        subtitle: 'Save message to database',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ElderMessageFormScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.groups,
        title: 'Congregation Members',
        color: Colors.teal,
        subtitle: 'View your flock',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MembersScreen()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.event,
        title: 'Manage Church Events',
        color: Colors.teal,
        subtitle: 'Create and manage events',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ElderEventsListScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.folder_shared_rounded,
        title: 'Member Digital File',
        color: Colors.teal,
        subtitle: 'View digital footprints',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MemberDigitalFileScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.wallet_giftcard_rounded,
        title: ' Church Contributions',
        color: Colors.teal,
        subtitle: 'View records',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ElderContributionsScreen(),
            ),
          );
        },
      ),
    ];
  }

  @override
  List<BottomNavigationBarItem> getBottomNavItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today),
        label: "church Calender",
      ),
      BottomNavigationBarItem(icon: Icon(Icons.group), label: "Members"),
      BottomNavigationBarItem(icon: Icon(Icons.business), label: "Board"),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
    ];
  }

  @override
  Color getPrimaryColor() => const Color(0xFF2E7D32); // Dark Green

  @override
  Color getSecondaryColor() => const Color(0xFF4CAF50); // Green

  @override
  IconData getRoleIcon() => Icons.admin_panel_settings;
}

// Placeholder screens for Elder-specific functionality
class ElderMemberViewScreen extends StatelessWidget {
  const ElderMemberViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Overview'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Member Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'View and manage congregation members',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ChurchBoardScreen extends StatelessWidget {
  const ChurchBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Church Board'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Church Board',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Church governance and board meetings',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ElderReportsScreen extends StatelessWidget {
  const ElderReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Reports & Analytics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'View church reports and analytics',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class MinistrySupportScreen extends StatelessWidget {
  const MinistrySupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ministry Support'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Ministry Support',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Support and guide church ministries',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
