import 'package:flutter/material.dart';
import 'package:pcea_church/screen/base_dashboard.dart';

class YouthLeaderDashboard extends BaseDashboard {
  const YouthLeaderDashboard({super.key});

  @override
  String getRoleTitle() => 'Youth Leader';

  @override
  String getRoleDescription() =>
      'Leader of youth ministry with responsibility for young people\'s spiritual growth and engagement';

  @override
  List<DashboardCard> getDashboardCards(BuildContext context) {
    return [
      DashboardCard(
        icon: Icons.people,
        title: 'Youth Members',
        color: Colors.blue,
        subtitle: 'Manage youth',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const YouthMembersScreen()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.event,
        title: 'Youth Events',
        color: Colors.green,
        subtitle: 'Plan activities',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const YouthEventsScreen()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.school,
        title: 'Bible Study',
        color: Colors.purple,
        subtitle: 'Youth studies',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const YouthBibleStudyScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.sports,
        title: 'Activities',
        color: Colors.orange,
        subtitle: 'Recreational',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const YouthActivitiesScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.group,
        title: 'Fellowship',
        color: Colors.teal,
        subtitle: 'Build community',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const YouthFellowshipScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.notifications,
        title: 'Communications',
        color: Colors.brown,
        subtitle: 'Youth updates',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const YouthCommunicationsScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.account_balance_wallet,
        title: 'Contributions',
        color: Colors.indigo,
        subtitle: 'View records',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const YouthContributionsScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.volunteer_activism,
        title: 'Ministry',
        color: Colors.deepPurple,
        subtitle: 'Youth ministry',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const YouthMinistryScreen(),
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
      BottomNavigationBarItem(icon: Icon(Icons.people), label: "Youth"),
      BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
    ];
  }

  @override
  Color getPrimaryColor() => const Color(0xFFE91E63); // Pink

  @override
  Color getSecondaryColor() => const Color(0xFFF06292); // Light Pink

  @override
  IconData getRoleIcon() => Icons.child_care;
}

// Placeholder screens for Youth Leader-specific functionality
class YouthMembersScreen extends StatelessWidget {
  const YouthMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youth Members'),
        backgroundColor: const Color(0xFFE91E63),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Youth Members',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Manage youth ministry membership',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class YouthEventsScreen extends StatelessWidget {
  const YouthEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youth Events'),
        backgroundColor: const Color(0xFFE91E63),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Youth Events',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Plan and organize youth events and activities',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class YouthBibleStudyScreen extends StatelessWidget {
  const YouthBibleStudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youth Bible Study'),
        backgroundColor: const Color(0xFFE91E63),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Youth Bible Study',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Organize and lead youth bible study sessions',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class YouthActivitiesScreen extends StatelessWidget {
  const YouthActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youth Activities'),
        backgroundColor: const Color(0xFFE91E63),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Youth Activities',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Plan recreational and educational activities',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class YouthFellowshipScreen extends StatelessWidget {
  const YouthFellowshipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youth Fellowship'),
        backgroundColor: const Color(0xFFE91E63),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Youth Fellowship',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Build community and fellowship among youth',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class YouthCommunicationsScreen extends StatelessWidget {
  const YouthCommunicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youth Communications'),
        backgroundColor: const Color(0xFFE91E63),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Youth Communications',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Communicate with youth members and parents',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class YouthContributionsScreen extends StatelessWidget {
  const YouthContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributions'),
        backgroundColor: const Color(0xFFE91E63),
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

class YouthMinistryScreen extends StatelessWidget {
  const YouthMinistryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youth Ministry'),
        backgroundColor: const Color(0xFFE91E63),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Youth Ministry',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Oversee youth ministry activities and programs',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
