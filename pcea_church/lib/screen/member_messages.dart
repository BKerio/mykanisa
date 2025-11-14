import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/screen/member_send_message.dart';

class MemberMessagesScreen extends StatefulWidget {
  const MemberMessagesScreen({super.key});

  @override
  State<MemberMessagesScreen> createState() => _MemberMessagesScreenState();
}

class _MemberMessagesScreenState extends State<MemberMessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _sentMessages = [];
  bool _isLoading = true;
  bool _isLoadingSent = false;
  String? _error;
  String? _congregation;
  bool _refreshing = false;
  int _unreadCount = 0;
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessages();
    _loadSentMessages();

    // Listen to tab changes to refresh sent messages
    _tabController.addListener(() {
      if (_tabController.index == 1 && _sentMessages.isEmpty) {
        _loadSentMessages();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/member/notifications'),
      );

      if (result.statusCode == 200) {
        final response = jsonDecode(result.body) as Map<String, dynamic>;
        if (response['status'] == 200) {
          // Handle paginated or direct array response
          List<Map<String, dynamic>> messages = [];
          if (response['notifications'] != null) {
            if (response['notifications'] is List) {
              messages = List<Map<String, dynamic>>.from(
                response['notifications'],
              );
            } else if (response['notifications'] is Map &&
                response['notifications']['data'] is List) {
              messages = List<Map<String, dynamic>>.from(
                response['notifications']['data'],
              );
            }
          } else if (response['data'] != null && response['data'] is List) {
            messages = List<Map<String, dynamic>>.from(response['data']);
          }

          setState(() {
            _messages = messages;
            _congregation = response['congregation'];
            _unreadCount = response['unread_count'] ?? 0;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error =
                response['message']?.toString() ?? 'Failed to load messages';
            _isLoading = false;
          });
        }
      } else if (result.statusCode == 404) {
        final response = jsonDecode(result.body) as Map<String, dynamic>?;
        setState(() {
          _error =
              response?['message']?.toString() ??
              'Member record not found. Please contact support.';
          _isLoading = false;
        });
      } else if (result.statusCode == 401) {
        setState(() {
          _error = 'Authentication failed. Please log in again.';
          _isLoading = false;
        });
      } else {
        final response = jsonDecode(result.body) as Map<String, dynamic>?;
        setState(() {
          _error =
              response?['message']?.toString() ??
              'Failed to load messages (Status: ${result.statusCode}). Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() {
        _error = 'Error loading messages: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshMessages() async {
    setState(() {
      _refreshing = true;
    });
    await _loadMessages();
    setState(() {
      _refreshing = false;
    });
  }

  Future<void> _loadSentMessages() async {
    setState(() {
      _isLoadingSent = true;
    });

    try {
      final result = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/member/sent-messages'),
      );

      if (result.statusCode == 200) {
        final response = jsonDecode(result.body) as Map<String, dynamic>;
        if (response['status'] == 200) {
          List<Map<String, dynamic>> messages = [];
          if (response['messages'] != null) {
            if (response['messages'] is List) {
              messages = List<Map<String, dynamic>>.from(response['messages']);
            } else if (response['messages'] is Map &&
                response['messages'].containsKey('data')) {
              messages = List<Map<String, dynamic>>.from(
                response['messages']['data'],
              );
            }
          } else if (response['data'] != null && response['data'] is List) {
            messages = List<Map<String, dynamic>>.from(response['data']);
          }

          setState(() {
            _sentMessages = messages;
            _isLoadingSent = false;
          });
        } else {
          setState(() {
            _sentMessages = [];
            _isLoadingSent = false;
          });
        }
      } else {
        setState(() {
          _sentMessages = [];
          _isLoadingSent = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading sent messages: $e');
      setState(() {
        _sentMessages = [];
        _isLoadingSent = false;
      });
    }
  }

  Future<void> _refreshSentMessages() async {
    await _loadSentMessages();
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

  Future<void> _markAsRead(Map<String, dynamic> message) async {
    // Only mark as read if not already read
    if (message['is_read'] == true) {
      return;
    }

    try {
      final result = await API().postRequest(
        url: Uri.parse(
          '${Config.baseUrl}/member/notifications/${message['id']}/mark-read',
        ),
        data: {},
      );

      final response = jsonDecode(result.body) as Map<String, dynamic>?;

      if (result.statusCode == 200 && response?['status'] == 200) {
        // Update unread count
        setState(() {
          _unreadCount = response?['unread_count'] ?? 0;
          // Update message read status in local list
          final index = _messages.indexWhere((m) => m['id'] == message['id']);
          if (index != -1) {
            _messages[index]['is_read'] = true;
            _messages[index]['read_at'] = DateTime.now().toIso8601String();
          }
        });
      }
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  void _showMessageDetails(Map<String, dynamic> message) {
    // Mark as read when viewing
    _markAsRead(message);

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
                  // Avatar with sender initials
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF0A1F44).withOpacity(0.15),
                    child: Text(
                      _getInitials(message['sender']?['full_name'] ?? 
                                  message['sender'] ?? 
                                  'Church Elder'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A1F44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                                'From: ${message['sender']?['full_name'] ?? message['sender'] ?? 'Church Elder'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: message['type'] == 'broadcast'
                                    ? Colors.blue.shade50
                                    : Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                message['type'] == 'broadcast'
                                    ? 'Broadcast'
                                    : 'Individual',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: message['type'] == 'broadcast'
                                      ? Colors.blue.shade700
                                      : Colors.purple.shade700,
                                ),
                              ),
                            ),
                            if (message['is_priority'] == true)
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
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                        'Replies',
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
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reply['sender']?['full_name'] ?? 'Member',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reply['message'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(reply['created_at']?.toString()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
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
                          _buildDetailRow(
                            Icons.access_time,
                            'Sent',
                            _formatDate(message['created_at']?.toString()),
                          ),
                          if (message['type'] != null) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              message['type'] == 'broadcast'
                                  ? Icons.broadcast_on_personal
                                  : Icons.person,
                              'Type',
                              message['type'] == 'broadcast'
                                  ? 'Broadcast'
                                  : 'Individual',
                            ),
                          ],
                          if (message['is_priority'] == true) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.priority_high,
                              'Priority',
                              'High Priority',
                              isPriority: true,
                            ),
                          ],
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showReplyDialog(message);
                      },
                      icon: const Icon(Icons.reply, color: Color(0xFF0A1F44)),
                      label: const Text(
                        'Reply',
                        style: TextStyle(color: Color(0xFF0A1F44)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF0A1F44)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteMessage(message);
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.red),
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

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isPriority = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isPriority ? Colors.red : const Color(0xFF0A1F44),
        ),
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPriority ? Colors.red : const Color(0xFF0A1F44),
            ),
          ),
        ),
      ],
    );
  }

  void _showReplyDialog(Map<String, dynamic> message) {
    _replyController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Reply to Message',
          style: TextStyle(color: Color(0xFF0A1F44)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Replying to: ${message['title'] ?? 'No Title'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
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
              _sendReply(message);
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

  Future<void> _sendReply(Map<String, dynamic> message) async {
    try {
      final result = await API().postRequest(
        url: Uri.parse(
          '${Config.baseUrl}/member/notifications/${message['id']}/reply',
        ),
        data: {'message': _replyController.text.trim()},
      );

      final response = jsonDecode(result.body) as Map<String, dynamic>;

      if (result.statusCode == 201 && response['status'] == 200) {
        API.showSnack(context, 'Reply sent successfully', success: true);
        _replyController.clear();
        _loadMessages(); // Refresh messages to show the reply
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

  Future<void> _deleteMessage(Map<String, dynamic> message) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Message',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to delete this message? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await API().deleteRequest(
        url: Uri.parse(
          '${Config.baseUrl}/member/notifications/${message['id']}',
        ),
      );

      final response = jsonDecode(result.body) as Map<String, dynamic>?;

      if (result.statusCode == 200 && response?['status'] == 200) {
        API.showSnack(context, 'Message deleted successfully', success: true);
        _loadMessages(); // Refresh messages
      } else {
        API.showSnack(
          context,
          response?['message']?.toString() ?? 'Failed to delete message',
          success: false,
        );
      }
    } catch (e) {
      API.showSnack(
        context,
        'Error deleting message: ${e.toString()}',
        success: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Messages',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: const Color(0xFF0A1F44),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MemberSendMessageScreen(),
                ),
              ).then((_) {
                _loadMessages();
                _loadSentMessages();
              });
            },
            tooltip: 'Message Elder',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _refreshing
                ? null
                : () {
                    if (_tabController.index == 0) {
                      _refreshMessages();
                    } else {
                      _refreshSentMessages();
                    }
                  },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inbox), text: 'Received'),
            Tab(icon: Icon(Icons.send), text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Received Messages Tab
          _buildReceivedMessagesTab(),
          // Sent Messages Tab
          _buildSentMessagesTab(),
        ],
      ),
    );
  }

  Widget _buildReceivedMessagesTab() {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A1F44)),
            ),
          )
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Error Loading Messages',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadMessages,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A1F44),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : _messages.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1F44).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Color(0xFF0A1F44),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Messages',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1F44),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You don\'t have any messages yet.\nCheck back later for updates from your elders.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        : RefreshIndicator(
            onRefresh: _refreshMessages,
            color: const Color(0xFF0A1F44),
            child: Column(
              children: [
                // Info banner
                if (_congregation != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0A1F44).withOpacity(0.1),
                          const Color(0xFF0A1F44).withOpacity(0.05),
                        ],
                      ),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1F44).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.church_rounded,
                            color: Color(0xFF0A1F44),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Congregation',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF0A1F44),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _congregation!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0A1F44),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1F44),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_messages.length} message${_messages.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Messages list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageCard(message);
                    },
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final isPriority = message['is_priority'] == true;
    final isBroadcast = message['type'] == 'broadcast';
    final isRead = message['is_read'] == true;
    final senderName =
        message['sender']?['full_name'] ?? message['sender'] ?? 'Church Elder';
    final senderInitials = _getInitials(senderName);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isRead ? 1 : 3,
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
                : Border.all(
                    color: isRead ? Colors.grey.shade200 : const Color(0xFF0A1F44).withOpacity(0.3),
                    width: isRead ? 1 : 2,
                  ),
            color: isRead ? Colors.white : const Color(0xFF0A1F44).withOpacity(0.02),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with avatar, title, and time
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with sender initials and unread indicator
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF0A1F44).withOpacity(0.15),
                        child: Text(
                          senderInitials,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A1F44),
                          ),
                        ),
                      ),
                      if (!isRead)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Title and badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
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
                        // Sender name
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                senderName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Type and Priority badges
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
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
                            if (isPriority)
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
                        ),
                      ],
                    ),
                  ),
                  // Time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(message['created_at']?.toString()),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Message preview in a container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.message,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Message:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
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
                  ],
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
                    onPressed: () => _deleteMessage(message),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showMessageDetails(message),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0A1F44),
                      side: const BorderSide(color: Color(0xFF0A1F44), width: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
  }

  Widget _buildSentMessagesTab() {
    return RefreshIndicator(
      onRefresh: _refreshSentMessages,
      color: const Color(0xFF0A1F44),
      child: _isLoadingSent
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A1F44)),
              ),
            )
          : _sentMessages.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1F44).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_outlined,
                        size: 64,
                        color: Color(0xFF0A1F44),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Sent Messages',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A1F44),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Messages you send to elders will appear here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const MemberSendMessageScreen(),
                          ),
                        ).then((_) => _loadSentMessages());
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Send New Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1F44),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sentMessages.length,
              itemBuilder: (context, index) {
                final message = _sentMessages[index];
                return _buildSentMessageCard(message);
              },
            ),
    );
  }

  Widget _buildSentMessageCard(Map<String, dynamic> message) {
    final recipientName = message['recipient']?['full_name'] ?? 'Elder';
    final recipientEmail = message['recipient']?['email'] ?? '';
    final hasReplies =
        message['replies'] != null && (message['replies'] as List).isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showSentMessageDetails(message),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasReplies ? Colors.blue.shade200 : Colors.grey.shade200,
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
                      Icons.send,
                      color: Color(0xFF0A1F44),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and recipient
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
                                'To: $recipientName',
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
                        if (recipientEmail.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            recipientEmail,
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
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.reply,
                                size: 10,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${(message['replies'] as List).length} Reply${(message['replies'] as List).length != 1 ? 'ies' : ''}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
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
              // View button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showSentMessageDetails(message),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
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

  void _showSentMessageDetails(Map<String, dynamic> message) {
    final recipientName = message['recipient']?['full_name'] ?? 'Elder';
    final recipientEmail = message['recipient']?['email'] ?? '';
    final recipientPhone = message['recipient']?['telephone'] ?? '';

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
                      Icons.send,
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
                          'To: $recipientName',
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
                    // Replies from elder section
                    if (message['replies'] != null &&
                        (message['replies'] as List).isNotEmpty) ...[
                      const Text(
                        'Replies from Elder',
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
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    reply['sender']?['full_name'] ?? 'Elder',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatDate(
                                      reply['created_at']?.toString(),
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reply['message'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No reply yet from the elder',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
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
                          _buildDetailRow(Icons.person, 'To', recipientName),
                          if (recipientEmail.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.email,
                              'Email',
                              recipientEmail,
                            ),
                          ],
                          if (recipientPhone.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.phone,
                              'Phone',
                              recipientPhone,
                            ),
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
          ],
        ),
      ),
    );
  }
}
