import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';

class MemberSendMessageScreen extends StatefulWidget {
  const MemberSendMessageScreen({super.key});

  @override
  State<MemberSendMessageScreen> createState() =>
      _MemberSendMessageScreenState();
}

class _MemberSendMessageScreenState extends State<MemberSendMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingElders = false;
  final primaryColor = const Color(0xFF0A1F44);
  List<Map<String, dynamic>> _elders = [];
  List<Map<String, dynamic>> _filteredElders = [];
  int? _selectedElderId;
  String? _selectedElderName;

  @override
  void initState() {
    super.initState();
    _loadElders();
    _searchController.addListener(_filterElders);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadElders() async {
    setState(() {
      _isLoadingElders = true;
    });

    try {
      final result = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/member/elders'),
      );

      if (result.statusCode == 200) {
        final response = jsonDecode(result.body) as Map<String, dynamic>;
        if (response['status'] == 200) {
          final elders = List<Map<String, dynamic>>.from(
            response['elders'] ?? [],
          );
          setState(() {
            _elders = elders;
            _filteredElders = elders;
            _isLoadingElders = false;
          });
        } else {
          setState(() {
            _isLoadingElders = false;
          });
        }
      } else {
        setState(() {
          _isLoadingElders = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingElders = false;
      });
    }
  }

  void _filterElders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredElders = _elders;
      } else {
        _filteredElders = _elders.where((elder) {
          final name = (elder['full_name'] ?? '').toString().toLowerCase();
          final email = (elder['email'] ?? '').toString().toLowerCase();
          final congregation = (elder['congregation'] ?? '')
              .toString()
              .toLowerCase();
          return name.contains(query) ||
              email.contains(query) ||
              congregation.contains(query);
        }).toList();
      }
    });
  }

  void _showElderPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
                            'Select Elder',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_filteredElders.length} elder${_filteredElders.length != 1 ? 's' : ''} available',
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
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search by name, email, or congregation...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Elders list
              Expanded(
                child: _isLoadingElders
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredElders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No elders available'
                                  : 'No elders match "${_searchController.text}"',
                              style: TextStyle(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredElders.length,
                        itemBuilder: (context, index) {
                          final elder = _filteredElders[index];
                          final name =
                              elder['full_name']?.toString() ?? 'Unknown';
                          final email = elder['email']?.toString() ?? '';
                          final congregation =
                              elder['congregation']?.toString() ?? '';
                          final isSelected = _selectedElderId == elder['id'];

                          String _getInitials(String name) {
                            final parts = name.trim().split(RegExp(r'\s+'));
                            if (parts.isEmpty || parts.first.isEmpty)
                              return '?';
                            final firstInitial = parts.first[0];
                            String secondInitial = '';
                            if (parts.length > 1 && parts.last.isNotEmpty) {
                              secondInitial = parts.last[0];
                            }
                            return (firstInitial + secondInitial).toUpperCase();
                          }

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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (email.isNotEmpty)
                                    Text(
                                      email,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (congregation.isNotEmpty)
                                    Text(
                                      congregation,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF0A1F44),
                                    )
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedElderId = elder['id'] as int;
                                  _selectedElderName = name;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedElderId == null) {
      API.showSnack(context, 'Please select an elder', success: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await API().postRequest(
        url: Uri.parse('${Config.baseUrl}/member/send-message-to-elder'),
        data: {
          'elder_id': _selectedElderId,
          'title': _titleController.text.trim(),
          'message': _messageController.text.trim(),
        },
      );

      final response = jsonDecode(result.body) as Map<String, dynamic>;

      if (result.statusCode == 201 && response['status'] == 200) {
        API.showSnack(
          context,
          'Message sent to elder successfully',
          success: true,
        );
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedElderId = null;
          _selectedElderName = null;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 241, 242, 243),
      appBar: AppBar(
        title: const Text(
          'Send a message to Elder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
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
                            'Send Message to Elder',
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
                    Text(
                      'Select an elder and compose your message. The elder will receive an SMS notification.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Elder Selection Field
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: _selectedElderName),
                decoration: InputDecoration(
                  labelText: 'Select Elder *',
                  hintText: 'Tap to select an elder',
                  prefixIcon: const Icon(
                    Icons.person,
                    color: Color(0xFF0A1F44),
                  ),
                  suffixIcon: const Icon(
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
                onTap: _showElderPicker,
                validator: (value) {
                  if (_selectedElderId == null) {
                    return 'Please select an elder';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Subject *',
                  hintText: 'e.g., Question about church service',
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
                  prefixIcon: const Icon(
                    Icons.campaign_rounded,
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
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _sendMessage,
                    child: const Text(
                      "Message your elder",
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
