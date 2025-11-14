import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ElderMessageFormScreen extends StatefulWidget {
  const ElderMessageFormScreen({super.key});

  @override
  State<ElderMessageFormScreen> createState() => _ElderMessageFormScreenState();
}

class _ElderMessageFormScreenState extends State<ElderMessageFormScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _recipientController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingMembers = false;
  bool _isLoadingHistory = false;
  String? _congregation;
  String _messageType = 'broadcast'; // 'broadcast', 'individual', 'group'
  String? _selectedRecipientId;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _messageHistory = [];
  bool _isPriority = false;
  Timer? _searchDebounceTimer;

  List<Map<String, dynamic>> _messagesFromMembers = [];
  bool _isLoadingMemberMessages = false;
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load members directly - Elder has full access
    _loadMembers();
    // Optionally load congregation info for display
    _loadCongregation();
    // Load message history
    _loadMessageHistory();
    // Load messages from members
    _loadMessagesFromMembers();

    // Listen to tab changes to refresh data
    _tabController.addListener(() {
      if (_tabController.index == 1 && _messageHistory.isEmpty) {
        _loadMessageHistory();
      } else if (_tabController.index == 2 && _messagesFromMembers.isEmpty) {
        _loadMessagesFromMembers();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchDebounceTimer?.cancel();
    _titleController.dispose();
    _messageController.dispose();
    _recipientController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadCongregation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? congregationName =
          prefs.getString('congregation_name') ??
          prefs.getString('congregation');
      String? congregationId = prefs.getString('congregation_id');

      if ((congregationName == null || congregationName.isEmpty) &&
          (congregationId == null || congregationId.isEmpty)) {
        final meRes = await API().getRequest(
          url: Uri.parse('${Config.baseUrl}/members/me'),
        );

        if (meRes.statusCode == 200) {
          final body = jsonDecode(meRes.body);
          if (body['status'] == 200 && body['member'] != null) {
            final member = body['member'] as Map<String, dynamic>;
            congregationName = member['congregation']?.toString();
            congregationId = member['congregation_id']?.toString();
            if (congregationName != null && congregationName.isNotEmpty) {
              await prefs.setString('congregation_name', congregationName);
            }
            if (congregationId != null && congregationId.isNotEmpty) {
              await prefs.setString('congregation_id', congregationId);
            }
          }
        }
      }

      setState(() {
        _congregation = congregationName?.trim();
      });
      // Members are loaded independently - no need to wait for congregation
    } catch (e) {
      debugPrint('Error loading congregation: $e');
    }
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoadingMembers = true;
    });

    try {
      // Elder has full access - fetch all members without scope restrictions
      final query = <String, String>{
        'per_page': '500', // Fetch 500 members per page
      };

      final uri = Uri.parse(
        '${Config.baseUrl}/elder/members',
      ).replace(queryParameters: query);

      debugPrint('Loading all members from: $uri');
      final membersRes = await API().getRequest(url: uri);

      if (membersRes.statusCode == 200) {
        Map<String, dynamic>? body;
        try {
          body = jsonDecode(membersRes.body) as Map<String, dynamic>?;
        } catch (e) {
          debugPrint('Error parsing JSON: $e');
          setState(() {
            _members = [];
            _isLoadingMembers = false;
          });
          return;
        }

        if (body != null) {
          List<Map<String, dynamic>> parsed = [];

          // Handle Laravel paginated response format: { data: [...], current_page: 1, ... }
          if (body.containsKey('data') && body['data'] is List) {
            parsed = List<Map<String, dynamic>>.from(body['data']);

            // Try to get congregation name from first member if available
            if (parsed.isNotEmpty && _congregation == null) {
              final firstMember = parsed.first;
              if (firstMember['congregation'] != null) {
                setState(() {
                  _congregation = firstMember['congregation'].toString();
                });
              }
            }
          }
          // Fallback: Handle alternative response formats
          else if (body.containsKey('members')) {
            final rawMembers = body['members'];
            if (rawMembers is List) {
              parsed = List<Map<String, dynamic>>.from(rawMembers);
            } else if (rawMembers is Map<String, dynamic> &&
                rawMembers['data'] is List) {
              parsed = List<Map<String, dynamic>>.from(rawMembers['data']);
            }
          }
          // Alternative: direct data field
          else if (body['status'] == 200 && body.containsKey('data')) {
            if (body['data'] is List) {
              parsed = List<Map<String, dynamic>>.from(body['data']);
            }
          }

          setState(() {
            _members = parsed;
            _isLoadingMembers = false;
          });

          debugPrint('Total members loaded: ${_members.length}');
        } else {
          setState(() {
            _members = [];
            _isLoadingMembers = false;
          });
        }
      } else {
        Map<String, dynamic>? errorBody;
        try {
          errorBody = jsonDecode(membersRes.body) as Map<String, dynamic>?;
        } catch (_) {
          errorBody = null;
        }
        final errorMessage =
            errorBody?['message']?.toString() ??
            'Failed to load members (status ${membersRes.statusCode})';
        debugPrint('Error message: $errorMessage');
        setState(() {
          _members = [];
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading members: $e');
      setState(() {
        _members = [];
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _loadMessageHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final uri = Uri.parse('${Config.baseUrl}/elder/messages');
      final historyRes = await API().getRequest(url: uri);

      if (historyRes.statusCode == 200) {
        final body = jsonDecode(historyRes.body) as Map<String, dynamic>?;

        if (body != null && body['status'] == 200) {
          List<Map<String, dynamic>> announcements = [];

          if (body.containsKey('announcements')) {
            final announcementsData = body['announcements'];
            if (announcementsData is Map &&
                announcementsData.containsKey('data')) {
              announcements = List<Map<String, dynamic>>.from(
                announcementsData['data'],
              );
            } else if (announcementsData is List) {
              announcements = List<Map<String, dynamic>>.from(
                announcementsData,
              );
            }
          } else if (body.containsKey('data')) {
            if (body['data'] is List) {
              announcements = List<Map<String, dynamic>>.from(body['data']);
            }
          }

          setState(() {
            _messageHistory = announcements;
            _isLoadingHistory = false;
          });
        } else {
          setState(() {
            _messageHistory = [];
            _isLoadingHistory = false;
          });
        }
      } else {
        setState(() {
          _messageHistory = [];
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading message history: $e');
      setState(() {
        _messageHistory = [];
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _saveMessage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Elder has full access - congregation not required

    setState(() => _isLoading = true);

    try {
      final messageData = {
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'type': _messageType,
        'is_priority': _isPriority,
        if (_messageType == 'individual' &&
            _selectedRecipientId != null &&
            _selectedRecipientId!.isNotEmpty)
          'recipient_id': _selectedRecipientId,
        if (_messageType == 'individual' &&
            _recipientController.text.trim().isNotEmpty)
          'recipient_phone': _recipientController.text.trim(),
      };

      // Try to save to database first
      final saveResult = await API().postRequest(
        url: Uri.parse('${Config.baseUrl}/elder/messages'),
        data: messageData,
      );

      final saveResponse = jsonDecode(saveResult.body);

      if (saveResult.statusCode == 200 || saveResult.statusCode == 201) {
        if (saveResponse['status'] == 200 || saveResponse['status'] == 201) {
          // Show success message with SMS status
          final smsSent = saveResponse['sms_sent'] ?? false;
          final smsSentCount = saveResponse['sms_sent_count'] ?? 0;
          final message =
              saveResponse['message']?.toString() ??
              'Message saved successfully';

          if (_messageType == 'individual') {
            API.showSnack(context, message, success: smsSent);

            // Clear form
            _titleController.clear();
            _messageController.clear();
            _recipientController.clear();
            _selectedRecipientId = null;
            _isPriority = false;
            _messageType = 'broadcast';

            // Reload history
            _loadMessageHistory();
            // Switch to history tab
            _tabController.animateTo(1);
            return;
          }

          // For broadcast messages - SMS is already sent via store endpoint
          // Show success message with SMS status
          if (_messageType == 'broadcast') {
            // SMS is sent in the store() method, so just show the response message
            API.showSnack(context, message, success: smsSentCount > 0);
          } else {
            // Individual message already handled above
            API.showSnack(
              context,
              message,
              success: smsSent || smsSentCount > 0,
            );
          }

          // Clear form
          _titleController.clear();
          _messageController.clear();
          _recipientController.clear();
          _selectedRecipientId = null;
          _isPriority = false;
          _messageType = 'broadcast';

          // Reload history
          _loadMessageHistory();
          // Switch to history tab
          _tabController.animateTo(1);
        } else {
          API.showSnack(
            context,
            saveResponse['message'] ?? 'Failed to save message',
            success: false,
          );
        }
      } else {
        API.showSnack(
          context,
          saveResponse['message'] ?? 'Failed to save message',
          success: false,
        );
      }
    } catch (e) {
      API.showSnack(
        context,
        'Error saving message: ${e.toString()}',
        success: false,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showRecipientPicker() {
    if (_isLoadingMembers) {
      API.showSnack(context, 'Loading members. Please wait...', success: false);
      return;
    }

    if (_members.isEmpty) {
      // Try to reload members
      _loadMembers();
      API.showSnack(
        context,
        'No members available. Loading members...',
        success: false,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              String searchQuery = '';
              // Filter members that have phone numbers
              final filteredMembers = _members.where((member) {
                // Only show members with phone numbers
                final phone = member['telephone']?.toString().trim() ?? '';
                if (phone.isEmpty) return false;

                if (searchQuery.isEmpty) return true;
                final name = (member['full_name'] ?? '')
                    .toString()
                    .toLowerCase();
                final phoneStr = phone.toLowerCase();
                final query = searchQuery.toLowerCase();
                return name.contains(query) || phoneStr.contains(query);
              }).toList();

              String _getInitials(String name) {
                final parts = name.trim().split(RegExp(r'\s+'));
                if (parts.isEmpty || parts.first.isEmpty) return '?';
                final firstInitial = parts.first[0];
                String secondInitial = '';
                if (parts.length > 1 && parts.last.isNotEmpty) {
                  secondInitial = parts.last[0];
                }
                return (firstInitial + secondInitial).toUpperCase();
              }

              return Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Recipient',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${filteredMembers.length} members with phone',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search by name or phone number...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Members list
                  Expanded(
                    child: filteredMembers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  searchQuery.isEmpty
                                      ? 'No members with phone numbers found'
                                      : 'No members match "$searchQuery"',
                                  style: TextStyle(color: Colors.grey.shade600),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredMembers.length,
                            itemBuilder: (context, index) {
                              final member = filteredMembers[index];
                              final name =
                                  member['full_name']?.toString() ?? 'Unknown';
                              final phone =
                                  member['telephone']?.toString() ?? '';
                              final isSelected =
                                  _selectedRecipientId ==
                                  member['id']?.toString();

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: isSelected ? 4 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFF0A1F44)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(
                                      0xFF0A1F44,
                                    ).withOpacity(0.15),
                                    child: Text(
                                      _getInitials(name),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0A1F44),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: phone.isNotEmpty
                                      ? Row(
                                          children: [
                                            const Icon(
                                              Icons.phone,
                                              size: 14,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              phone,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          'No phone number',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF0A1F44),
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedRecipientId = member['id']
                                          ?.toString();
                                      _recipientController.text = name;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
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
          return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
        }
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  void _showMessageDetails(Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              message['type'] == 'broadcast'
                                  ? 'Broadcast'
                                  : 'Individual',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (message['is_priority'] == true) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.priority_high,
                                size: 14,
                                color: Colors.red,
                              ),
                              Text(
                                'Priority',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message content
                    Text(
                      message['message'] ?? '',
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                    const SizedBox(height: 24),
                    // Details card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1F44).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0A1F44).withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            Icons.access_time,
                            'Sent',
                            _formatDate(message['created_at']?.toString()),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.people,
                            'Target Count',
                            '${message['target_count'] ?? 0} member(s)',
                          ),
                          if (message['recipient'] != null) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.person,
                              'Recipient',
                              message['recipient']['full_name'] ?? 'Unknown',
                            ),
                          ],
                        ],
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0A1F44)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0A1F44),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A1F44),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: 'Create'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.inbox), text: 'From Members'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Create Message Tab
          _buildCreateMessageTab(),
          // Message History Tab
          _buildHistoryTab(),
          // Messages From Members Tab
          _buildMessagesFromMembersTab(),
        ],
      ),
    );
  }

  Widget _buildCreateMessageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modern Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0A1F44).withOpacity(0.1),
                    const Color(0xFF0A1F44).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0A1F44).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1F44).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Color(0xFF0A1F44),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Message Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A1F44),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_congregation != null && _congregation!.isNotEmpty) ...[
                    _buildInfoRow(Icons.church, 'Congregation', _congregation!),
                    const SizedBox(height: 8),
                  ],
                  if (_isLoadingMembers)
                    _buildInfoRow(
                      Icons.hourglass_empty,
                      'Status',
                      'Loading members...',
                    )
                  else if (_members.isNotEmpty)
                    _buildInfoRow(
                      Icons.people,
                      'Available Members',
                      '${_members.length} member${_members.length != 1 ? 's' : ''}',
                    ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.send,
                    'Delivery',
                    _messageType == 'broadcast'
                        ? 'SMS to all members'
                        : 'SMS to selected member',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Message Type Selection
            const Text(
              'Message Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A1F44),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'broadcast',
                    label: Text('Broadcast'),
                    icon: Icon(Icons.broadcast_on_personal),
                  ),
                  ButtonSegment(
                    value: 'individual',
                    label: Text('Individual'),
                    icon: Icon(Icons.person),
                  ),
                ],
                selected: {_messageType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _messageType = newSelection.first;
                    if (_messageType == 'broadcast') {
                      _selectedRecipientId = null;
                      _recipientController.clear();
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Message Title *',
                hintText: 'e.g., Weekly Announcement, Special Event',
                prefixIcon: const Icon(Icons.title, color: Color(0xFF0A1F44)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF0A1F44),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a message title';
                }
                if (value.length > 255) {
                  return 'Title must be less than 255 characters';
                }
                return null;
              },
              maxLength: 255,
            ),
            const SizedBox(height: 16),

            // Recipient Field (for individual messages)
            if (_messageType == 'individual') ...[
              TextFormField(
                controller: _recipientController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Recipient (Member with Phone) *',
                  hintText: _isLoadingMembers
                      ? 'Loading members...'
                      : _members.isEmpty
                      ? 'No members available'
                      : 'Tap to select a member with phone number (${_members.where((m) => m['telephone'] != null && m['telephone'].toString().isNotEmpty).length} with phone)',
                  prefixIcon: _isLoadingMembers
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.phone, color: Color(0xFF0A1F44)),
                  suffixIcon: _isLoadingMembers
                      ? null
                      : _members.isEmpty
                      ? IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadMembers,
                          tooltip: 'Reload members',
                        )
                      : const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF0A1F44),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF0A1F44),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onTap: _isLoadingMembers ? null : _showRecipientPicker,
                validator: (value) {
                  if (_messageType == 'individual' &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Please select a recipient with phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Message Field
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Message *',
                hintText: 'Enter your message...',
                prefixIcon: const Icon(Icons.message, color: Color(0xFF0A1F44)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF0A1F44),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a message';
                }
                return null;
              },
            ),

            // Character Count
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${_messageController.text.length} characters',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Priority Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Priority Message',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Mark this message as high priority'),
                value: _isPriority,
                onChanged: (value) {
                  setState(() {
                    _isPriority = value;
                  });
                },
                secondary: Icon(
                  Icons.priority_high,
                  color: _isPriority ? Colors.red : Colors.grey,
                ),
                activeColor: const Color(0xFF0A1F44),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1F44),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Send Message',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Help Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Messages are saved to the database and sent via SMS. Broadcast messages are sent to all members with phone numbers.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadMessageHistory,
      color: const Color(0xFF0A1F44),
      child: _isLoadingHistory
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A1F44)),
              ),
            )
          : _messageHistory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No Messages Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your message history will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messageHistory.length,
              itemBuilder: (context, index) {
                final message = _messageHistory[index];
                return _buildMessageHistoryCard(message);
              },
            ),
    );
  }

  Widget _buildMessageHistoryCard(Map<String, dynamic> message) {
    final isBroadcast = message['type'] == 'broadcast';
    final isPriority = message['is_priority'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showMessageDetails(message),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isPriority
                ? Border.all(color: Colors.red.shade300, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1F44).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isBroadcast ? Icons.broadcast_on_personal : Icons.person,
                      color: const Color(0xFF0A1F44),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A1F44),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isBroadcast
                                    ? Colors.blue.shade50
                                    : Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isBroadcast ? 'Broadcast' : 'Individual',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isBroadcast
                                      ? Colors.blue.shade700
                                      : Colors.purple.shade700,
                                ),
                              ),
                            ),
                            if (isPriority) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.priority_high,
                                      size: 12,
                                      color: Colors.red.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Priority',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Time
                  Text(
                    _formatDate(message['created_at']?.toString()),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Message preview
              Text(
                message['message'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Stats row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildStatItem(
                      Icons.people,
                      'Targets',
                      '${message['target_count'] ?? 0}',
                    ),
                    const SizedBox(width: 16),
                    if (message['recipient'] != null)
                      _buildStatItem(
                        Icons.person,
                        'Recipient',
                        message['recipient']['full_name'] ?? 'Unknown',
                      ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showMessageDetails(message),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0A1F44),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0A1F44),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0A1F44)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0A1F44),
          ),
        ),
      ],
    );
  }

  Future<void> _loadMessagesFromMembers() async {
    setState(() {
      _isLoadingMemberMessages = true;
    });

    try {
      final uri = Uri.parse('${Config.baseUrl}/elder/messages-from-members');
      final result = await API().getRequest(url: uri);

      if (result.statusCode == 200) {
        final body = jsonDecode(result.body) as Map<String, dynamic>?;

        if (body != null && body['status'] == 200) {
          List<Map<String, dynamic>> messages = [];

          if (body.containsKey('messages')) {
            if (body['messages'] is List) {
              messages = List<Map<String, dynamic>>.from(body['messages']);
            } else if (body['messages'] is Map &&
                body['messages'].containsKey('data')) {
              messages = List<Map<String, dynamic>>.from(
                body['messages']['data'],
              );
            }
          } else if (body.containsKey('data')) {
            if (body['data'] is List) {
              messages = List<Map<String, dynamic>>.from(body['data']);
            }
          }

          setState(() {
            _messagesFromMembers = messages;
            _isLoadingMemberMessages = false;
          });
        } else {
          setState(() {
            _messagesFromMembers = [];
            _isLoadingMemberMessages = false;
          });
        }
      } else {
        setState(() {
          _messagesFromMembers = [];
          _isLoadingMemberMessages = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading messages from members: $e');
      setState(() {
        _messagesFromMembers = [];
        _isLoadingMemberMessages = false;
      });
    }
  }

  void _showReplyDialog(Map<String, dynamic> message) {
    _replyController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Reply to Member',
          style: TextStyle(color: Color(0xFF0A1F44)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Replying to: ${message['sender']?['full_name'] ?? 'Member'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Subject: ${message['title'] ?? 'No Title'}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  labelText: 'Your Reply *',
                  hintText: 'Type your reply here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF0A1F44),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 5,
                maxLength: 5000,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_replyController.text.trim().isEmpty) {
                API.showSnack(
                  context,
                  'Please enter a reply message',
                  success: false,
                );
                return;
              }
              Navigator.pop(context);
              _sendReplyToMember(message);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1F44),
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReplyToMember(Map<String, dynamic> message) async {
    try {
      final result = await API().postRequest(
        url: Uri.parse(
          '${Config.baseUrl}/elder/messages/${message['id']}/reply',
        ),
        data: {'message': _replyController.text.trim()},
      );

      final response = jsonDecode(result.body) as Map<String, dynamic>;

      if (result.statusCode == 201 && response['status'] == 200) {
        API.showSnack(context, 'Reply sent successfully', success: true);
        _replyController.clear();
        _loadMessagesFromMembers(); // Refresh messages
      } else {
        API.showSnack(
          context,
          response['message']?.toString() ?? 'Failed to send reply',
          success: false,
        );
      }
    } catch (e) {
      API.showSnack(
        context,
        'Error sending reply: ${e.toString()}',
        success: false,
      );
    }
  }

  Widget _buildMessagesFromMembersTab() {
    return RefreshIndicator(
      onRefresh: _loadMessagesFromMembers,
      color: const Color(0xFF0A1F44),
      child: _isLoadingMemberMessages
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A1F44)),
              ),
            )
          : _messagesFromMembers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Messages from Members',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1F44),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Messages from members will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messagesFromMembers.length,
              itemBuilder: (context, index) {
                final message = _messagesFromMembers[index];
                return _buildMemberMessageCard(message);
              },
            ),
    );
  }

  Widget _buildMemberMessageCard(Map<String, dynamic> message) {
    final senderName = message['sender']?['full_name'] ?? 'Member';
    final senderEmail = message['sender']?['email'] ?? '';
    final hasReplies =
        message['replies'] != null && (message['replies'] as List).isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showMemberMessageDetails(message),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasReplies ? Colors.green.shade200 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1F44).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF0A1F44),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and sender
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A1F44),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                senderName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (senderEmail.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            senderEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Time and reply badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDate(message['created_at']?.toString()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (hasReplies) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.reply,
                                size: 10,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Replied',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Message preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message['message'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showReplyDialog(message),
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('Reply'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0A1F44),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showMemberMessageDetails(message),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0A1F44),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMemberMessageDetails(Map<String, dynamic> message) {
    final senderName = message['sender']?['full_name'] ?? 'Member';
    final senderEmail = message['sender']?['email'] ?? '';
    final senderPhone = message['sender']?['telephone'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1F44).withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1F44).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF0A1F44),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A1F44),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'From: $senderName',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message content
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        message['message'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Replies section
                    if (message['replies'] != null &&
                        (message['replies'] as List).isNotEmpty) ...[
                      const Text(
                        'Your Replies',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A1F44),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(message['replies'] as List).map(
                        (reply) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(reply['created_at']?.toString()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reply['message'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Details card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1F44).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0A1F44).withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(Icons.person, 'From', senderName),
                          if (senderEmail.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(Icons.email, 'Email', senderEmail),
                          ],
                          if (senderPhone.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(Icons.phone, 'Phone', senderPhone),
                          ],
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.access_time,
                            'Sent',
                            _formatDate(message['created_at']?.toString()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showReplyDialog(message);
                  },
                  icon: const Icon(Icons.reply),
                  label: const Text('Reply to Member'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1F44),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
