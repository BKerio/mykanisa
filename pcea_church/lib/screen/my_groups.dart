import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/screen/group_activities.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Constants ---
const Color kPrimaryColor = Color(0xFF0A1F44);
const String kDefaultGroupName = 'Unnamed Group';
const String kDefaultGroupDescription = 'No description available';

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  // State variables
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _allGroups = [];
  List<int> _myGroupIds = [];

  // --- Initialization ---

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- Data Fetching Logic ---

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // Fetch both groups and member data concurrently
      await Future.wait([_fetchAllGroups(), _fetchMemberGroups()]);
    } catch (e) {
      // Catch any unhandled exceptions during loading
      _errorMessage = 'A network error occurred. Please try again.';
      debugPrint('Load Error: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAllGroups() async {
    final res = await API().getRequest(
      url: Uri.parse('${Config.baseUrl}/groups'),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if ((body['status'] ?? 400) == 200 && body['groups'] is List) {
        _allGroups = List<Map<String, dynamic>>.from(
          body['groups'] as List? ?? [],
        );
        return;
      }
    }
    // Handle specific API error responses if needed, otherwise let the main try/catch handle failure
  }

  Future<void> _fetchMemberGroups() async {
    final prefs = await SharedPreferences.getInstance();
    String groupsJson = '';

    try {
      final res = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/members/me'),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if ((body['status'] ?? 400) == 200) {
          final m = (body['member'] ?? {}) as Map<String, dynamic>;
          groupsJson = (m['groups'] ?? '') as String;
          await prefs.setString('member_groups_json', groupsJson);
        }
      }
    } catch (e) {
      debugPrint('Error fetching member groups from API: $e');
    }

    // Use cached data if API failed or returned empty
    if (groupsJson.isEmpty) {
      groupsJson = prefs.getString('member_groups_json') ?? '';
    }

    _myGroupIds = _decodeGroupIds(groupsJson);
  }

  List<int> _decodeGroupIds(String groupsJson) {
    if (groupsJson.isEmpty) return [];
    try {
      final list = jsonDecode(groupsJson);
      if (list is List) {
        // Ensure conversion is robust: handles strings or numbers in the list
        return list
            .map((e) => int.tryParse(e.toString()) ?? -1)
            .where((e) => e > 0)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // --- Computed Property ---

  List<Map<String, dynamic>> get _myGroups {
    if (_myGroupIds.isEmpty) return [];
    final ids = Set<int>.from(_myGroupIds);
    return _allGroups
        .where((g) => ids.contains((g['id'] as num?)?.toInt() ?? 0))
        .toList();
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'My Church Groups',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 35,
              color: Colors.white,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }
    if (_myGroups.isEmpty) {
      return _buildEmptyState();
    }
    return _buildGroupsGrid();
  }

  Widget _buildLoadingState() {
    return Center(
      child: SpinKitFadingCircle(
        size: 64,
        duration: const Duration(milliseconds: 1800), // Adjusted duration
        itemBuilder: (context, index) {
          final palette = [
            kPrimaryColor,
            Colors.red,
            Colors.blue,
            Colors.green,
          ];
          return DecoratedBox(
            decoration: BoxDecoration(
              color: palette[index % palette.length],
              shape: BoxShape.circle,
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.redAccent, size: 72),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Loading'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _loadData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Groups Assigned',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You are not currently assigned to any group. If this is unexpected, please contact your church leadership for enrollment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsGrid() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: kPrimaryColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myGroups.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.95, // Slightly taller cards
        ),
        itemBuilder: (context, index) {
          final g = _myGroups[index];
          return _buildGroupCard(g);
        },
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> groupData) {
    final groupId = (groupData['id'] as num?)?.toInt() ?? 0;
    final name = groupData['name'] ?? kDefaultGroupName;
    final description = groupData['description'] ?? kDefaultGroupDescription;

    return InkWell(
      onTap: () {
        if (groupId > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupActivitiesScreen(
                groupId: groupId,
                groupName: name,
                groupDescription: description != kDefaultGroupDescription
                    ? description
                    : null,
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 5,
        shadowColor: kPrimaryColor.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.blue.shade50, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_alt_sharp,
                  color: kPrimaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              // Group Name
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: kPrimaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Group Description
              Expanded(
                child: Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              // Action Indicator
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_right_alt,
                  size: 28,
                  color: kPrimaryColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
