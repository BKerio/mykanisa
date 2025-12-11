import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'dart:convert';

class GroupRequestsScreen extends StatefulWidget {
  const GroupRequestsScreen({super.key});

  @override
  State<GroupRequestsScreen> createState() => _GroupRequestsScreenState();
}

class _GroupRequestsScreenState extends State<GroupRequestsScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> requests = [];
  Set<int> processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/group-leader/join-requests'),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if ((body['status'] ?? 400) == 200) {
          final requestsList = List<Map<String, dynamic>>.from(
            body['requests'] ?? [],
          );

          setState(() {
            requests = requestsList;
            loading = false;
          });
          return;
        }
      }

      setState(() {
        error = 'Failed to load requests';
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error: ${e.toString()}';
        loading = false;
      });
    }
  }

  Future<void> _approveRequest(int requestId, String memberName) async {
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
                      Icons.check_circle_rounded,
                      color: primaryColor,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Approve Request',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Approve $memberName to join this group? They will receive an SMS notification.',
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
                            'Approve the request',
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

    setState(() => processingIds.add(requestId));

    try {
      final res = await API().postRequest(
        url: Uri.parse(
          '${Config.baseUrl}/group-leader/join-requests/$requestId/approve',
        ),
        data: {},
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && (body['status'] ?? 400) == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(body['message'] ?? 'Request approved'),
              backgroundColor: Colors.green,
            ),
          );

          setState(() {
            requests.removeWhere((r) => r['id'] == requestId);
            processingIds.remove(requestId);
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(body['message'] ?? 'Failed to approve'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => processingIds.remove(requestId));
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
        setState(() => processingIds.remove(requestId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          "Join Requests",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: loading
          ? Center(
              child: SpinKitFadingCircle(
                size: 64,
                duration: const Duration(milliseconds: 1800),
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
                    onPressed: _loadRequests,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : requests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: Color(0xFF0A1F44).withOpacity(0.4),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.inbox_rounded,
                      size: 58,
                      color: Color(0xFF0A1F44),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Text(
                    'No Pending Requests',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Everything is clear at the moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadRequests,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  final member = request['member'] as Map<String, dynamic>?;
                  final group = request['group'] as Map<String, dynamic>?;
                  final requestId = request['id'] as int;
                  final isProcessing = processingIds.contains(requestId);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(
                                  0xFF0A1F44,
                                ).withOpacity(0.1),
                                child: Text(
                                  (member?['full_name'] ?? 'M')
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0A1F44),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member?['full_name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      member?['email'] ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.groups,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Wants to join: ${group?['name'] ?? 'Unknown Group'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isProcessing
                                  ? null
                                  : () => _approveRequest(
                                      requestId,
                                      member?['full_name'] ?? 'Member',
                                    ),
                              icon: isProcessing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(Icons.check_circle),
                              label: Text(
                                isProcessing ? 'Approving...' : 'Approve',
                              ),
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
            ),
    );
  }
}
