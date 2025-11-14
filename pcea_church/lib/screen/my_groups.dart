import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  bool loading = true;
  String error = '';
  List<Map<String, dynamic>> allGroups = [];
  List<int> myGroupIds = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      await Future.wait([_fetchAllGroups(), _fetchMemberGroups()]);
    } catch (e) {
      error = 'Failed to load groups';
    }
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _fetchAllGroups() async {
    final res = await API().getRequest(
      url: Uri.parse('${Config.baseUrl}/groups'),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if ((body['status'] ?? 400) == 200) {
        allGroups = List<Map<String, dynamic>>.from(body['groups'] as List);
      }
    }
  }

  Future<void> _fetchMemberGroups() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final res = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/members/me'),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if ((body['status'] ?? 400) == 200) {
          final m = (body['member'] ?? {}) as Map<String, dynamic>;
          final groupsJson = (m['groups'] ?? '') as String;
          myGroupIds = _decodeGroupIds(groupsJson);
          await prefs.setString('member_groups_json', groupsJson);
          return;
        }
      }
      // fallback to cache
      final cached = prefs.getString('member_groups_json') ?? '';
      myGroupIds = _decodeGroupIds(cached);
    } catch (_) {
      final cached = prefs.getString('member_groups_json') ?? '';
      myGroupIds = _decodeGroupIds(cached);
    }
  }

  List<int> _decodeGroupIds(String groupsJson) {
    if (groupsJson.isEmpty) return [];
    try {
      final list = jsonDecode(groupsJson);
      if (list is List) {
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

  List<Map<String, dynamic>> get myGroups {
    if (myGroupIds.isEmpty) return [];
    final ids = Set<int>.from(myGroupIds);
    return allGroups
        .where((g) => ids.contains((g['id'] as num).toInt()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'My Church Groups',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh, color: Colors.black87),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? _errorState()
          : myGroups.isEmpty
          ? _emptyState()
          : _groupsGrid(theme),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 12),
            Text(error, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _load,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.groups_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Groups Found',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'You are not assigned to any group yet.\nPlease contact your church leadership for assistance.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupsGrid(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myGroups.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (context, index) {
          final g = myGroups[index];
          final name = g['name'] ?? 'Unnamed Group';
          final description = g['description'] ?? 'No description available';

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening "$name"'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Card(
                elevation: 3,
                shadowColor: Colors.blueAccent.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blueAccent.withOpacity(0.15),
                        radius: 24,
                        child: const Icon(
                          Icons.group,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.blueAccent.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
