import 'package:flutter/material.dart';
import 'package:pcea_church/screen/account_summary.dart';
import 'package:pcea_church/screen/base_dashboard.dart';
import 'package:pcea_church/screen/my_groups.dart';
import 'package:pcea_church/screen/payments.dart';
import 'package:pcea_church/screen/member_messages.dart';
import 'package:pcea_church/screen/pledges.dart';
import 'package:pcea_church/screen/view_events.dart';

class MemberDashboard extends BaseDashboard {
  const MemberDashboard({super.key});

  @override
  String getRoleTitle() => 'Member';

  @override
  String getRoleDescription() =>
      'Regular church member with access to personal profile and contribution features';

  @override
  List<DashboardCard> getDashboardCards(BuildContext context) {
    return [
      DashboardCard(
        icon: Icons.account_balance_wallet_rounded,
        title: 'My Account summary',
        color: Colors.teal,
        subtitle: 'View & edit profile',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LedgerPage()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.campaign,
        title: 'Church Communications',
        color: Colors.teal,
        subtitle: 'View messages from elders',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MemberMessagesScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.wallet_rounded,
        title: 'Contribute via m-Pesa',
        color: Colors.teal,
        subtitle: 'Make contributions',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PaymentsPage()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.flag,
        title: 'My Pledges',
        color: Colors.teal,
        subtitle: 'Manage pledges',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PledgesPage()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.groups,
        title: 'Church groups',
        color: Colors.teal,
        subtitle: 'Manage your church groups',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyGroupsScreen()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.event,
        title: 'Church Calender',
        color: Colors.teal,
        subtitle: 'View events',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ViewEventsScreen()),
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
        icon: Icon(Icons.campaign_rounded),
        label: "Messages",
      ),
      BottomNavigationBarItem(icon: Icon(Icons.group), label: "Dependents"),
      BottomNavigationBarItem(
        icon: Icon(Icons.account_balance_wallet),
        label: "Payments",
      ),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
    ];
  }

  @override
  Color getPrimaryColor() => const Color(0xFF35C2C1); // Teal

  @override
  Color getSecondaryColor() => const Color(0xFF20BBA6); // Dark Teal

  @override
  IconData getRoleIcon() => Icons.person;
}

// Placeholder screens for Member-specific functionality

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF35C2C1),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Notifications',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'View church announcements and updates',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class MinistryInvolvementScreen extends StatelessWidget {
  const MinistryInvolvementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ministry Involvement'),
        backgroundColor: const Color(0xFF35C2C1),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.church, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Ministry Involvement',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Explore opportunities to get involved in church ministries',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
