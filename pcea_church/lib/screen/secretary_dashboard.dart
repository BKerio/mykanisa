import 'package:flutter/material.dart';
import 'package:pcea_church/screen/base_dashboard.dart';
import 'package:pcea_church/screen/member_messages.dart';
import 'package:pcea_church/screen/members.dart';
import 'package:pcea_church/screen/view_events.dart';
import 'package:pcea_church/screen/minutes_history.dart';

class SecretaryDashboard extends BaseDashboard {
  const SecretaryDashboard({super.key});

  @override
  String getRoleTitle() => 'Secretary';

  @override
  String getRoleDescription() =>
      'Church secretary with administrative duties for record keeping and church communications';

  @override
  List<DashboardCard> getDashboardCards(BuildContext context) {
    return [
      DashboardCard(
        icon: Icons.groups,
        title: 'Church Members',
        color: Colors.teal,
        subtitle: 'View & manage',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MembersScreen()),
          );
        },
      ),

      DashboardCard(
        icon: Icons.event_note,
        title: 'Manage Minutes',
        color: Colors.teal,
        subtitle: 'History & Create',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MinutesHistoryPage()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.campaign_rounded,
        title: 'Communications',
        color: Colors.teal,
        subtitle: 'Send announcements',
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
        icon: Icons.event,
        title: 'Church Events',
        color: Colors.teal,
        subtitle: 'Plan & manage events',
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
        label: "Communication",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.assignment),
        label: "Manage Minutes",
      ),
      BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
    ];
  }

  @override
  Color getPrimaryColor() => const Color(0xFF0A1F44);

  @override
  Color getSecondaryColor() => const Color(0xFF0A1F44);

  @override
  IconData getRoleIcon() => Icons.description;
}
