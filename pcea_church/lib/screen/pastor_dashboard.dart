import 'package:flutter/material.dart';
import 'package:pcea_church/screen/base_dashboard.dart';
import 'package:pcea_church/screen/profile.dart';

class PastorDashboard extends BaseDashboard {
  const PastorDashboard({super.key});

  @override
  String getRoleTitle() => 'Pastor';

  @override
  String getRoleDescription() =>
      'Senior pastoral leadership with oversight of congregation spiritual life and church operations';

  @override
  List<DashboardCard> getDashboardCards(BuildContext context) {
    return [
      DashboardCard(
        icon: Icons.person,
        title: 'My Profile',
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
        subtitle: 'View & manage',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ContributionsManagementScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.church,
        title: 'Services',
        color: Colors.purple,
        subtitle: 'Plan & conduct',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ServicesManagementScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.assignment,
        title: 'Reports',
        color: Colors.orange,
        subtitle: 'Analytics & insights',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportsScreen()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.notifications,
        title: 'Communications',
        color: Colors.teal,
        subtitle: 'Send announcements',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CommunicationsScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.event,
        title: 'Events',
        color: Colors.indigo,
        subtitle: 'Plan church events',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EventsManagementScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.group_add,
        title: 'Role Management',
        color: Colors.brown,
        subtitle: 'Assign leadership',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RoleManagementScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.volunteer_activism,
        title: 'Ministry',
        color: Colors.deepPurple,
        subtitle: 'Oversee ministries',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MinistryOversightScreen(),
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
      BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      BottomNavigationBarItem(icon: Icon(Icons.group), label: "Members"),
      BottomNavigationBarItem(icon: Icon(Icons.church), label: "Ministry"),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
    ];
  }

  @override
  Color getPrimaryColor() => const Color(0xFF8B4513); // Saddle Brown

  @override
  Color getSecondaryColor() => const Color(0xFFCD853F); // Peru

  @override
  IconData getRoleIcon() => Icons.church;
}

// Placeholder screens for Pastor-specific functionality
class MemberManagementScreen extends StatelessWidget {
  const MemberManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Management'),
        backgroundColor: const Color(0xFF8B4513),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Member Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'View, add, and manage congregation members',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ContributionsManagementScreen extends StatelessWidget {
  const ContributionsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributions Management'),
        backgroundColor: const Color(0xFF8B4513),
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
              'View and manage church contributions',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ServicesManagementScreen extends StatelessWidget {
  const ServicesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services Management'),
        backgroundColor: const Color(0xFF8B4513),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.church, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Services Planning',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Plan and manage church services',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: const Color(0xFF8B4513),
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
              'View church statistics and reports',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class CommunicationsScreen extends StatelessWidget {
  const CommunicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communications'),
        backgroundColor: const Color(0xFF8B4513),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Communications',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Send announcements and messages',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class EventsManagementScreen extends StatelessWidget {
  const EventsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events Management'),
        backgroundColor: const Color(0xFF8B4513),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Events Planning',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Plan and manage church events',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class RoleManagementScreen extends StatelessWidget {
  const RoleManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
        backgroundColor: const Color(0xFF8B4513),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_add, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Role Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Assign and manage leadership roles',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class MinistryOversightScreen extends StatelessWidget {
  const MinistryOversightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ministry Oversight'),
        backgroundColor: const Color(0xFF8B4513),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Ministry Oversight',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Oversee church ministries and programs',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
