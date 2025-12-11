import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'dart:convert';

class AllChurchGroupsScreen extends StatefulWidget {
  const AllChurchGroupsScreen({super.key});

  @override
  State<AllChurchGroupsScreen> createState() => _AllChurchGroupsScreenState();
}

class _AllChurchGroupsScreenState extends State<AllChurchGroupsScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> groups = [];
  List<int> memberGroupIds = [];
  List<int> pendingRequestIds = [];
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // Fetch all groups
      final groupsRes = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/groups'),
      );

      // Fetch user profile to check membership
      final profileRes = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/members/me'),
      );

      // Fetch pending join requests
      final pendingRes = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/member/groups/my-pending-requests'),
      );

      if (groupsRes.statusCode == 200 && profileRes.statusCode == 200) {
        final groupsBody = jsonDecode(groupsRes.body) as Map<String, dynamic>;
        final profileBody = jsonDecode(profileRes.body) as Map<String, dynamic>;

        if ((groupsBody['status'] ?? 400) == 200 &&
            (profileBody['status'] ?? 400) == 200) {
          final groupsList = List<Map<String, dynamic>>.from(
            groupsBody['groups'],
          );

          // Helper to parse groups from profile
          List<int> myIds = [];
          final member = profileBody['member'];
          if (member['groups'] != null) {
            // Try pivot structure first (from relationship)
            if (member['groups_data'] != null) {
              final gData = member['groups_data'];
              if (gData is List) {
                for (var g in gData) {
                  if (g['id'] != null) myIds.add(g['id']);
                }
              }
            }
            // Try legacy/JSON structure
            try {
              final decoded = jsonDecode(member['groups']);
              if (decoded is List) {
                myIds.addAll(decoded.map((e) => int.parse(e.toString())));
              }
            } catch (e) {
              // Ignore
            }
          }

          // Parse pending requests
          List<int> pendingIds = [];
          if (pendingRes.statusCode == 200) {
            try {
              final pendingBody = jsonDecode(pendingRes.body) as Map<String, dynamic>;
              if ((pendingBody['status'] ?? 400) == 200) {
                final pendingList = pendingBody['pending_group_ids'];
                if (pendingList is List) {
                  pendingIds = pendingList.map((e) => int.parse(e.toString())).toList();
                }
              }
            } catch (e) {
              // Ignore pending requests error, continue with empty list
            }
          }

          setState(() {
            groups = groupsList;
            memberGroupIds = myIds.toSet().toList(); // Unique
            pendingRequestIds = pendingIds;
            loading = false;
          });
          return;
        }
      }

      setState(() {
        error = 'Failed to load groups';
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error: ${e.toString()}';
        loading = false;
      });
    }
  }

  Future<void> _requestJoin(int groupId, String groupName) async {
    const Color primaryColor = Color(0xFF0A1F44);

    final bool? confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, __) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: curved,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 26),
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 6),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.08),
                    ),
                    child: Icon(
                      Icons.group_add_rounded,
                      color: primaryColor,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Join Group',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Do you want to send a request to join "$groupName"? The group leader will be notified.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.35,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 26),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Not now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 6,
                            shadowColor: primaryColor.withOpacity(0.25),
                            backgroundColor: primaryColor,
                          ),
                          child: const Text(
                            'Send Request',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    setState(() => submitting = true);

    try {
      final res = await API().postRequest(
        url: Uri.parse('${Config.baseUrl}/member/groups/join-request'),
        data: {'group_id': groupId},
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && (body['status'] ?? 400) == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(body['message'] ?? 'Request sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload data to get updated pending requests from backend
          _loadData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(body['message'] ?? 'Failed to send request'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        elevation: 2,
        title: Text(
          "All Church Groups",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: loading
          ? Center(
              child: SpinKitFadingCircle(
                size: 64,
                duration: const Duration(
                  milliseconds: 1800,
                ), // Adjusted duration
                itemBuilder: (context, index) {
                  final palette = const [
                    Color(0xFF0A1F44),
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
            )
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : groups.isEmpty
          ? const Center(child: Text('No church groups found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final isMember = memberGroupIds.contains(group['id']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF20BBA6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.groups,
                                color: Color(0xFF0A1F44),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group['name'] ?? 'Unknown Group',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  if (isMember)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(
                                          0xFF0A1F44,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Color(
                                            0xFF0A1F44,
                                          ).withOpacity(0.2),
                                        ),
                                      ),
                                      child: const Text(
                                        'Member',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF0A1F44),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (group['description'] != null &&
                            group['description'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 8),
                            child: Text(
                              group['description'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: isMember
                              ? OutlinedButton.icon(
                                  onPressed: null, // Disabled
                                  icon: const Icon(Icons.check),
                                  label: const Text('Already joined'),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                )
                              : pendingRequestIds.contains(group['id'])
                              ? OutlinedButton.icon(
                                  onPressed: null,
                                  icon: const Icon(Icons.hourglass_empty),
                                  label: const Text('Awaiting Approval'),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: submitting
                                      ? null
                                      : () => _requestJoin(
                                          group['id'],
                                          group['name'],
                                        ),
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Request to Join'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0A1F44),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
