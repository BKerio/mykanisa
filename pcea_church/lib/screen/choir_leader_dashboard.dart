import 'package:flutter/material.dart';
import 'package:pcea_church/screen/base_dashboard.dart';
import 'package:pcea_church/screen/profile.dart';
import 'package:pcea_church/components/settings.dart';

class ChoirLeaderDashboard extends BaseDashboard {
  const ChoirLeaderDashboard({super.key});

  @override
  String getRoleTitle() => 'Choir Leader';

  @override
  String getRoleDescription() =>
      'Leader of the church choir with responsibility for music ministry and worship enhancement';

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
        icon: Icons.queue_music,
        title: 'Songs & Hymns',
        color: Colors.blue,
        subtitle: 'Music library',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SongsHymnsScreen()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.event,
        title: 'Rehearsals',
        color: Colors.green,
        subtitle: 'Schedule practice',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RehearsalsScreen()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.church,
        title: 'Worship Services',
        color: Colors.orange,
        subtitle: 'Service planning',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WorshipServicesScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.mic,
        title: 'Performances',
        color: Colors.teal,
        subtitle: 'Special events',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PerformancesScreen()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.notifications,
        title: 'Communications',
        color: Colors.brown,
        subtitle: 'Choir updates',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChoirCommunicationsScreen(),
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
              builder: (context) => const ChoirContributionsScreen(),
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
      BottomNavigationBarItem(icon: Icon(Icons.music_note), label: "Choir"),
      BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
    ];
  }

  @override
  Color getPrimaryColor() => const Color(0xFF7B1FA2); // Purple

  @override
  Color getSecondaryColor() => const Color(0xFFBA68C8); // Light Purple

  @override
  IconData getRoleIcon() => Icons.music_note;
}

// Placeholder screens for Choir Leader-specific functionality
class ChoirMembersScreen extends StatelessWidget {
  const ChoirMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choir Members'),
        backgroundColor: const Color(0xFF7B1FA2),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Choir Members',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Manage choir membership and roles',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class SongsHymnsScreen extends StatelessWidget {
  const SongsHymnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Songs & Hymns'),
        backgroundColor: const Color(0xFF7B1FA2),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue_music, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Music Library',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Manage songs, hymns, and music repertoire',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class RehearsalsScreen extends StatelessWidget {
  const RehearsalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rehearsals'),
        backgroundColor: const Color(0xFF7B1FA2),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Choir Rehearsals',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Schedule and manage choir rehearsals',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class WorshipServicesScreen extends StatelessWidget {
  const WorshipServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worship Services'),
        backgroundColor: const Color(0xFF7B1FA2),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.church, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Worship Services',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Plan music for worship services',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class PerformancesScreen extends StatelessWidget {
  const PerformancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performances'),
        backgroundColor: const Color(0xFF7B1FA2),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Special Performances',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Manage special choir performances and events',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ChoirCommunicationsScreen extends StatelessWidget {
  const ChoirCommunicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choir Communications'),
        backgroundColor: const Color(0xFF7B1FA2),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Choir Communications',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Communicate with choir members',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ChoirContributionsScreen extends StatelessWidget {
  const ChoirContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributions'),
        backgroundColor: const Color(0xFF7B1FA2),
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

class MusicMinistryScreen extends StatelessWidget {
  const MusicMinistryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Ministry'),
        backgroundColor: const Color(0xFF7B1FA2),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Music Ministry',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Oversee music ministry activities',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
