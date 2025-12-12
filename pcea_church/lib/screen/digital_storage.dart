import 'package:flutter/material.dart';
import 'package:pcea_church/config/server.dart';
import 'dart:convert';
import '../method/api.dart';
import 'package:intl/intl.dart';

class MemberDigitalFileScreen extends StatefulWidget {
  const MemberDigitalFileScreen({super.key});

  @override
  State<MemberDigitalFileScreen> createState() =>
      _MemberDigitalFileScreenState();
}

class _MemberDigitalFileScreenState extends State<MemberDigitalFileScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _digitalFile;
  TabController? _tabController;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
    ); // Profile, Family, Attendance, Finance, Tasks, Logs
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchMember(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _digitalFile = null;
    });

    try {
      // First, find the member. If query is numeric, assume ID or E-Kanisa No.
      // Ideally we need an endpoint to search first, THEN get details.
      // For now, I'll leverage the existing 'members' list endpoint or a search,
      // but to save specific calls, I will try to fetch by ID if possible or assume query is E-Kanisa Number which is unique.
      // But the backend `getDigitalFile` expects an ID.
      // So I need to FIND the ID first.

      // I'll search for the member first using existing MemberController::index logic or similar if available for searching.
      // The `AdminMembersController::index` allows filtering.
      // Let's assume the user picks from a list in a real scenario, but here I'll try to find by query.

      // Hack: I'll use the getAllMembers endpoint and filter locally or use a search param if available.
      // Backend route: GET /api/elder/members

      final searchRes = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/elder/members?q=$query'),
        //requireAuth: true,
      );

      if (searchRes.statusCode == 200) {
        final data = jsonDecode(searchRes.body);
        // Laravel paginate response has 'data' key at root, or sometimes wrapped.
        // MembersController returns query->paginate() directly.
        final members = data['data'];

        if (members != null && (members as List).isNotEmpty) {
          // Take the first match
          final memberId = members[0]['id'];
          await _fetchDigitalFile(memberId);
        } else {
          _showError('No member found matching "$query"');
        }
      } else {
        _showError('Search failed');
      }
    } catch (e) {
      _showError('Error searching member: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDigitalFile(int id) async {
    try {
      final response = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/elder/members/$id/digital-file'),
        //requireAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _digitalFile = data['data'];
        });
      } else {
        _showError('Failed to load digital file');
      }
    } catch (e) {
      _showError('Error fetching digital file: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Digital File'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Phone or ID',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                    ),
                    onSubmitted: _searchMember,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _searchMember(_searchController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_digitalFile != null)
            Expanded(child: _buildFileContent())
          else
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_shared, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Search for a member to view their digital file',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileContent() {
    final profile = _digitalFile!['profile'];

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: profile['profile_image_url'] != null
                    ? NetworkImage(profile['profile_image_url'])
                    : null,
                child: profile['profile_image_url'] == null
                    ? Text(
                        (profile['full_name'] ?? profile['name'] ?? '?')
                            .toString()[0]
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile['full_name'] ??
                          profile['name'] ??
                          'Unknown Member',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      profile['e_kanisa_number'] ?? 'No Number',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      profile['email'] ?? '',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tabs
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Family'),
            Tab(text: 'Attendance'),
            Tab(text: 'Finance'),
            Tab(text: 'Tasks'),
            Tab(text: 'Logs'),
          ],
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(),
              _buildFamilyTab(),
              _buildAttendanceTab(),
              _buildFinanceTab(),
              _buildTasksTab(),
              _buildLogsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    final p = _digitalFile!['profile'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoTile('Phone', p['telephone']),
        _infoTile(
          'National ID',
          p['id_number'] ?? p['national_id'],
        ), // Handle inconsistent naming if any
        _infoTile(
          'Date of Birth',
          p['dob'] ?? p['pk_dob'] ?? p['date_of_birth'] ?? '-',
        ),
        _infoTile('Gender', p['gender']),
        _infoTile('Marital Status', p['marital_status']),
        const Divider(),
        _infoTile(
          'Baptized',
          (p['is_baptized'] == true ||
                  p['is_baptized'] == 1 ||
                  p['is_baptized'] == '1')
              ? 'Yes'
              : 'No',
        ),
        _infoTile(
          'Holy Communion',
          (p['takes_holy_communion'] == true ||
                  p['takes_holy_communion'] == 1 ||
                  p['takes_holy_communion'] == '1')
              ? 'Yes'
              : 'No',
        ),
        const Divider(),
        _infoTile('District', p['district']),
        _infoTile('Congregation', p['congregation']),
        _infoTile('Parish', p['parish']),
      ],
    );
  }

  Widget _infoTile(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyTab() {
    final deps = _digitalFile!['profile']['dependencies'] as List?;
    if (deps == null || deps.isEmpty)
      return const Center(child: Text('No dependents listed'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deps.length,
      itemBuilder: (context, index) {
        final d = deps[index];
        final photoUrls = d['photo_urls'] as List?;
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.person, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text('Birth Year: ${d['year_of_birth']}'),
                        ],
                      ),
                    ),
                  ],
                ),
                if (photoUrls != null && photoUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photoUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, pIndex) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            photoUrls[pIndex],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTab() {
    final att = _digitalFile!['attendances'] as List?;
    final meetAtt = _digitalFile!['meeting_attendance'] as List?;

    if ((att == null || att.isEmpty) && (meetAtt == null || meetAtt.isEmpty)) {
      return const Center(child: Text('No attendance records found'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (att != null && att.isNotEmpty) ...[
          const Text(
            'Regular Services',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...att.map(
            (a) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available, color: Colors.green),
              title: Text(a['event_type'] ?? 'Service'),
              subtitle: Text(
                _dateFormat.format(DateTime.parse(a['event_date'])),
              ),
            ),
          ),
          const Divider(),
        ],
        if (meetAtt != null && meetAtt.isNotEmpty) ...[
          const Text(
            'Meeting Attendance',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...meetAtt.map(
            (m) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.meeting_room, color: Colors.blue),
              title: Text(m['title']),
              subtitle: Text(
                '${m['meeting_type']} • ${_dateFormat.format(DateTime.parse(m['meeting_date']))}',
              ),
              trailing: Chip(
                label: Text(m['status']),
                backgroundColor: m['status'] == 'present'
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                labelStyle: TextStyle(
                  color: m['status'] == 'present' ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFinanceTab() {
    final conts = _digitalFile!['contributions'] as List?;
    if (conts == null || conts.isEmpty)
      return const Center(child: Text('No contribution history'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conts.length,
      itemBuilder: (context, index) {
        final c = conts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.teal,
              child: Icon(Icons.attach_money, color: Colors.white),
            ),
            title: Text(c['contribution_type'].toString().toUpperCase()),
            subtitle: Text(
              _dateFormat.format(DateTime.parse(c['contribution_date'])),
            ),
            trailing: Text(
              'KES ${c['amount']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                fontSize: 15,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTasksTab() {
    final tasks = _digitalFile!['tasks'] as List?;
    if (tasks == null || tasks.isEmpty)
      return const Center(child: Text('No action items assigned'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final t = tasks[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        t['meeting_title'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: t['status'] == 'Done'
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        t['status'],
                        style: TextStyle(
                          fontSize: 10,
                          color: t['status'] == 'Done'
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(t['description'], style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 8),
                if (t['due_date'] != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${_dateFormat.format(DateTime.parse(t['due_date']))}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogsTab() {
    final logs = _digitalFile!['audit_logs'] as List?;
    if (logs == null || logs.isEmpty)
      return const Center(child: Text('No activity logs found'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final l = logs[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history, size: 20),
          title: Text(l['action'] ?? 'Activity'),
          subtitle: Text(
            '${l['details'] ?? ''}\n${_dateFormat.format(DateTime.parse(l['created_at']))}',
          ),
          isThreeLine: true,
        );
      },
    );
  }
}
