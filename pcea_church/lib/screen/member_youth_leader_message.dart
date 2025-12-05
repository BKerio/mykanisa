import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';

class MemberYouthLeaderMessageScreen extends StatefulWidget {
  const MemberYouthLeaderMessageScreen({super.key});

  @override
  State<MemberYouthLeaderMessageScreen> createState() =>
      _MemberYouthLeaderMessageScreenState();
}

class _MemberYouthLeaderMessageScreenState
    extends State<MemberYouthLeaderMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingLeader = true;
  Map<String, dynamic>? _youthLeader;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadYouthLeader();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadYouthLeader() async {
    setState(() {
      _isLoadingLeader = true;
      _error = null;
    });

    try {
      final result = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/members/my-youth-leader'),
      );

      if (result.statusCode == 200) {
        final response = jsonDecode(result.body) as Map<String, dynamic>;
        if (response['status'] == 200 && response['youth_leader'] != null) {
          setState(() {
            _youthLeader = response['youth_leader'] as Map<String, dynamic>;
            _isLoadingLeader = false;
          });
        } else {
          setState(() {
            _error = response['message']?.toString() ??
                'No youth leader assigned to your group';
            _isLoadingLeader = false;
          });
        }
      } else {
        final response = jsonDecode(result.body) as Map<String, dynamic>;
        setState(() {
          _error = response['message']?.toString() ??
              'Failed to load youth leader information';
          _isLoadingLeader = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading youth leader: ${e.toString()}';
        _isLoadingLeader = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_youthLeader == null) {
      API.showSnack(
        context,
        'Youth leader information not available',
        success: false,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await API().postRequest(
        url: Uri.parse('${Config.baseUrl}/member/send-message-to-youth-leader'),
        data: {
          'youth_leader_id': _youthLeader!['id'],
          'title': _titleController.text.trim(),
          'message': _messageController.text.trim(),
        },
      );

      final response = jsonDecode(result.body) as Map<String, dynamic>;

      if ((result.statusCode == 201 || result.statusCode == 200) &&
          response['status'] == 200) {
        API.showSnack(
          context,
          'Message sent to youth leader successfully',
          success: true,
        );
        _titleController.clear();
        _messageController.clear();
        Navigator.pop(context);
      } else {
        API.showSnack(
          context,
          response['message']?.toString() ?? 'Failed to send message',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 242, 243),
      appBar: AppBar(
        title: const Text(
          'Message Youth Leader',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingLeader
          ? const Center(child: CircularProgressIndicator())
          : _error != null || _youthLeader == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
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
                          _error ?? 'No Youth Leader Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You don\'t have a youth leader assigned to your group yet.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadYouthLeader,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A1F44),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Youth Leader Info Card
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
                          child: Row(
                            children: [
                              Builder(
                                builder: (context) {
                                  final raw =
                                      (_youthLeader!['profile_image_url'] ??
                                              _youthLeader!['profile_image'])
                                          ?.toString()
                                          .trim();
                                  String? imageUrl;
                                  if (raw != null && raw.isNotEmpty) {
                                    if (raw.startsWith('http://') ||
                                        raw.startsWith('https://')) {
                                      imageUrl = raw;
                                    } else {
                                      final base =
                                          Config.baseUrl.replaceAll('/api', '');
                                      imageUrl =
                                          raw.startsWith('/') ? '$base$raw' : '$base/$raw';
                                    }
                                  }

                                  return CircleAvatar(
                                    radius: 30,
                                    backgroundColor:
                                        const Color(0xFF0A1F44).withOpacity(0.15),
                                    backgroundImage: imageUrl != null
                                        ? NetworkImage(imageUrl)
                                        : null,
                                    child: imageUrl == null
                                        ? Text(
                                            _getInitials(_youthLeader!['full_name']
                                                ?.toString()),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0A1F44),
                                              fontSize: 20,
                                            ),
                                          )
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _youthLeader!['full_name']?.toString() ??
                                          'Unknown',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0A1F44),
                                      ),
                                    ),
                                    if (_youthLeader!['assigned_group'] != null)
                                      Text(
                                        _youthLeader!['assigned_group']['name']
                                                ?.toString() ??
                                            '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    if (_youthLeader!['telephone'] != null)
                                      Text(
                                        _youthLeader!['telephone']?.toString() ??
                                            '',
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
                        ),
                        const SizedBox(height: 24),

                        // Title Field
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Subject *',
                            hintText: 'e.g., Question about group activities',
                            prefixIcon: const Icon(Icons.title,
                                color: Color(0xFF0A1F44)),
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
                              return 'Please enter a subject';
                            }
                            if (value.length > 255) {
                              return 'Subject must be less than 255 characters';
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
                            hintText: 'Type your message here...',
                            prefixIcon: const Icon(Icons.message,
                                color: Color(0xFF0A1F44)),
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
                          maxLength: 5000,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a message';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Send Button
                        if (_isLoading)
                          SizedBox(
                            width: double.infinity,
                            height: 70,
                            child: Center(
                              child: SpinKitFadingCircle(
                                size: 108,
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
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A1F44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _sendMessage,
                              child: const Text(
                                "Send Message",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
    );
  }
}

