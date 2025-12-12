import 'package:flutter/material.dart';
import 'package:pcea_church/screen/account_summary.dart';
import 'package:pcea_church/screen/base_dashboard.dart';
import 'package:pcea_church/screen/my_groups.dart';
import 'package:pcea_church/screen/payments.dart';
import 'package:pcea_church/screen/member_messages.dart';
import 'package:pcea_church/screen/pledges.dart';
import 'package:pcea_church/screen/view_events.dart';
import 'package:pcea_church/screen/member_group_leader_message.dart';
import 'package:pcea_church/screen/all_church_groups.dart';
import 'package:pcea_church/screen/minutes_history.dart';

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
        title: 'My Kanisa Contribution Summary',
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
        icon: Icons.group,
        title: 'Message Group Leader',
        color: Colors.teal,
        subtitle: 'Contact your group leader',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MemberGroupLeaderMessageScreen(),
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
      DashboardCard(
        icon: Icons.group_add,
        title: 'Join a Group',
        color: Colors.teal,
        subtitle: 'View all groups & join',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AllChurchGroupsScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.event_note,
        title: 'My Minutes',
        color: Colors.teal,
        subtitle: 'View meeting minutes',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MinutesHistoryPage(
                apiPath: '/minutes/mine',
                canCreate: false, // Members cannot create minutes
              ),
            ),
          );
        },
      ),
    ];
  }

  @override
  List<BottomNavigationBarItem> getBottomNavItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.grid_view_rounded, color: Color(0xFF0A1F44)),
        label: "Home",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF0A1F44)),
        label: "Inbox",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.people_outline_rounded, color: Color(0xFF0A1F44)),
        label: "Family",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined, color: Color(0xFF0A1F44)),
        label: "Settings",
      ),
    ];
  }

  @override
  Color getPrimaryColor() => const Color(0xFF20BBA6);

  @override
  Color getSecondaryColor() => const Color(0xFF20BBA6);

  @override
  IconData getRoleIcon() => Icons.person;
}
