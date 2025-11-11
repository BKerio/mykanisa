import 'package:flutter/material.dart';
import 'package:pcea_church/screen/base_dashboard.dart';

class TreasurerDashboard extends BaseDashboard {
  const TreasurerDashboard({super.key});

  @override
  String getRoleTitle() => 'Treasurer';

  @override
  String getRoleDescription() =>
      'Church treasurer with financial oversight and responsibility for church finances and budgeting';

  @override
  List<DashboardCard> getDashboardCards(BuildContext context) {
    return [
      DashboardCard(
        icon: Icons.account_balance_wallet,
        title: 'Contributions',
        color: Colors.green,
        subtitle: 'View & manage',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TreasurerContributionsScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.account_balance,
        title: 'Accounts',
        color: Colors.blue,
        subtitle: 'Financial accounts',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FinancialAccountsScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.pie_chart,
        title: 'Budget',
        color: Colors.purple,
        subtitle: 'Manage budget',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BudgetManagementScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.receipt,
        title: 'Expenses',
        color: Colors.orange,
        subtitle: 'Track expenses',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExpensesTrackingScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.assessment,
        title: 'Reports',
        color: Colors.teal,
        subtitle: 'Financial reports',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TreasurerReportsScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.payment,
        title: 'Payments',
        color: Colors.brown,
        subtitle: 'Process payments',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PaymentProcessingScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.analytics,
        title: 'Analytics',
        color: Colors.indigo,
        subtitle: 'Financial insights',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FinancialAnalyticsScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.people,
        title: 'Members',
        color: Colors.deepPurple,
        subtitle: 'View records',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TreasurerMembersScreen(),
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
      BottomNavigationBarItem(
        icon: Icon(Icons.account_balance_wallet),
        label: "Finance",
      ),
      BottomNavigationBarItem(icon: Icon(Icons.assessment), label: "Reports"),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
    ];
  }

  @override
  Color getPrimaryColor() => const Color(0xFF388E3C); // Dark Green

  @override
  Color getSecondaryColor() => const Color(0xFF66BB6A); // Light Green

  @override
  IconData getRoleIcon() => Icons.account_balance;
}

// Placeholder screens for Treasurer-specific functionality
class TreasurerContributionsScreen extends StatelessWidget {
  const TreasurerContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributions'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Contributions Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'View and manage all church contributions',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class FinancialAccountsScreen extends StatelessWidget {
  const FinancialAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Accounts'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Financial Accounts',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Manage church financial accounts',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetManagementScreen extends StatelessWidget {
  const BudgetManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Management'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Budget Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Create and manage church budgets',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpensesTrackingScreen extends StatelessWidget {
  const ExpensesTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses Tracking'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Expenses Tracking',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Track and manage church expenses',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class TreasurerReportsScreen extends StatelessWidget {
  const TreasurerReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Financial Reports',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Generate comprehensive financial reports',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentProcessingScreen extends StatelessWidget {
  const PaymentProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Processing'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Payment Processing',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Process and manage church payments',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class FinancialAnalyticsScreen extends StatelessWidget {
  const FinancialAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Financial Analytics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Analyze financial trends and insights',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class TreasurerMembersScreen extends StatelessWidget {
  const TreasurerMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Records'),
        backgroundColor: const Color(0xFF388E3C),
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
              'View member contribution records',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
