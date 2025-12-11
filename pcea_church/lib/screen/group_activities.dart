import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/screen/member_group_leader_message.dart';
import 'package:pcea_church/screen/group_leader_dashboard.dart';

class GroupActivitiesScreen extends StatefulWidget {
  final int groupId;
  final String groupName;
  final String? groupDescription;

  const GroupActivitiesScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupDescription,
  });

  @override
  State<GroupActivitiesScreen> createState() => _GroupActivitiesScreenState();
}

class _GroupActivitiesScreenState extends State<GroupActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _groupData;
  bool _isLeader = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    ); // Default to 3 tabs (Info, Leader, Messages)
    _loadGroupActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupActivities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/groups/${widget.groupId}/activities'),
      );

      if (result.statusCode == 200) {
        final response = jsonDecode(result.body) as Map<String, dynamic>;
        if (response['status'] == 200) {
          final isLeader = response['is_leader'] ?? false;

          // Update tab controller based on whether user is leader
          final tabCount = isLeader ? 4 : 3;
          if (_tabController.length != tabCount) {
            _tabController.dispose();
            _tabController = TabController(length: tabCount, vsync: this);
          }

          setState(() {
            _groupData = response;
            _isLeader = isLeader;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error =
                response['message']?.toString() ??
                'Failed to load group activities';
            _isLoading = false;
          });
        }
      } else {
        final response = jsonDecode(result.body) as Map<String, dynamic>;
        setState(() {
          _error =
              response['message']?.toString() ??
              'Failed to load group activities';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading group activities: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final firstInitial = parts.first[0].toUpperCase();
    String secondInitial = '';
    if (parts.length > 1 && parts.last.isNotEmpty) {
      secondInitial = parts.last[0].toUpperCase();
    }
    return firstInitial + secondInitial;
  }

  /// Builds a full image URL for a leader, supporting both relative and absolute paths.
  String? _getLeaderImageUrl(Map<String, dynamic> leader) {
    final raw = (leader['profile_image_url'] ?? leader['profile_image'])
        ?.toString()
        .trim();
    if (raw == null || raw.isEmpty) return null;

    // If already an absolute URL, return as-is.
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    // Otherwise, treat as a relative path and prepend the base URL (without /api).
    final base = Config.baseUrl.replaceAll('/api', '');
    if (raw.startsWith('/')) {
      return '$base$raw';
    }
    return '$base/$raw';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now';
          }
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d, y').format(date);
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.groupName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              if (widget.groupDescription != null)
                Text(
                  widget.groupDescription!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),

        bottom: _isLoading || _error != null
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.orange,
                unselectedLabelColor: Colors.white70,

                tabs: _isLeader
                    ? const [
                        Tab(
                          icon: Icon(Icons.info_outline, size: 30),
                          text: 'Group Info',
                        ),
                        Tab(
                          icon: Icon(Icons.people, size: 30),
                          text: 'Members',
                        ),
                        Tab(icon: Icon(Icons.person, size: 30), text: 'Leader'),
                        Tab(
                          icon: Icon(Icons.campaign, size: 30),
                          text: 'Messages',
                        ),
                      ]
                    : const [
                        Tab(
                          icon: Icon(Icons.info_outline, size: 30),
                          text: 'Group Info',
                        ),
                        Tab(
                          icon: Icon(Icons.person, size: 30),
                          text: 'Group Leader',
                        ),
                        Tab(
                          icon: Icon(Icons.campaign, size: 30),
                          text: 'Messages',
                        ),
                      ],
              ),

        actions: [
          IconButton(
            onPressed: _loadGroupActivities,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 35,
              color: Colors.white,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),

      body: _isLoading
          ? Center(
              child: SpinKitFadingCircle(
                size: 64,
                duration: const Duration(milliseconds: 3200),
                itemBuilder: (context, index) {
                  const palette = [
                    Colors.black,
                    Color(0xFF0A1F44),
                    Colors.red,
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
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF0A1F44),
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'We couldn’t load details for this group right now.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A1F44),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'It may be that no information has been added yet, or there was a small connection issue.',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, size: 35),
                      label: const Text(
                        'Try Again, Please',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1F44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _loadGroupActivities,
                    ),
                  ],
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: _isLeader
                  ? [
                      _buildInfoTab(),
                      _buildMembersTab(),
                      _buildLeaderTab(),
                      _buildMessagesTab(),
                    ]
                  : [_buildInfoTab(), _buildLeaderTab(), _buildMessagesTab()],
            ),
    );
  }

  Widget _buildInfoTab() {
    final group = _groupData?['group'] as Map<String, dynamic>? ?? {};
    final memberCount = _groupData?['member_count'] ?? 0;
    final groupLeader = _groupData?['group_leader'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Info Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1F44).withOpacity(0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: Color(0xFF0A1F44),
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group['name']?.toString() ?? widget.groupName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0A1F44),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),

                            if (_isLeader)
                              Text(
                                '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (group['description'] != null &&
                      group['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade300, thickness: 1),
                    const SizedBox(height: 14),

                    Text(
                      group['description'].toString(),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.55,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Statistics - Only show member count to leaders
          _isLeader
              ? Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Members',
                        memberCount.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Leader',
                        groupLeader != null ? 'Assigned' : 'None',
                        Icons.person,
                        Color(0xFF0A1F44),
                      ),
                    ),
                  ],
                )
              : _buildStatCard(
                  'Group Leader',
                  groupLeader != null ? 'Assigned' : 'None',
                  Icons.person,
                  Color(0xFF0A1F44),
                ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    final members = _groupData?['members'] as List<dynamic>? ?? [];
    final memberCount = _groupData?['member_count'] ?? 0;

    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No members found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$memberCount ${memberCount == 1 ? 'Member' : 'Members'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1F44),
                ),
              ),
              if (_isLeader)
                ElevatedButton.icon(
                  icon: const Icon(Icons.broadcast_on_personal, size: 18),
                  label: const Text('Broadcast Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1F44),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const GroupCommunicationScreen(),
                      ),
                    ).then(
                      (_) => _loadGroupActivities(),
                    ); // Refresh after sending
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index] as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0A1F44).withOpacity(0.15),
                    backgroundImage: member['profile_image'] != null
                        ? NetworkImage(
                            '${Config.baseUrl}/${member['profile_image']}',
                          )
                        : null,
                    child: member['profile_image'] == null
                        ? Text(
                            _getInitials(member['full_name']?.toString()),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A1F44),
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    member['full_name']?.toString() ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (member['email'] != null)
                        Text(member['email'].toString()),
                      if (member['telephone'] != null)
                        Text(member['telephone'].toString()),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (member['role'] != null &&
                          member['role'].toString() != 'member')
                        Chip(
                          label: Text(
                            member['role'].toString().replaceAll('_', ' '),
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: const Color(
                            0xFF0A1F44,
                          ).withOpacity(0.1),
                        ),
                      if (_isLeader)
                        IconButton(
                          icon: const Icon(
                            Icons.message,
                            color: Color(0xFF0A1F44),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    GroupIndividualMessageScreen(
                                      recipientId: member['id'] as int,
                                      recipientName:
                                          member['full_name']?.toString() ??
                                          'Unknown',
                                    ),
                              ),
                            );
                          },
                          tooltip: 'Send Message',
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderTab() {
    final groupLeader = _groupData?['group_leader'] as Map<String, dynamic>?;

    if (groupLeader == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No Group Leader Assigned',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This group does not have a youth leader assigned yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Group Leader Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Column(
                children: [
                  Builder(
                    builder: (context) {
                      final imageUrl = _getLeaderImageUrl(groupLeader);
                      return CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color(
                          0xFF0A1F44,
                        ).withOpacity(0.1),
                        backgroundImage: imageUrl != null
                            ? NetworkImage(imageUrl)
                            : null,
                        child: imageUrl == null
                            ? Text(
                                _getInitials(
                                  groupLeader['full_name']?.toString(),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0A1F44),
                                  fontSize: 34,
                                ),
                              )
                            : null,
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  Text(
                    groupLeader['full_name']?.toString() ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A1F44),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Chip(
                    label: const Text('Group Leader'),
                    backgroundColor: const Color(0xFF0A1F44).withOpacity(0.12),
                    labelStyle: const TextStyle(
                      color: Color(0xFF0A1F44),
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  if (groupLeader['email'] != null) ...[
                    const SizedBox(height: 20),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF0A1F44),
                      ),
                      title: Text(
                        groupLeader['email'].toString(),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],

                  if (groupLeader['telephone'] != null)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.phone_outlined,
                        color: Color(0xFF0A1F44),
                      ),
                      title: Text(
                        groupLeader['telephone'].toString(),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Message Group Leader'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1F44),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const MemberGroupLeaderMessageScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    final announcements = _groupData?['announcements'] as List<dynamic>? ?? [];

    if (announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Messages Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Group announcements and messages will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        final announcement = announcements[index] as Map<String, dynamic>;
        final sender = announcement['sender'] as Map<String, dynamic>?;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(
                        0xFF0A1F44,
                      ).withOpacity(0.15),
                      backgroundImage: sender?['profile_image'] != null
                          ? NetworkImage(
                              '${Config.baseUrl}/storage/${sender!['profile_image']}',
                            )
                          : null,
                      child: sender?['profile_image'] == null
                          ? Text(
                              _getInitials(sender?['full_name']?.toString()),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A1F44),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sender?['full_name']?.toString() ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatDate(announcement['created_at']?.toString()),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  announcement['title']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1F44),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  announcement['message']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
