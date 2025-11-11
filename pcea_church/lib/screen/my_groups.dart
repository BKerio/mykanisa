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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 241, 242, 243),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'My Church Groups',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent),
                  const SizedBox(height: 8),
                  Text(error),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : myGroups.isEmpty
          ? _emptyState()
          : _groupsList(),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.group_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('You are not assigned to any group yet.'),
            SizedBox(height: 4),
            Text(
              'Please contact your church leadership for assignment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: myGroups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final g = myGroups[i];
        return Card(
          elevation: 1,
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.group)),
            title: Text((g['name'] ?? '') as String),
            subtitle: Text(
              ((g['description'] ?? '') as String).isEmpty
                  ? '—'
                  : (g['description'] as String),
            ),
          ),
        );
      },
    );
  }
}
