import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pcea_church/screen/base_dashboard.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/screen/group_requests.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:convert';

class GroupLeaderDashboard extends BaseDashboard {
  const GroupLeaderDashboard({super.key});

  @override
  String getRoleTitle() => 'Group Leader';

  @override
  String getRoleDescription() =>
      'Leader of a church group with responsibility for members\' spiritual growth and engagement';

  @override
  List<DashboardCard> getDashboardCards(BuildContext context) {
    return [
      DashboardCard(
        icon: Icons.groups,
        title: 'My Group Members',
        color: Colors.teal,
        subtitle: 'View & manage assigned group',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GroupMembersScreen()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.person_add_alt_1,
        title: 'Members Join Requests',
        color: Colors.teal,
        subtitle: 'Approve member requests',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GroupRequestsScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.campaign_rounded,
        title: 'Group Communication',
        color: Colors.teal,
        subtitle: 'Message group members',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GroupCommunicationScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.event,
        title: 'Group Events',
        color: Colors.teal,
        subtitle: 'Plan activities',
        onTap: () {},
      ),
    ];
  }

  @override
  List<BottomNavigationBarItem> getBottomNavItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.grid_view_rounded),
        label: "Home",
      ),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      BottomNavigationBarItem(icon: Icon(Icons.people), label: "Group"),
      BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
    ];
  }

  @override
  Color getPrimaryColor() => const Color(0xFF20BBA6);

  @override
  Color getSecondaryColor() => const Color(0xFF20BBA6);

  @override
  IconData getRoleIcon() => Icons.supervised_user_circle;
}

// Group Members Screen for Group Leaders
class GroupMembersScreen extends StatefulWidget {
  const GroupMembersScreen({super.key});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? groupInfo;
  List<Map<String, dynamic>> members = [];

  // Multiple groups support
  bool multipleGroups = false;
  List<dynamic> assignedGroups = [];
  int? selectedGroupId;
  bool loadingMembers = false;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // First fetch assigned groups to see if we need to select one
      final res = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/group-leader/assigned-group'),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if ((body['status'] ?? 400) == 200) {
          final isMultiple = body['multiple_groups'] == true;
          final groupsList =
              body['groups'] ?? (body['group'] != null ? [body['group']] : []);

          setState(() {
            multipleGroups = isMultiple;
            assignedGroups = groupsList;
            if (groupsList.isNotEmpty) {
              // Default to first group
              selectedGroupId = groupsList[0]['id'];
            }
            loading = false;
          });

