import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';

class MinutesListPage extends StatefulWidget {
  const MinutesListPage({super.key});

  @override
  State<MinutesListPage> createState() => _MinutesListPageState();
}

class _MinutesListPageState extends State<MinutesListPage> {
  final List<Map<String, dynamic>> _minutes = [];
  bool _loading = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetchMinutes();
  }

  Future<void> _fetchMinutes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      print('Fetching minutes from: ${Config.baseUrl}/minutes/mine');
      final res = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/minutes/mine'),
      );
      
      print('Response status: ${res.statusCode}');
      print('Response body: ${res.body}');
      
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        print('=== MINUTES FETCH DEBUG ===');
        print('Response type: ${body.runtimeType}');
        print('Full response: $body');
        
        List<Map<String, dynamic>> data = [];
        
        if (body is Map) {
          print('Response is a Map with keys: ${body.keys.toList()}');
          
          // Check all possible keys that might contain the minutes array
          final possibleKeys = ['minutes', 'data', 'results', 'items', 'meetings', 'records'];
          for (final key in possibleKeys) {
            if (body.containsKey(key)) {
              print('Found key "$key" with value: ${body[key]}');
              final minutesData = body[key];
              if (minutesData is List) {
                print('Key "$key" contains a List with ${minutesData.length} items');
                data = List<Map<String, dynamic>>.from(minutesData);
                break;
              } else if (minutesData is Map) {
                print('Key "$key" contains a single Map, wrapping in list');
                data = [Map<String, dynamic>.from(minutesData)];
                break;
              }
            }
          }
          
          // If no array found, maybe the response itself is the minutes data
          if (data.isEmpty && body.isNotEmpty) {
            print('No array found, treating entire response as single minute');
            data = [Map<String, dynamic>.from(body)];
          }
        } else if (body is List) {
          print('Response is directly a List with ${body.length} items');
          data = List<Map<String, dynamic>>.from(body);
        }
        
        print('Final parsed data: $data');
        print('Number of minutes found: ${data.length}');
        print('=== END DEBUG ===');
        
        setState(() {
          _minutes
            ..clear()
            ..addAll(data);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load minutes (${res.statusCode}): ${res.body}';
          _loading = false;
        });
      }
    } catch (e) {
      print('Error fetching minutes: $e');
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredMinutes {
    if (_query.isEmpty) return _minutes;
    final q = _query.toLowerCase();
    return _minutes.where((m) {
      final title = (m['title'] ?? m['agendaTitle'] ?? '').toString().toLowerCase();
      final type = (m['meetingType'] ?? m['type'] ?? '').toString().toLowerCase();
      final num = (m['minuteNumber'] ?? m['number'] ?? '').toString().toLowerCase();
      return title.contains(q) || type.contains(q) || num.contains(q);
    }).toList();
  }

  String _formatDate(dynamic value) {
    try {
      if (value == null) return '';
      final dt = value is String ? DateTime.tryParse(value) : value as DateTime?;
      if (dt == null) return value.toString();
      return DateFormat('EEE, dd MMM yyyy').format(dt);
    } catch (_) {
      return value.toString();
    }
  }

  void _showDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final agendas = item['agendas'] ?? item['agenda'] ?? [];
        final agendaDetails = Map<String, dynamic>.from(item['agendaDetails'] ?? {});
        final present = List<String>.from(item['present'] ?? []);
        final apologies = List<String>.from(item['apologies'] ?? []);
        
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (item['title'] ?? item['agendaTitle'] ?? 'Meeting Minutes').toString(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(
                        icon: Icons.meeting_room,
                        label: (item['meetingType'] ?? item['type'] ?? 'General').toString(),
                      ),
                      _Chip(
                        icon: Icons.confirmation_number,
                        label: (item['minuteNumber'] ?? item['number'] ?? '').toString(),
                      ),
                      _Chip(
                        icon: Icons.event,
                        label: _formatDate(item['date'] ?? item['meetingDate']),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (present.isNotEmpty) ...[
                    const Text('Present', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: present.map((e) => Chip(label: Text(e))).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (apologies.isNotEmpty) ...[
                    const Text('Apologies', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: apologies.map((e) => Chip(label: Text(e))).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (agendas is List && agendas.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Agenda Details', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...agendas.map((agenda) {
                          if (agenda is Map) {
                            return _AgendaTile(
                              title: agenda['title'] ?? 'Agenda Item',
                              content: agenda['content'] ?? '',
                            );
                          }
                          return _AgendaTile(
                            title: agenda.toString(),
                            content: agendaDetails[agenda.toString()] ?? '',
                          );
                        }),
                      ],
                    )
                  else if (agendaDetails.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Agenda Details', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...agendaDetails.entries.map((e) => _AgendaTile(
                          title: e.key,
                          content: (e.value ?? '').toString(),
                        )),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Minutes'),
        backgroundColor: const Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _fetchMinutes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by title, type, number',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0A1F44)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchMinutes,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(Icons.error, color: Colors.red),
                                  const SizedBox(height: 8),
                                  Text(_error!),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _fetchMinutes,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : _filteredMinutes.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                Center(child: Text('No minutes available')),
                              ],
                            )
                          : ListView.separated(
                              itemCount: _filteredMinutes.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final m = _filteredMinutes[i];
                                final title = (m['title'] ?? m['agendaTitle'] ?? 'Meeting Minutes').toString();
                                final type = (m['meetingType'] ?? m['type'] ?? 'General').toString();
                                final number = (m['minuteNumber'] ?? m['number'] ?? '').toString();
                                final date = _formatDate(m['date'] ?? m['meetingDate']);
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF0A1F44).withOpacity(0.15),
                                    child: const Icon(Icons.description, color: Color(0xFF0A1F44)),
                                  ),
                                  title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(type),
                                      if (number.isNotEmpty) Text('Ref: $number'),
                                      if (date.isNotEmpty) Text(date),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _showDetails(m),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: const Color(0xFF0A1F44)),
      label: Text(label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  final String title;
  final String content;
  const _AgendaTile({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              content.isEmpty ? 'No details provided' : content,
              style: const TextStyle(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}