import 'package:flutter/material.dart';
import 'package:pcea_church/screen/base_dashboard.dart';

class DeaconDashboard extends BaseDashboard {
  const DeaconDashboard({super.key});

  @override
  String getRoleTitle() => 'Deacon';

  @override
  String getRoleDescription() =>
      'Deacon with service and leadership responsibilities for church operations and member care';

  @override
  List<DashboardCard> getDashboardCards(BuildContext context) {
    return [
      DashboardCard(
        icon: Icons.people,
        title: 'Members',
        color: Colors.blue,
        subtitle: 'View & assist',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DeaconMemberSupportScreen(),
            ),
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
              builder: (context) => const DeaconContributionsScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.volunteer_activism,
        title: 'Service',
        color: Colors.purple,
        subtitle: 'Community service',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ServiceActivitiesScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.home_repair_service,
        title: 'Facilities',
        color: Colors.orange,
        subtitle: 'Church maintenance',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FacilitiesManagementScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.event,
        title: 'Events',
        color: Colors.teal,
        subtitle: 'Help organize',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EventSupportScreen()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.help,
        title: 'Support',
        color: Colors.brown,
        subtitle: 'Member assistance',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MemberSupportScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.church,
        title: 'Worship',
        color: Colors.indigo,
        subtitle: 'Service support',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WorshipSupportScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.group,
        title: 'Fellowship',
        color: Colors.deepPurple,
        subtitle: 'Build community',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FellowshipBuildingScreen(),
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
      BottomNavigationBarItem(icon: Icon(Icons.group), label: "Service"),
      BottomNavigationBarItem(
        icon: Icon(Icons.volunteer_activism),
        label: "Ministry",
      ),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
    ];
  }

  @override
  Color getPrimaryColor() => const Color(0xFF1976D2); // Blue

  @override
  Color getSecondaryColor() => const Color(0xFF42A5F5); // Light Blue

  @override
  IconData getRoleIcon() => Icons.volunteer_activism;
}

// Placeholder screens for Deacon-specific functionality
class DeaconMemberSupportScreen extends StatelessWidget {
  const DeaconMemberSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Support'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Member Support',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'View and assist congregation members',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class DeaconContributionsScreen extends StatelessWidget {
  const DeaconContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributions'),
        backgroundColor: const Color(0xFF1976D2),
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
              'View contribution records',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceActivitiesScreen extends StatelessWidget {
  const ServiceActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Activities'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Service Activities',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Community service and outreach programs',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class FacilitiesManagementScreen extends StatelessWidget {
  const FacilitiesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facilities Management'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_repair_service, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Facilities Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Church facilities maintenance and management',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class EventSupportScreen extends StatelessWidget {
  const EventSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Support'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Event Support',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Help organize and support church events',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class MemberSupportScreen extends StatelessWidget {
  const MemberSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Assistance'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Member Assistance',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Provide support and assistance to members',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class WorshipSupportScreen extends StatelessWidget {
  const WorshipSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worship Support'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.church, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Worship Support',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Support worship services and ceremonies',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class FellowshipBuildingScreen extends StatelessWidget {
  const FellowshipBuildingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fellowship Building'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Fellowship Building',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Build and strengthen church community',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
