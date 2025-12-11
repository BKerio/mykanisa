import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMinute();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('email');
    });
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
    const Color primaryColor = Color(0xFF0A1F44);

    final confirm = await showGeneralDialog<bool>(
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
                      color: Colors.red.withOpacity(0.12),
                    ),
                    child: Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red.shade400,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Delete Minute',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Are you sure you want to permanently delete this minute?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                            shadowColor: Color(0xFF0A1F44).withOpacity(0.25),
                            backgroundColor: Color(0xFF0A1F44),
                          ),
                          child: const Text(
                            'Delete',
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

    try {
      final uri = Uri.parse(
        '${Config.baseUrl}/secretary/minutes/${widget.minuteId}',
      );

      final response = await API().deleteRequest(url: uri);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minute deleted successfully')),
        );
        Navigator.pop(context, true);
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

    // Load Logo
    final logoImage = await imageFromAssetBundle('assets/icon.png');

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
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Opacity(
              opacity: 0.08,
              child: pw.Center(child: pw.Image(logoImage)),
            ),
          ),
        ),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PCEA SGM CHURCH',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'MEETING MINUTES',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        height: 60,
                        width: 60,
                        child: pw.Image(logoImage),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
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
                  pw.Text(
                    'Title: $title',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [pw.Text('Date: $date'), pw.Text('Time: $time')],
                  ),
                  pw.SizedBox(height: 5),
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
            pw.Text(
              'ATTENDANCE',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            if (attendees.isNotEmpty)
              _buildPdfAttendanceList(attendees)
            else
              pw.Text('No attendees recorded'),
            pw.SizedBox(height: 20),

            // Agenda
            pw.Text(
              'AGENDA',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            ...agendaItems.asMap().entries.map((e) {
              return pw.Bullet(text: '${e.value['title'] ?? ''}');
            }),
            pw.SizedBox(height: 20),

            // Action Items
            pw.Text(
              'ACTION ITEMS',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            if (actionItems.isNotEmpty)
              pw.Table.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: ['Task', 'Responsible', 'Due Date', 'Status'],
                data: actionItems
                    .map(
                      (item) => [
                        item['description'] ?? '',
                        item['responsible_member']?['name'] ?? 'Unassigned',
                        item['due_date'] ?? '',
                        item['status'] ?? '',
                      ],
                    )
                    .toList(),
              )
            else
              pw.Text('No action items'),
            pw.SizedBox(height: 20),

            // Discussion/Summary
            pw.Text(
              'MINUTES / SUMMARY',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            pw.Text(summary.isNotEmpty ? summary : 'No summary provided'),
            pw.SizedBox(height: 20),

            if (notes.isNotEmpty) ...[
              pw.Text(
                'GENERAL NOTES',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(notes),
            ],

            // Footer
            pw.SizedBox(height: 40),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 150, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 5),
                    pw.Text('Secretary Signature'),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 150, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 5),
                    pw.Text('Chairman Signature'),
                  ],
                ),
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
    final apology = attendees
        .where((a) => a['status'] == 'absent_with_apology')
        .toList();
    final absent = attendees
        .where((a) => a['status'] == 'absent_without_apology')
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (present.isNotEmpty) ...[
          pw.Text(
            'Present (${present.length}):',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.Wrap(
            spacing: 5,
            children: present
                .map((a) => pw.Text('${a['member']['name'] ?? ''},'))
                .toList(),
          ),
          pw.SizedBox(height: 5),
        ],
        if (apology.isNotEmpty) ...[
          pw.Text(
            'Apologies (${apology.length}):',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.Wrap(
            spacing: 5,
            children: apology
                .map((a) => pw.Text('${a['member']['name'] ?? ''},'))
                .toList(),
          ),
          pw.SizedBox(height: 5),
        ],
        if (absent.isNotEmpty) ...[
          pw.Text(
            'Absent (${absent.length}):',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.Wrap(
            spacing: 5,
            children: absent
                .map((a) => pw.Text('${a['member']['name'] ?? ''},'))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Minute Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                  ElevatedButton(onPressed: _loadMinute, child: Text('Retry')),
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
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final apology = attendees
        .where((a) => a['status'] == 'absent_with_apology')
        .toList();
    final absent = attendees
        .where((a) => a['status'] == 'absent_without_apology')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (present.isNotEmpty)
          _buildAttendanceGroup('Present', present, Colors.green),
        if (apology.isNotEmpty)
          _buildAttendanceGroup('With Apology', apology, Colors.orange),
        if (absent.isNotEmpty)
          _buildAttendanceGroup('Absent', absent, Colors.red),
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
        ...attendees.map(
          (a) => Padding(
            padding: EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              '• ${a['member']['name'] ?? 'Unknown'} (${a['member']['role'] ?? 'Member'})',
            ),
          ),
        ),
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
                if (item['notes'] != null &&
                    item['notes'].toString().isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    item['notes'],
                    style: TextStyle(color: Colors.grey[700]),
                  ),
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
        final responsibleEmail = item['responsible_member']?['email'];
        final dueDate = item['due_date'] != null
            ? DateFormat.yMMMd().format(DateTime.parse(item['due_date']))
            : 'No deadline';
        final status = item['status'] ?? 'Pending';
        final reason = item['status_reason'];

        final isMyTask = _currentUserEmail != null && 
                         responsibleEmail == _currentUserEmail;

        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: isMyTask ? () => _updateActionStatus(item['id'], status, reason) : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['description'] ?? 'No description',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isMyTask)
                        Icon(Icons.edit, size: 16, color: _brand),
                    ],
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
                  if (reason != null && reason.toString().isNotEmpty) ...[
                     SizedBox(height: 4),
                     Text('Update: $reason', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _updateActionStatus(int id, String currentStatus, dynamic currentReason) async {
    String selectedStatus = ['Pending', 'In progress', 'Done'].contains(currentStatus) 
        ? currentStatus 
        : 'Pending';
    String reasonText = currentReason?.toString() ?? '';
    
    // Check if it was "Cannot Manage" (prefix logic)
    if (reasonText.startsWith('[Cannot Manage] ')) {
        selectedStatus = 'Cannot Manage';
        reasonText = reasonText.replaceAll('[Cannot Manage] ', '');
    }

    final reasonController = TextEditingController(text: reasonText);

    final result = await showDialog<Map<String, String>>(
       context: context,
       builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
              title: Text('Update Task Status'),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      DropdownButtonFormField<String>(
                          value: selectedStatus,
                          items: ['Pending', 'In progress', 'Done', 'Cannot Manage']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                          onChanged: (v) => setState(() => selectedStatus = v!),
                          decoration: InputDecoration(labelText: 'Status'),
                      ),
                      SizedBox(height: 10),
                      TextField(
                          controller: reasonController,
                          decoration: InputDecoration(labelText: 'Reason / Comment', border: OutlineInputBorder()),
                          maxLines: 2,
                      ),
                  ],
              ),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _brand, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(context, {
                          'status': selectedStatus, 
                          'reason': reasonController.text
                      }),
                      child: Text('Update'),
                  ),
              ],
          ),
       ),
    );

    if (result != null) {
        setState(() => _loading = true);
        try {
            final uri = Uri.parse('${Config.baseUrl}/minutes/tasks/$id/status');
            final response = await API().postRequest(url: uri, data: {
                'status': result['status'],
                'status_reason': result['reason'],
            });
            
            if (response.statusCode >= 200 && response.statusCode < 300) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated')));
                 _loadMinute(); 
            } else {
                 throw Exception('Failed to update status');
            }
        } catch(e) {
            setState(() => _loading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
    }
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
