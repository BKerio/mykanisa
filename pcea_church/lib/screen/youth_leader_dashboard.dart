import 'package:flutter/material.dart';
import 'package:pcea_church/screen/base_dashboard.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'dart:convert';

class YouthLeaderDashboard extends BaseDashboard {
  const YouthLeaderDashboard({super.key});

  @override
  String getRoleTitle() => 'Youth Leader';

  @override
  String getRoleDescription() =>
      'Leader of youth ministry with responsibility for young people\'s spiritual growth and engagement';

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
            MaterialPageRoute(builder: (context) => const YouthGroupMembersScreen()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.message,
        title: 'Group Communication',
        color: Colors.blue,
        subtitle: 'Message group members',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const YouthGroupCommunicationScreen()),
          );
        },
      ),
      DashboardCard(
        icon: Icons.event,
        title: 'Youth Events',
        color: Colors.teal,
        subtitle: 'Plan activities',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const YouthEventsScreen()),
          );
        },
      ),

      DashboardCard(
        icon: Icons.group,
        title: 'Fellowship',
        color: Colors.teal,
        subtitle: 'Build community',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const YouthFellowshipScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.campaign_rounded,
        title: 'Communications',
        color: Colors.teal,
        subtitle: 'Youth updates',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const YouthCommunicationsScreen(),
            ),
          );
        },
      ),
      DashboardCard(
        icon: Icons.account_balance_wallet,
        title: 'Contributions',
        color: Colors.teal,
        subtitle: 'View records',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const YouthContributionsScreen(),
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
      BottomNavigationBarItem(icon: Icon(Icons.people), label: "Youth"),
      BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
    ];
  }

  @override
  Color getPrimaryColor() => const Color(0xFF20BBA6);

  @override
  Color getSecondaryColor() => const Color(0xFF20BBA6);

  @override
  IconData getRoleIcon() => Icons.child_care;
}

// Group Members Screen for Youth Leaders
class YouthGroupMembersScreen extends StatefulWidget {
  const YouthGroupMembersScreen({super.key});

  @override
  State<YouthGroupMembersScreen> createState() => _YouthGroupMembersScreenState();
}

class _YouthGroupMembersScreenState extends State<YouthGroupMembersScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? groupInfo;
  List<Map<String, dynamic>> members = [];

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
  }

  Future<void> _loadGroupMembers() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/youth-leader/group-members'),
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
            loading = false;
          });
          return;
        }
      }
      
      setState(() {
        error = 'Failed to load group members';
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error: ${e.toString()}';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Group Members'),
        backgroundColor: const Color(0xFF20BBA6),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadGroupMembers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : groupInfo == null || members.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No group assigned or no members found'),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Group info header
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: const Color(0xFF20BBA6).withOpacity(0.1),
                          child: Row(
                            children: [
                              const Icon(Icons.groups, size: 32, color: Color(0xFF20BBA6)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      groupInfo!['group_name'] ?? 'Unknown Group',
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
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF20BBA6),
                                    child: Text(
                                      (member['full_name'] ?? '?')[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(member['full_name'] ?? 'Unknown'),
                                  subtitle: Text(
                                    member['e_kanisa_number'] ?? member['email'] ?? '',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.message),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => YouthIndividualMessageScreen(
                                            recipientId: member['id'],
                                            recipientName: member['full_name'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class YouthEventsScreen extends StatelessWidget {
  const YouthEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youth Events'),
        backgroundColor: const Color(0xFFE91E63),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Youth Events',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Plan and organize youth events and activities',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class YouthBibleStudyScreen extends StatelessWidget {
  const YouthBibleStudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youth Bible Study'),
        backgroundColor: const Color(0xFFE91E63),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Youth Bible Study',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Organize and lead youth bible study sessions',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class YouthActivitiesScreen extends StatelessWidget {
  const YouthActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youth Activities'),
        backgroundColor: const Color(0xFFE91E63),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Youth Activities',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Plan recreational and educational activities',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class YouthFellowshipScreen extends StatelessWidget {
  const YouthFellowshipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youth Fellowship'),
        backgroundColor: const Color(0xFFE91E63),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Youth Fellowship',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Build community and fellowship among youth',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Group Communication Screen for Youth Leaders
class YouthGroupCommunicationScreen extends StatefulWidget {
  const YouthGroupCommunicationScreen({super.key});

  @override
  State<YouthGroupCommunicationScreen> createState() => _YouthGroupCommunicationScreenState();
}

class _YouthGroupCommunicationScreenState extends State<YouthGroupCommunicationScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool loading = false;

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
      final res = await API().postRequest(
        url: Uri.parse('${Config.baseUrl}/youth-leader/broadcast-message'),
        data: {
          'subject': _subjectController.text.trim(),
          'message': _messageController.text.trim(),
        },
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
        } else {
          API.showSnack(context, body['message'] ?? 'Failed to send message', success: false);
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
        backgroundColor: const Color(0xFF20BBA6),
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
                        Icon(Icons.broadcast_on_personal, color: Color(0xFF20BBA6)),
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
                        hintText: 'Type your message to all group members...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : _broadcastMessage,
                        icon: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(loading ? 'Sending...' : 'Broadcast to All Members'),
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
                    builder: (context) => const YouthGroupMembersScreen(),
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
class YouthIndividualMessageScreen extends StatefulWidget {
  final int recipientId;
  final String recipientName;

  const YouthIndividualMessageScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  State<YouthIndividualMessageScreen> createState() => _YouthIndividualMessageScreenState();
}

class _YouthIndividualMessageScreenState extends State<YouthIndividualMessageScreen> {
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
        url: Uri.parse('${Config.baseUrl}/youth-leader/send-message'),
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
          API.showSnack(context, body['message'] ?? 'Failed to send message', success: false);
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
        backgroundColor: const Color(0xFF20BBA6),
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
                          backgroundColor: Color(0xFF20BBA6),
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
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : _sendMessage,
                        icon: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(loading ? 'Sending...' : 'Send Message'),
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
          ],
        ),
      ),
    );
  }
}

// Placeholder screens for other functionality
class YouthCommunicationsScreen extends StatelessWidget {
  const YouthCommunicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youth Communications'),
        backgroundColor: const Color(0xFFE91E63),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Youth Communications',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Communicate with youth members and parents',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class YouthContributionsScreen extends StatelessWidget {
  const YouthContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contributions'),
        backgroundColor: const Color(0xFFE91E63),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Contributions',
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

class YouthMinistryScreen extends StatelessWidget {
  const YouthMinistryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Youth Ministry'),
        backgroundColor: const Color(0xFFE91E63),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Youth Ministry',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Oversee youth ministry activities and programs',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