          if (selectedGroupId != null) {
            _loadMembersForGroup(selectedGroupId!);
          }
          return;
        }
      }

      setState(() {
        error = 'Failed to load assigned groups';
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error: ${e.toString()}';
        loading = false;
      });
    }
  }

  Future<void> _loadMembersForGroup(int groupId) async {
    setState(() {
      loadingMembers = true;
    });

    try {
      final res = await API().getRequest(
        url: Uri.parse(
          '${Config.baseUrl}/group-leader/group-members?group_id=$groupId',
        ),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if ((body['status'] ?? 400) == 200) {
          setState(() {
            groupInfo = {
              'group_id': body['group_id'],
              'group_name': body['group_name'],
              'total_members': body['total_members'],
            };
            members = List<Map<String, dynamic>>.from(body['members']);
            loadingMembers = false;
          });
          return;
        }
      }

      setState(() {
        // Don't replace main error, just show snackbar or empty state
        loadingMembers = false;
      });
      if (mounted)
        API.showSnack(
          context,
          'Failed to load members for selected group',
          success: false,
        );
    } catch (e) {
      setState(() {
        loadingMembers = false;
      });
      if (mounted)
        API.showSnack(context, 'Error loading members: $e', success: false);
    }
  }

  void _showGroupPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Select Group',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...assignedGroups.map((group) {
                final isSelected = selectedGroupId == group['id'];
                return ListTile(
                  leading: Icon(
                    Icons.group,
                    color: isSelected ? const Color(0xFF0A1F44) : Colors.grey,
                  ),
                  title: Text(
                    group['name'],
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF0A1F44)
                          : Colors.black,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.groups, color: Color(0xFF0A1F44))
                      : null,
                  onTap: () {
                    setState(() => selectedGroupId = group['id']);
                    _loadMembersForGroup(group['id']);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 6,
        backgroundColor: const Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'My Group Members',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),

      body: Column(
        children: [
          // Group selector (only show if multiple groups)
          if (multipleGroups && assignedGroups.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () => _showGroupPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.groups, color: Color(0xFF0A1F44)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Group',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedGroupId != null
                                  ? assignedGroups.firstWhere(
                                      (g) => g['id'] == selectedGroupId,
                                      orElse: () => {'name': 'Select a group'},
                                    )['name']
                                  : 'Select a group',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded),
                    ],
                  ),
                ),
              ),
            ),

          // Main content
          Expanded(
            child: loading
                ? Center(
                    child: SpinKitFadingCircle(
                      size: 64,
                      duration: const Duration(milliseconds: 1200),
                      itemBuilder: (context, index) {
                        final palette = [
                          Colors.white,
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
                : error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadGroupData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : loadingMembers
                ? Center(
                    child: SpinKitFadingCircle(
                      size: 64,
                      duration: const Duration(milliseconds: 1200),
                      itemBuilder: (context, index) {
                        final palette = [
                          Colors.white,
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
                : groupInfo == null || members.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No members found in this group'),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Group info header
                      if (!multipleGroups) // Only show if not using dropdown (redundant info)
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Color(0xFF0A1F44),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.groups,
                                size: 32,
                                color: Color(0xFF0A1F44),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      groupInfo!['group_name'] ??
                                          'Unknown Group',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${groupInfo!['total_members']} members',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Members list
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final member = members[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),

                                leading: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: const Color(0xFF0A1F44),
                                  child: Text(
                                    (member['full_name'] ?? '?')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),

                                title: Text(
                                  member['full_name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member['e_kanisa_number'] ??
                                          member['email'] ??
                                          '',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),

                                    if (member['telephone'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          member['telephone'],
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Call Icon
                                    IconButton(
                                      icon: const Icon(
                                        Icons.call_rounded,
                                        color: Color(0xFF20BBA6),
                                        size: 26,
                                      ),
                                      onPressed: member['telephone'] != null
                                          ? () {
                                              final phone = member['telephone'];
                                              launchUrl(
                                                Uri.parse('tel:$phone'),
                                              );
                                            }
                                          : null,
                                    ),

                                    // Message Icon
                                    IconButton(
                                      icon: const Icon(
                                        Icons.message_rounded,
                                        color: Color(0xFF0A1F44),
                                        size: 26,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GroupIndividualMessageScreen(
                                                  recipientId: member['id'],
                                                  recipientName:
                                                      member['full_name'],
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// Group Communication Screen for Group Leaders
class GroupCommunicationScreen extends StatefulWidget {
  const GroupCommunicationScreen({super.key});

  @override
  State<GroupCommunicationScreen> createState() =>
      _GroupCommunicationScreenState();
}

class _GroupCommunicationScreenState extends State<GroupCommunicationScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool loading = false;

  // Group selection
  bool fetchingGroups = true;
  bool multipleGroups = false;
  List<dynamic> assignedGroups = [];
  int? selectedGroupId;

  @override
  void initState() {
    super.initState();
    _fetchAssignedGroups();
  }

  Future<void> _fetchAssignedGroups() async {
    try {
      final res = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/group-leader/assigned-group'),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if ((body['status'] ?? 400) == 200) {
          final isMultiple = body['multiple_groups'] == true;
          final groupsList =
              body['groups'] ?? (body['group'] != null ? [body['group']] : []);

          if (mounted) {
            setState(() {
              multipleGroups = isMultiple;
              assignedGroups = groupsList;
              fetchingGroups = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => fetchingGroups = false);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _broadcastMessage() async {
    if (_messageController.text.trim().isEmpty) {
      API.showSnack(context, 'Please enter a message', success: false);
      return;
    }

    setState(() => loading = true);

    try {
      final data = {
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
      };

      if (selectedGroupId != null) {
        data['group_id'] = selectedGroupId.toString();
      }

      final res = await API().postRequest(
        url: Uri.parse('${Config.baseUrl}/group-leader/broadcast-message'),
        data: data,
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if ((body['status'] ?? 400) == 200) {
          API.showSnack(
            context,
            'Message broadcasted to ${body['sent_count']} members',
            success: true,
          );
          _subjectController.clear();
          _messageController.clear();
          // Keep group selection
        } else {
          API.showSnack(
            context,
            body['message'] ?? 'Failed to send message',
            success: false,
          );
        }
      }
    } catch (e) {
      API.showSnack(context, 'Error: ${e.toString()}', success: false);
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Communication'),
        backgroundColor: Color(0xFF0A1F44),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.broadcast_on_personal,
                          color: Color(0xFF0A1F44),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Broadcast Message',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (multipleGroups && assignedGroups.isNotEmpty) ...[
                      DropdownButtonFormField<int?>(
                        value: selectedGroupId,
                        decoration: const InputDecoration(
                          labelText: 'Recipients',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                          helperText:
                              'Select "All My Groups" to broadcast to everyone',
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All My Groups'),
                          ),
                          ...assignedGroups.map<DropdownMenuItem<int?>>((
                            group,
                          ) {
                            return DropdownMenuItem<int?>(
                              value: group['id'],
                              child: Text(group['name']),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() => selectedGroupId = value);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.subject),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _messageController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Message *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        hintText: 'Type your message to group members...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: loading || fetchingGroups
                            ? null
                            : _broadcastMessage,
                        icon: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          loading ? 'Sending...' : 'Broadcast Message',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF20BBA6),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GroupMembersScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.people),
              label: const Text('View All Group Members'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Individual Message Screen
class GroupIndividualMessageScreen extends StatefulWidget {
  final int recipientId;
  final String recipientName;

  const GroupIndividualMessageScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  State<GroupIndividualMessageScreen> createState() =>
      _GroupIndividualMessageScreenState();
}

class _GroupIndividualMessageScreenState
    extends State<GroupIndividualMessageScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      API.showSnack(context, 'Please enter a message', success: false);
      return;
    }

    setState(() => loading = true);

    try {
      final res = await API().postRequest(
        url: Uri.parse('${Config.baseUrl}/group-leader/send-message'),
        data: {
          'recipient_id': widget.recipientId,
          'subject': _subjectController.text.trim(),
          'message': _messageController.text.trim(),
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if ((body['status'] ?? 400) == 200) {
          API.showSnack(context, 'Message sent successfully', success: true);
          Navigator.pop(context);
        } else {
          API.showSnack(
            context,
            body['message'] ?? 'Failed to send message',
            success: false,
          );
        }
      }
    } catch (e) {
      API.showSnack(context, 'Error: ${e.toString()}', success: false);
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Message ${widget.recipientName}'),
        backgroundColor: const Color(0xFF0A1F44),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF0A1F44),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'To:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                widget.recipientName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.subject),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _messageController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Message *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        hintText: 'Type your message...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Loading animation like login screen
                    if (loading)
                      SizedBox(
                        width: double.infinity,
                        height: 70,
                        child: Center(
                          child: SpinKitFadingCircle(
                            size: 108,
                            duration: const Duration(milliseconds: 3200),
                            itemBuilder: (context, index) {
                              final palette = [
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
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send, size: 22),
                          label: const Text(
                            "Send Message",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF20BBA6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
