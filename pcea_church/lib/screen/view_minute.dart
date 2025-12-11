import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'create_minutes.dart';

class ViewMinutePage extends StatefulWidget {
  final int minuteId;
  final bool canEdit;

  const ViewMinutePage({required this.minuteId, this.canEdit = true});

  @override
  _ViewMinutePageState createState() => _ViewMinutePageState();
}

class _ViewMinutePageState extends State<ViewMinutePage> {
  final Color _brand = const Color(0xFF0A1F44);
  final Color _lightBrand = const Color(0xFF193D71);

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _minute;

  @override
  void initState() {
    super.initState();
    _loadMinute();
  }

  Future<void> _loadMinute() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final endpoint = widget.canEdit ? '/secretary/minutes' : '/minutes';
      final uri = Uri.parse('${Config.baseUrl}$endpoint/${widget.minuteId}');
      final response = await API().getRequest(url: uri);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        setState(() {
          _minute = data['data'];
          _loading = false;
        });
      } else {
        throw Exception('Failed to load minute details');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteMinute() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Minute?'),
        content: Text('Are you sure you want to permanently delete this minute?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final uri = Uri.parse('${Config.baseUrl}/secretary/minutes/${widget.minuteId}');
      final response = await API().deleteRequest(url: uri);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Minute deleted successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      } else {
        throw Exception('Failed to delete minute');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    
    // Extract data
    final title = _minute!['title'] ?? 'Untitled';
    final date = _minute!['meeting_date'] ?? '';
    final time = _minute!['meeting_time'] ?? '';
    final location = _minute!['location'] ?? 'N/A';
    final type = _minute!['meeting_type'] ?? 'N/A';
    
    final attendees = (_minute!['attendees'] as List?) ?? [];
    final agendaItems = (_minute!['agenda_items'] as List?) ?? [];
    final actionItems = (_minute!['action_items'] as List?) ?? [];
    final summary = _minute!['summary'] ?? '';
    final notes = _minute!['notes'] ?? '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PCEA CHURCH', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('MEETING MINUTES', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Divider(),
                ],
              ),
            ),
            
            // Meeting Info
            pw.Container(
              padding: pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Title: $title', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Date: $date'),
                      pw.Text('Time: $time'),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Location: $location'),
                      pw.Text('Type: $type'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Attendance
            pw.Text('ATTENDANCE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            if (attendees.isNotEmpty)
              _buildPdfAttendanceList(attendees)
            else
              pw.Text('No attendees recorded'),
            pw.SizedBox(height: 20),

            // Agenda
            pw.Text('AGENDA', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            ...agendaItems.asMap().entries.map((e) {
              return pw.Bullet(text: '${e.value['title'] ?? ''}');
            }),
            pw.SizedBox(height: 20),

            // Action Items
            pw.Text('ACTION ITEMS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            if (actionItems.isNotEmpty)
              pw.Table.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: ['Task', 'Responsible', 'Due Date', 'Status'],
                data: actionItems.map((item) => [
                  item['description'] ?? '',
                  item['responsible_member']?['name'] ?? 'Unassigned',
                  item['due_date'] ?? '',
                  item['status'] ?? ''
                ]).toList(),
              )
            else
              pw.Text('No action items'),
            pw.SizedBox(height: 20),
            
            // Discussion/Summary
            pw.Text('MINUTES / SUMMARY', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text(summary.isNotEmpty ? summary : 'No summary provided'),
            pw.SizedBox(height: 20),
            
            if (notes.isNotEmpty) ...[
               pw.Text('GENERAL NOTES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
               pw.Text(notes),
            ],
            
            // Footer
            pw.SizedBox(height: 40),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(children: [
                  pw.Container(width: 150, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 5),
                  pw.Text('Secretary Signature'),
                ]),
                pw.Column(children: [
                  pw.Container(width: 150, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 5),
                  pw.Text('Chairman Signature'),
                ]),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Minutes_${title.replaceAll(' ', '_')}.pdf',
    );
  }

  pw.Widget _buildPdfAttendanceList(List attendees) {
    // Group attendees
    final present = attendees.where((a) => a['status'] == 'present').toList();
    final apology = attendees.where((a) => a['status'] == 'absent_with_apology').toList();
    final absent = attendees.where((a) => a['status'] == 'absent_without_apology').toList();
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (present.isNotEmpty) ...[
          pw.Text('Present (${present.length}):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Wrap(
            spacing: 5,
            children: present.map((a) => pw.Text('${a['member']['name'] ?? ''},')).toList(),
          ),
          pw.SizedBox(height: 5),
        ],
        if (apology.isNotEmpty) ...[
          pw.Text('Apologies (${apology.length}):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Wrap(
            spacing: 5,
            children: apology.map((a) => pw.Text('${a['member']['name'] ?? ''},')).toList(),
          ),
          pw.SizedBox(height: 5),
        ],
        if (absent.isNotEmpty) ...[
          pw.Text('Absent (${absent.length}):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
           pw.Wrap(
            spacing: 5,
            children: absent.map((a) => pw.Text('${a['member']['name'] ?? ''},')).toList(),
          ),
        ],
      ],
    );
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minute Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          if (_minute != null) ...[
            IconButton(
              icon: Icon(Icons.picture_as_pdf),
              onPressed: _generatePdf,
              tooltip: 'Export PDF',
            ),
            if (widget.canEdit) ...[
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MinutesPage(editMinute: _minute),
                    ),
                  );
                  if (result == true) {
                    _loadMinute(); // Reload after edit
                  }
                },
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: _deleteMinute,
                tooltip: 'Delete',
              ),
            ],
          ],
        ],
      ),
      body: _loading
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
                        onPressed: _loadMinute,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      SizedBox(height: 20),
                      _buildSection('Attendance', _buildAttendance()),
                      SizedBox(height: 20),
                      _buildSection('Agenda Items', _buildAgenda()),
                      SizedBox(height: 20),
                      _buildSection('Action Items', _buildActions()),
                      SizedBox(height: 20),
                      _buildSection('Notes', _buildNotes()),
                      SizedBox(height: 20),
                      _buildSection('Summary', _buildSummary()),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final title = _minute!['title'] ?? 'Untitled';
    final meetingDate = _minute!['meeting_date'] ?? '';
    final meetingTime = _minute!['meeting_time'] ?? '';
    final meetingType = _minute!['meeting_type'] ?? 'N/A';
    final location = _minute!['location'] ?? 'N/A';
    final isOnline = _minute!['is_online'] ?? false;
    final onlineLink = _minute!['online_link'] ?? '';

    final date = meetingDate.isNotEmpty
        ? DateFormat.yMMMd().format(DateTime.parse(meetingDate))
        : 'No date';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _brand,
              ),
            ),
            SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today, 'Date', date),
            _buildInfoRow(Icons.access_time, 'Time', meetingTime),
            _buildInfoRow(Icons.meeting_room, 'Type', meetingType),
            _buildInfoRow(Icons.place, 'Location', location),
            if (isOnline && onlineLink.isNotEmpty)
              _buildInfoRow(Icons.link, 'Link', onlineLink),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _lightBrand),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _brand,
          ),
        ),
        Divider(color: _lightBrand, thickness: 2),
        SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildAttendance() {
    final attendees = (_minute!['attendees'] as List?) ?? [];
    if (attendees.isEmpty) return Text('No attendees recorded');

    final present = attendees.where((a) => a['status'] == 'present').toList();
    final apology = attendees.where((a) => a['status'] == 'absent_with_apology').toList();
    final absent = attendees.where((a) => a['status'] == 'absent_without_apology').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (present.isNotEmpty) _buildAttendanceGroup('Present', present, Colors.green),
        if (apology.isNotEmpty) _buildAttendanceGroup('With Apology', apology, Colors.orange),
        if (absent.isNotEmpty) _buildAttendanceGroup('Absent', absent, Colors.red),
      ],
    );
  }

  Widget _buildAttendanceGroup(String title, List attendees, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${attendees.length})',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        SizedBox(height: 4),
        ...attendees.map((a) => Padding(
              padding: EdgeInsets.only(left: 16, bottom: 4),
              child: Text('• ${a['member']['name'] ?? 'Unknown'} (${a['member']['role'] ?? 'Member'})'),
            )),
        SizedBox(height: 12),
      ],
    );
  }

  Widget _buildAgenda() {
    final agendaItems = (_minute!['agenda_items'] as List?) ?? [];
    if (agendaItems.isEmpty) return Text('No agenda items');

    return Column(
      children: agendaItems.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final item = entry.value;
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. ${item['title'] ?? 'Untitled'}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (item['notes'] != null && item['notes'].toString().isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(item['notes'], style: TextStyle(color: Colors.grey[700])),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions() {
    final actionItems = (_minute!['action_items'] as List?) ?? [];
    if (actionItems.isEmpty) return Text('No action items');

    return Column(
      children: actionItems.map<Widget>((item) {
        final responsible = item['responsible_member']?['name'] ?? 'Unassigned';
        final dueDate = item['due_date'] != null
            ? DateFormat.yMMMd().format(DateTime.parse(item['due_date']))
            : 'No deadline';
        final status = item['status'] ?? 'Pending';

        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['description'] ?? 'No description',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(responsible, style: TextStyle(fontSize: 12)),
                    SizedBox(width: 16),
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(dueDate, style: TextStyle(fontSize: 12)),
                    SizedBox(width: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotes() {
    final notes = _minute!['notes'] ?? '';
    return Text(notes.isEmpty ? 'No notes' : notes);
  }

  Widget _buildSummary() {
    final summary = _minute!['summary'] ?? '';
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        summary.isEmpty ? 'No summary' : summary,
        style: TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
