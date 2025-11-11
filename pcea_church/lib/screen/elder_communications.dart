import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';

class ElderCommunicationsScreen extends StatefulWidget {
  const ElderCommunicationsScreen({super.key});

  @override
  State<ElderCommunicationsScreen> createState() => _ElderCommunicationsScreenState();
}

class _ElderCommunicationsScreenState extends State<ElderCommunicationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  String? _congregation;
  int? _memberCount;
  
  @override
  void initState() {
    super.initState();
    _loadCongregation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadCongregation() async {
    try {
      final result = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/elder/me'),
      );

      if (result.statusCode == 200) {
        final response = jsonDecode(result.body);
        if (response['status'] == 200) {
          // Try to get congregation from member record
          final memberResult = await API().getRequest(
            url: Uri.parse('${Config.baseUrl}/members/me'),
          );
          
          if (memberResult.statusCode == 200) {
            final memberResponse = jsonDecode(memberResult.body);
            if (memberResponse['status'] == 200 && memberResponse['member'] != null) {
              setState(() {
                _congregation = memberResponse['member']['congregation'];
              });
              _loadMemberCount();
            }
          }
        }
      }
    } catch (e) {
      print('Error loading congregation: $e');
    }
  }

  Future<void> _loadMemberCount() async {
    if (_congregation == null) return;
    
    try {
      final result = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/elder/members?congregation=$_congregation'),
      );

      if (result.statusCode == 200) {
        final response = jsonDecode(result.body);
        if (response['status'] == 200 && response['members'] != null) {
          // Handle paginated response
          if (response['members']['total'] != null) {
            setState(() {
              _memberCount = response['members']['total'] as int;
            });
          } else {
            final members = response['members']['data'] ?? response['members'];
            setState(() {
              _memberCount = members is List ? members.length : 0;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading member count: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_congregation == null) {
      API.showSnack(context, 'Unable to determine your congregation. Please contact support.', success: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await API().postRequest(
        url: Uri.parse('${Config.baseUrl}/elder/communications/broadcast'),
        data: {
          'title': _titleController.text.trim(),
          'message': _messageController.text.trim(),
          'congregation': _congregation,
        },
      );

      final response = jsonDecode(result.body);

      if (result.statusCode == 200 && response['status'] == 200) {
        API.showSnack(
          context,
          'Message sent successfully to ${response['target_count'] ?? _memberCount ?? 0} members!',
          success: true,
        );
        _titleController.clear();
        _messageController.clear();
      } else {
        API.showSnack(
          context,
          response['message'] ?? 'Failed to send message',
          success: false,
        );
      }
    } catch (e) {
      API.showSnack(
        context,
        'Error sending message: ${e.toString()}',
        success: false,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Message to Congregation'),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Broadcast Message',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_congregation != null) ...[
                        Text(
                          'Congregation: $_congregation',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (_memberCount != null) ...[
                        Text(
                          'Recipients: $_memberCount active members',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else if (_congregation != null) ...[
                        const Text(
                          'Loading member count...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Your message will be sent to all active members in your congregation.',
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
              
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Message Title *',
                  hintText: 'e.g., Weekly Announcement, Special Event',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
              
              // Message Field
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Message *',
                  hintText: 'Enter your message to the congregation...',
                  prefixIcon: const Icon(Icons.message),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                onChanged: (value) {
                  setState(() {}); // Update character count
                },
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Send Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Send Message',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Help Text
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber.shade800, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tip: Be clear and concise. Include important details like dates, times, and locations.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
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
      ),
    );
  }
}



