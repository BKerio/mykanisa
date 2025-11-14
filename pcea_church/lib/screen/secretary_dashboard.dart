import 'package:flutter/material.dart';
import 'package:pcea_church/screen/base_dashboard.dart';
import 'package:pcea_church/screen/minutes_page.dart';

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
        icon: Icons.people,
        title: 'Members',
        color: Colors.blue,
        subtitle: 'View & manage',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SecretaryMembersScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.assignment,
        title: 'Records',
        color: Colors.green,
        subtitle: 'Church records',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MeetingMinutesPage()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.event_note,
        title: 'Minutes',
        color: Colors.purple,
        subtitle: 'Meeting minutes',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MeetingMinutesPage()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.notifications,
        title: 'Communications',
        color: Colors.orange,
        subtitle: 'Send announcements',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SecretaryCommunicationsScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.event,
        title: 'Events',
        color: Colors.teal,
        subtitle: 'Plan events',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SecretaryEventsScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.account_balance_wallet,
        title: 'Contributions',
        color: Colors.brown,
        subtitle: 'View records',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SecretaryContributionsScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.description,
        title: 'Reports',
        color: Colors.indigo,
        subtitle: 'Generate reports',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SecretaryReportsScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.schedule,
        title: 'Schedule',
        color: Colors.deepPurple,
        subtitle: 'Manage calendar',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SecretaryScheduleScreen(),
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
      BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Records"),
      BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
    ];
  }

  @override
  Color getPrimaryColor() => const Color(0xFF795548); // Brown

  @override
  Color getSecondaryColor() => const Color(0xFFA1887F); // Light Brown

  @override
  IconData getRoleIcon() => Icons.description;
}

// Placeholder screens for Secretary-specific functionality
class SecretaryMembersScreen extends StatelessWidget {
  const SecretaryMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Records'),
        backgroundColor: const Color(0xFF795548),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Member Records',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'View and manage member records',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ChurchRecordsScreen extends StatelessWidget {
  const ChurchRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Church Records'),
        backgroundColor: const Color(0xFF795548),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Church Records',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Manage church administrative records',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class MeetingMinutesScreen extends StatelessWidget {
  const MeetingMinutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Minutes'),
        backgroundColor: const Color(0xFF795548),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Meeting Minutes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Record and manage meeting minutes',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class SecretaryCommunicationsScreen extends StatelessWidget {
  const SecretaryCommunicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communications'),
        backgroundColor: const Color(0xFF795548),
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
              'Send announcements and communications',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class SecretaryEventsScreen extends StatelessWidget {
  const SecretaryEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: const Color(0xFF795548),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Event Planning',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Plan and coordinate church events',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class SecretaryContributionsScreen extends StatelessWidget {
  const SecretaryContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributions'),
        backgroundColor: const Color(0xFF795548),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Contributions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'View contribution records',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class SecretaryReportsScreen extends StatelessWidget {
  const SecretaryReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: const Color(0xFF795548),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Reports',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Generate administrative reports',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class SecretaryScheduleScreen extends StatelessWidget {
  const SecretaryScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: const Color(0xFF795548),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Church Schedule',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Manage church calendar and schedule',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
