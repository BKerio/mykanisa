import 'package:flutter/material.dart';
import 'package:pcea_church/screen/base_dashboard.dart';

class SundaySchoolTeacherDashboard extends BaseDashboard {
  const SundaySchoolTeacherDashboard({super.key});

  @override
  String getRoleTitle() => 'Sunday School Teacher';

  @override
  String getRoleDescription() => 'Educational ministry and student management';

  @override
  Color getPrimaryColor() => const Color(0xFFE91E63); // Pink

  @override
  Color getSecondaryColor() => const Color(0xFFF8BBD9); // Light Pink

  @override
  IconData getRoleIcon() => Icons.school;

  @override
  List<DashboardCard> getDashboardCards(BuildContext context) {
    return [
      DashboardCard(
        icon: Icons.child_care,
        title: 'Students',
        color: getPrimaryColor(),
        subtitle: 'Manage students',
        onTap: () => _showStudentsManagement(context),
      ),
      DashboardCard(
        icon: Icons.event,
        title: 'Events',
        color: const Color(0xFF4CAF50),
        subtitle: 'Sunday school events',
        onTap: () => _showEventsManagement(context),
      ),
      DashboardCard(
        icon: Icons.menu_book,
        title: 'Curriculum',
        color: const Color(0xFF2196F3),
        subtitle: 'Lesson plans',
        onTap: () => _showCurriculumManagement(context),
      ),
      DashboardCard(
        icon: Icons.notifications,
        title: 'Notifications',
        color: const Color(0xFFFF9800),
        subtitle: 'Notify students',
        onTap: () => _showNotifications(context),
      ),
      DashboardCard(
        icon: Icons.analytics,
        title: 'Attendance',
        color: const Color(0xFF9C27B0),
        subtitle: 'Track attendance',
        onTap: () => _showAttendance(context),
      ),
      DashboardCard(
        icon: Icons.quiz,
        title: 'Assessments',
        color: const Color(0xFF607D8B),
        subtitle: 'Student progress',
        onTap: () => _showAssessments(context),
      ),
    ];
  }

  @override
  List<BottomNavigationBarItem> getBottomNavItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      BottomNavigationBarItem(
        icon: Icon(Icons.family_restroom),
        label: 'Dependents',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
    ];
  }

  void _showStudentsManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Student Management'),
        content: const Text(
          'This feature will allow you to:\n\n• View all Sunday school students\n• Add new students\n• Edit student information\n• Track student progress\n• Manage student groups',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  void _showEventsManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Events & Activities'),
        content: const Text(
          'This feature will allow you to:\n\n• Create Sunday school events\n• Schedule activities\n• Manage event details\n• Track event attendance\n• Send event reminders',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Navigate to events screen
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  void _showCurriculumManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Curriculum & Lessons'),
        content: const Text(
          'This feature will allow you to:\n\n• Manage lesson plans\n• Create curriculum content\n• Track teaching progress\n• Store teaching materials\n• Plan upcoming lessons',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Navigate to curriculum screen
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Notifications'),
        content: const Text(
          'This feature will allow you to:\n\n• Notify students about events\n• Send lesson reminders\n• Communicate with parents\n• Schedule announcements\n• Track message delivery',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Navigate to notifications screen
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  void _showAttendance(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Attendance & Progress'),
        content: const Text(
          'This feature will allow you to:\n\n• Track student attendance\n• View attendance reports\n• Monitor student progress\n• Generate progress reports\n• Identify attendance patterns',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Navigate to attendance screen
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  void _showAssessments(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Student Assessments'),
        content: const Text(
          'This feature will allow you to:\n\n• Create assessment forms\n• Track student performance\n• Generate progress reports\n• Monitor learning outcomes\n• Plan improvement strategies',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Navigate to assessments screen
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}
