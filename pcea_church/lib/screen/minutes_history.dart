import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'view_minute.dart';

class MinutesHistoryPage extends StatefulWidget {
  @override
  _MinutesHistoryPageState createState() => _MinutesHistoryPageState();
}

class _MinutesHistoryPageState extends State<MinutesHistoryPage> {
  final Color _brand = const Color(0xFF0A1F44);
  final Color _lightBrand = const Color(0xFF193D71);
  
  bool _loading = true;
  String? _error;
  List<dynamic> _minutes = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMinutes();
  }

  Future<void> _loadMinutes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('${Config.baseUrl}/secretary/minutes');
      final response = await API().getRequest(url: uri);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        setState(() {
          _minutes = data['data']['data'] ?? data['data'] ?? [];
          _loading = false;
        });
      } else {
        throw Exception('Failed to load minutes');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<dynamic> get _filteredMinutes {
    if (_searchQuery.isEmpty) return _minutes;
    return _minutes.where((m) {
      final title = (m['title'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Minutes History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search minutes by title...',
                prefixIcon: Icon(Icons.search, color: _brand),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _lightBrand, width: 2),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? Center(child: SpinKitThreeBounce(color: _brand, size: 30))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 60, color: Colors.red),
                            SizedBox(height: 16),
                            Text('Error: $_error'),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMinutes,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredMinutes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.description_outlined, size: 80, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No minutes recorded yet'
                                      : 'No matching minutes found',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadMinutes,
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredMinutes.length,
                              itemBuilder: (context, index) {
                                final minute = _filteredMinutes[index];
                                return _buildMinuteCard(minute);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinuteCard(dynamic minute) {
    final title = minute['title'] ?? 'Untitled';
    final meetingDate = minute['meeting_date'] ?? '';
    final meetingType = minute['meeting_type'] ?? 'N/A';
    final attendeeCount = (minute['attendees'] as List?)?.length ?? 0;
    final agendaCount = (minute['agenda_items'] as List?)?.length ?? 0;
    final actionCount = (minute['action_items'] as List?)?.length ?? 0;

    final date = meetingDate.isNotEmpty
        ? DateFormat.yMMMd().format(DateTime.parse(meetingDate))
        : 'No date';

    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewMinutePage(minuteId: minute['id']),
            ),
          );
          if (result == true) _loadMinutes(); // Reload if edited
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _brand,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMeetingTypeColor(meetingType),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      meetingType,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(date, style: TextStyle(color: Colors.grey)),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(Icons.people, '$attendeeCount', 'Attendees'),
                  _buildStat(Icons.list_alt, '$agendaCount', 'Agenda'),
                  _buildStat(Icons.assignment, '$actionCount', 'Actions'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String count, String label) {
    return Column(
      children: [
        Icon(icon, color: _lightBrand, size: 20),
        SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _brand,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Color _getMeetingTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'virtual':
        return Colors.blue;
      case 'physical':
        return Colors.green;
      case 'hybrid':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
