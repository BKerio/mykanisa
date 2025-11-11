import 'package:flutter/material.dart';
import 'package:pcea_church/screen/base_dashboard.dart';
import 'package:pcea_church/screen/profile.dart';
import 'package:pcea_church/components/settings.dart';
import 'package:pcea_church/screen/elder_communications.dart';

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
        icon: Icons.person,
        title: 'Member Profile',
        color: Colors.blue,
        subtitle: 'View & edit profile',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.account_balance_wallet,
        title: 'Contributions',
        color: Colors.green,
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
      DashboardCard(
        icon: Icons.business,
        title: 'Church Board',
        color: Colors.purple,
        subtitle: 'Governance',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChurchBoardScreen()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.assignment,
        title: 'Reports',
        color: Colors.orange,
        subtitle: 'View analytics',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ElderReportsScreen()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.notifications,
        title: 'Communications',
        color: Colors.teal,
        subtitle: 'Send & receive messages',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ElderCommunicationsScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.group_add,
        title: 'Role Assignment',
        color: Colors.brown,
        subtitle: 'Assign roles',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ElderRoleAssignmentScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.church,
        title: 'Congregation',
        color: Colors.indigo,
        subtitle: 'Oversee growth',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CongregationOversightScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.settings,
        title: 'Settings',
        color: Colors.deepPurple,
        subtitle: 'App preferences',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        },
      ),
    ];
  }

  @override
  List<BottomNavigationBarItem> getBottomNavItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
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

class ElderContributionsScreen extends StatelessWidget {
  const ElderContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributions'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Contributions Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'View contribution records and statistics',
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

class ElderRoleAssignmentScreen extends StatelessWidget {
  const ElderRoleAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Assignment'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_add, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Role Assignment',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Assign roles to congregation members',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class CongregationOversightScreen extends StatelessWidget {
  const CongregationOversightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Congregation Oversight'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.church, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Congregation Oversight',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Oversee congregation growth and development',
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
