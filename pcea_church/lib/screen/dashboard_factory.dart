import 'package:flutter/material.dart';
import 'package:pcea_church/screen/base_dashboard.dart';
import 'package:pcea_church/screen/pastor_dashboard.dart';
import 'package:pcea_church/screen/elder_dashboard.dart';
import 'package:pcea_church/screen/deacon_dashboard.dart';
import 'package:pcea_church/screen/secretary_dashboard.dart';
import 'package:pcea_church/screen/treasurer_dashboard.dart';
import 'package:pcea_church/screen/choir_leader_dashboard.dart';
import 'package:pcea_church/screen/youth_leader_dashboard.dart';
import 'package:pcea_church/screen/sunday_school_teacher_dashboard.dart';
import 'package:pcea_church/screen/member_dashboard.dart';

class DashboardFactory {
  /// Creates and returns the appropriate dashboard based on the user's role
  static BaseDashboard createDashboard(String role) {
    switch (role.toLowerCase()) {
      // Leadership Roles
      case 'pastor':
        return const PastorDashboard();
      case 'elder':
        return const ElderDashboard();
      case 'deacon':
        return const DeaconDashboard();

      // Administrative Roles
      case 'secretary':
        return const SecretaryDashboard();
      case 'treasurer':
        return const TreasurerDashboard();

      // Ministry Roles
      case 'choir_leader':
      case 'choir leader':
        return const ChoirLeaderDashboard();
      case 'youth_leader':
      case 'youth leader':
        return const YouthLeaderDashboard();
      case 'sunday_school_teacher':
      case 'sunday school teacher':
        return const SundaySchoolTeacherDashboard();

      // Default to member dashboard
      case 'member':
      default:
        return const MemberDashboard();
    }
  }

  /// Gets the display name for a role
  static String getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'pastor':
        return 'Pastor';
      case 'elder':
        return 'Elder';
      case 'deacon':
        return 'Deacon';
      case 'secretary':
        return 'Secretary';
      case 'treasurer':
        return 'Treasurer';
      case 'chairman':
        return 'Chairman';
      case 'choir_leader':
      case 'choir leader':
        return 'Choir Leader';
      case 'youth_leader':
      case 'youth leader':
        return 'Youth Leader';
      case 'sunday_school_teacher':
      case 'sunday school teacher':
        return 'Sunday School Teacher';
      case 'member':
      default:
        return 'Member';
    }
  }

  /// Gets the color scheme for a role
  static Color getRolePrimaryColor(String role) {
    switch (role.toLowerCase()) {
      case 'pastor':
        return const Color(0xFF8B4513); // Saddle Brown
      case 'elder':
        return const Color(0xFF2E7D32); // Dark Green
      case 'deacon':
        return const Color(0xFF1976D2); // Blue
      case 'secretary':
        return const Color(0xFF795548); // Brown
      case 'treasurer':
        return const Color(0xFF388E3C); // Dark Green
      case 'chairman':
        return const Color(0xFF1565C0); // Deep Blue
      case 'choir_leader':
      case 'choir leader':
        return const Color(0xFF7B1FA2); // Purple
      case 'youth_leader':
      case 'youth leader':
        return const Color(0xFFE91E63); // Pink
      case 'sunday_school_teacher':
      case 'sunday school teacher':
        return const Color(0xFFE91E63); // Pink
      case 'member':
      default:
        return const Color(0xFF35C2C1); // Teal
    }
  }

  /// Gets the secondary color for a role
  static Color getRoleSecondaryColor(String role) {
    switch (role.toLowerCase()) {
      case 'pastor':
        return const Color(0xFFCD853F); // Peru
      case 'elder':
        return const Color(0xFF4CAF50); // Green
      case 'deacon':
        return const Color(0xFF42A5F5); // Light Blue
      case 'secretary':
        return const Color(0xFFA1887F); // Light Brown
      case 'treasurer':
        return const Color(0xFF66BB6A); // Light Green
      case 'chairman':
        return const Color(0xFF42A5F5); // Light Blue
      case 'choir_leader':
      case 'choir leader':
        return const Color(0xFFBA68C8); // Light Purple
      case 'youth_leader':
      case 'youth leader':
        return const Color(0xFFF06292); // Light Pink
      case 'sunday_school_teacher':
      case 'sunday school teacher':
        return const Color(0xFFF8BBD9); // Light Pink
      case 'member':
      default:
        return const Color(0xFF20BBA6); // Teal
    }
  }

  /// Gets the icon for a role
  static IconData getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'pastor':
        return Icons.church;
      case 'elder':
        return Icons.admin_panel_settings;
      case 'deacon':
        return Icons.volunteer_activism;
      case 'secretary':
        return Icons.description;
      case 'treasurer':
        return Icons.account_balance;
      case 'chairman':
        return Icons.admin_panel_settings;
      case 'choir_leader':
      case 'choir leader':
        return Icons.music_note;
      case 'youth_leader':
      case 'youth leader':
        return Icons.child_care;
      case 'sunday_school_teacher':
      case 'sunday school teacher':
        return Icons.school;
      case 'member':
      default:
        return Icons.person;
    }
  }

  /// Checks if a role is a leadership role
  static bool isLeadershipRole(String role) {
    const leadershipRoles = ['pastor', 'elder', 'deacon', 'chairman'];
    return leadershipRoles.contains(role.toLowerCase());
  }

  /// Checks if a role is an administrative role
  static bool isAdministrativeRole(String role) {
    const adminRoles = ['secretary', 'treasurer', 'chairman'];
    return adminRoles.contains(role.toLowerCase());
  }

  /// Checks if a role is a ministry role
  static bool isMinistryRole(String role) {
    const ministryRoles = [
      'choir_leader',
      'choir leader',
      'youth_leader',
      'youth leader',
      'sunday_school_teacher',
      'sunday school teacher',
    ];
    return ministryRoles.contains(role.toLowerCase());
  }

  /// Gets all available roles
  static List<String> getAllRoles() {
    return [
      'pastor',
      'elder',
      'deacon',
      'secretary',
      'treasurer',
      'chairman',
      'choir_leader',
      'youth_leader',
      'sunday_school_teacher',
      'member',
    ];
  }

  /// Gets roles by category
  static Map<String, List<String>> getRolesByCategory() {
    return {
      'Leadership': ['pastor', 'elder', 'deacon', 'chairman'],
      'Administrative': ['secretary', 'treasurer'],
      'Ministry': ['choir_leader', 'youth_leader', 'sunday_school_teacher'],
      'General': ['member'],
    };
  }
}
