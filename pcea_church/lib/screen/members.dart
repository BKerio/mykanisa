import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _congregationName;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _filtered = [];
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    // Debounce search - wait 800ms after user stops typing
    _searchController.addListener(_debouncedSearch);
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController
      ..removeListener(_debouncedSearch)
      ..dispose();
    super.dispose();
  }

  void _debouncedSearch() {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Start new timer
    _searchDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _applyFilter();
      }
    });
  }

  Future<void> _loadMembers({bool useSearch = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Build query parameters - Elder now has full access like admin
      final query = <String, String>{
        'per_page': '100', // Fetch 100 members per page
      };

      // Add search query if provided
      final searchQuery = _searchController.text.trim();
      if (useSearch && searchQuery.isNotEmpty) {
        query['q'] = searchQuery;
      }

      // Build URI for Elder members endpoint (now works like admin)
      final uri = Uri.parse(
        '${Config.baseUrl}/elder/members',
      ).replace(queryParameters: query);

      debugPrint('Fetching members from: $uri');

      final membersRes = await API().getRequest(url: uri);
      debugPrint(
        'Members response ${membersRes.statusCode}: ${membersRes.body}',
      );

      Map<String, dynamic>? body;
      try {
        body = jsonDecode(membersRes.body) as Map<String, dynamic>?;
      } catch (e) {
        debugPrint('Error parsing JSON: $e');
        body = null;
      }

      if (membersRes.statusCode != 200) {
        final message = body?['message']?.toString();
        final fallback =
            'Failed to load members (status ${membersRes.statusCode}).';
        setState(() {
          _error = (message != null && message.isNotEmpty)
              ? '$message (status ${membersRes.statusCode})'
              : fallback;
          _members = [];
          _filtered = [];
        });
        return;
      }

      if (body == null) {
        setState(() {
          _error = 'Unexpected response from server.';
          _members = [];
          _filtered = [];
        });
        return;
      }

      // Handle paginated response (Admin/Elder API format)
      List<Map<String, dynamic>> parsed = [];

      debugPrint('Response body keys: ${body.keys.toList()}');

      // Check if it's a paginated response (Laravel pagination)
      if (body.containsKey('data') && body['data'] is List) {
        // Standard Laravel pagination: { data: [...], current_page: 1, ... }
        parsed = List<Map<String, dynamic>>.from(body['data']);
        debugPrint('Parsed ${parsed.length} members from paginated data');

        // Update congregation name from response if available
        if (parsed.isNotEmpty && parsed.first.containsKey('congregation')) {
          final firstCong = parsed.first['congregation']?.toString();
          if (firstCong != null && firstCong.isNotEmpty) {
            _congregationName = firstCong;
          }
        }
      } else if (body.containsKey('members')) {
        // Fallback: { members: [...] } or { members: { data: [...] } }
        final rawMembers = body['members'];
        if (rawMembers is List) {
          parsed = List<Map<String, dynamic>>.from(rawMembers);
          debugPrint('Parsed ${parsed.length} members from members list');
        } else if (rawMembers is Map<String, dynamic> &&
            rawMembers['data'] is List) {
          parsed = List<Map<String, dynamic>>.from(rawMembers['data']);
          debugPrint('Parsed ${parsed.length} members from members.data');
        }
      } else if (body['status'] == 200 && body.containsKey('data')) {
        // Alternative: { status: 200, data: [...] }
        final rawData = body['data'];
        if (rawData is List) {
          parsed = List<Map<String, dynamic>>.from(rawData);
          debugPrint('Parsed ${parsed.length} members from status.data');
        }
      }

      setState(() {
        _members = parsed;
        _filtered = parsed;
      });

      if (parsed.isEmpty) {
        setState(() {
          _error = useSearch && searchQuery.isNotEmpty
              ? 'No members found matching "$searchQuery".'
              : 'No members found.';
        });
      }
    } catch (e) {
      debugPrint('Error in _loadMembers: $e');
      setState(() {
        _error = 'An error occurred while fetching members: ${e.toString()}';
        _members = [];
        _filtered = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      // If search is cleared, reload all members
      setState(() {
        _filtered = List<Map<String, dynamic>>.from(_members);
      });
      // Optionally reload from server to get all members
      _loadMembers(useSearch: false);
      return;
    }

    // Perform server-side search
    _loadMembers(useSearch: true);
  }

  Future<void> _refresh() => _loadMembers();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF0A1F44),
        title: const Text(
          'Congregation Members',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed: _loadMembers,
            tooltip: 'Refresh',
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: SpinKitFadingCircle(
          size: 64,
          duration: const Duration(milliseconds: 3200),
          itemBuilder: (context, index) {
            final palette = [
              Colors.black,
              const Color(0xFF0A1F44),
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
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),
                onPressed: _loadMembers,
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_outline, size: 72, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _members.isEmpty
                    ? 'No members found yet.'
                    : 'No members match your search. Try a different keyword.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filtered.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_congregationName != null &&
                    _congregationName!.isNotEmpty) ...[
                  Text(
                    'Congregation: $_congregationName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  '${_members.length} member${_members.length != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, child) {
                    return TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: value.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadMembers(useSearch: false);
                                },
                              )
                            : null,
                        hintText: 'Search by name, kanisa number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (searchValue) {
                        _applyFilter();
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            );
          }

          final member = _filtered[index - 1];
          return _MemberTile(member: member);
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Map<String, dynamic> member;

  const _MemberTile({required this.member});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final firstInitial = parts.first[0];
    String secondInitial = '';
    if (parts.length > 1 && parts.last.isNotEmpty) {
      secondInitial = parts.last[0];
    }
    final initials = (firstInitial + secondInitial).toUpperCase();
    return initials.trim().isEmpty ? '?' : initials;
  }

  @override
  Widget build(BuildContext context) {
    final fullName = (member['full_name'] ?? 'Unknown Member').toString();
    final email = (member['email'] ?? '').toString();
    final phone = (member['telephone'] ?? '').toString();
    final eKanisaNumber = (member['e_kanisa_number'] ?? '').toString();
    final role = (member['role'] ?? 'Member').toString();

    // Handle group_names from API (Elder/Admin format)
    final groupNames = member['group_names'];
    final groups = member['groups'];

    final groupText = () {
      // Prefer group_names array from API
      if (groupNames is List) {
        final names = groupNames
            .where((name) => name != null && name.toString().isNotEmpty)
            .map((name) => name.toString())
            .toList();
        if (names.isNotEmpty) return names.join(', ');
      }

      // Fallback to groups field
      if (groups == null) return '';
      if (groups is List) {
        final names = groups
            .map((g) => g is Map ? g['name']?.toString() ?? '' : g.toString())
            .where((name) => name.isNotEmpty)
            .toList();
        return names.join(', ');
      }
      return groups.toString();
    }();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF0A1F44).withOpacity(0.15),
              child: Text(
                _initials(fullName),
                style: const TextStyle(
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
                  // FULL NAME
                  Text(
                    fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ROLE + KANISA NUMBER
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        role,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (eKanisaNumber.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "• ",
                              style: TextStyle(color: Colors.black45),
                            ),
                            const Text(
                              "Kanisa No:",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              eKanisaNumber,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // EMAIL ROW
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            email,
                            overflow: TextOverflow.fade,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // PHONE ROW
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // GROUPS ROW
                  if (groupText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          size: 16,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            groupText,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
