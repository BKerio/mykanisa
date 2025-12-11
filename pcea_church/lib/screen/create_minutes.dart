import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
// Note: Assuming these imports exist in the actual project environment
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:file_picker/file_picker.dart';
import 'minutes_history.dart';

// --- Models (Keep them unchanged) ---
class Attendee {
  String name, role, status, phone;
  String? id;
  Attendee({
    required this.name,
    this.role = '',
    this.id,
    this.status = 'present',
    this.phone = '',
  });
}

class AgendaItem {
  String title, notes;
  bool expanded;
  List<String> attachments = [];
  List<String> paths = [];
  List<List<int>> bytes = [];
  AgendaItem({this.title = 'New item', this.notes = '', this.expanded = true});
}

class ActionItem {
  String description, status;
  String? responsible;
  DateTime? dueDate;
  ActionItem({
    this.description = '',
    this.status = 'Pending',
    this.responsible,
    this.dueDate,
  });
}

// --- Main Widget ---
class MinutesPage extends StatefulWidget {
  final Map<String, dynamic>? editMinute;

  const MinutesPage({this.editMinute});

  @override
  _MinutesPageState createState() => _MinutesPageState();
}

class _MinutesPageState extends State<MinutesPage> {
  // State
  final _titleCtrl = TextEditingController(text: "Weekly Standup");
  final _locCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  String _type = 'Physical';
  bool _isOnline = false;
  bool _loadingAtt = false, _submitting = false;
  String? _attError;
  Timer? _debounce;
  String _summary = '';

  final List<Attendee> _attendees = [];
  final List<AgendaItem> _agendas = [];
  final List<ActionItem> _actions = [];

  // Brand Colors and Styling
  final Color _brand = const Color(0xFF0A1F44);
  final Color _lightBrand = const Color(0xFF193D71);
  final Color _accentColor = const Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    
    // Check if editing existing minute
    if (widget.editMinute != null) {
      _loadEditData();
    } else {
      // Initialize default agenda items for better UX
      if (_agendas.isEmpty) {
        _agendas.add(AgendaItem(title: 'Opening Prayer / Call to Order'));
        _agendas.add(AgendaItem(title: 'Review Previous Minutes & Actions'));
        _agendas.add(AgendaItem(title: 'Main Discussion Points'));
      }
    }
    
    _loadMembers();
    _searchCtrl.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 800),
        () => _loadMembers(search: _searchCtrl.text),
      );
    });
  }

  void _loadEditData() {
    final minute = widget.editMinute!;
    
    // Load basic info
    _titleCtrl.text = minute['title'] ?? '';
    _locCtrl.text = minute['location'] ?? '';
    _linkCtrl.text = minute['online_link'] ?? '';
    _notesCtrl.text = minute['notes'] ?? '';
    _summary = minute['summary'] ?? '';
    _type = minute['meeting_type'] ?? 'Physical';
    _isOnline = minute['is_online'] ?? false;
    
    if (minute['meeting_date'] != null) {
      _date = DateTime.parse(minute['meeting_date']);
    }
    
    if (minute['meeting_time'] != null) {
      final timeParts = minute['meeting_time'].toString().split(':');
      if (timeParts.length >= 2) {
        _time = TimeOfDay(
          hour: int.tryParse(timeParts[0]) ?? 0,
          minute: int.tryParse(timeParts[1]) ?? 0,
        );
      }
    }
    
    // Load agenda items
    final agendaItems = (minute['agenda_items'] as List?) ?? [];
    _agendas.clear();
    for (var item in agendaItems) {
      _agendas.add(AgendaItem(
        title: item['title'] ?? '',
        notes: item['notes'] ?? '',
      ));
    }
    
    // Store action items data to load after attendees are loaded
    _pendingActionItems = (minute['action_items'] as List?) ?? [];
  }
  
  List<dynamic> _pendingActionItems = [];
  
  void _loadPendingActionItems() {
    if (_pendingActionItems.isEmpty) return;
    
    _actions.clear();
    for (var item in _pendingActionItems) {
      final responsibleId = item['responsible_member_id']?.toString();
      // Only set responsible if that member exists in loaded attendees
      final memberExists = responsibleId != null && 
          _attendees.any((a) => a.id == responsibleId);
      
      _actions.add(ActionItem(
        description: item['description'] ?? '',
        status: item['status'] ?? 'Pending',
        responsible: memberExists ? responsibleId : null,
        dueDate: item['due_date'] != null ? DateTime.parse(item['due_date']) : null,
      ));
    }
    _pendingActionItems = []; // Clear after loading
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleCtrl.dispose();
    _locCtrl.dispose();
    _linkCtrl.dispose();
    _searchCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // --- Logic (Unchanged) ---

  Future<void> _loadMembers({String search = ''}) async {
    setState(() {
      _loadingAtt = true;
      _attError = null;
    });
    try {
      // Dummy Config and API usage, assuming they are defined elsewhere
      final uri = Uri.parse('${Config.baseUrl}/elder/members').replace(
        queryParameters: {
          'per_page': '100',
          if (search.isNotEmpty) 'q': search,
        },
      );
      final res = await API().getRequest(url: uri);
      final body = jsonDecode(res.body);

      if (res.statusCode != 200 || body == null)
        throw Exception(body?['message'] ?? 'Load failed');

      List raw = [];
      if (body['data'] is List)
        raw = body['data'];
      else if (body['members'] is List)
        raw = body['members'];
      else if (body['members']?['data'] is List)
        raw = body['members']['data'];

      setState(() {
        _attendees.clear();
        _attendees.addAll(
          raw.map((m) {
            final name = (m['full_name'] ?? '').toString();
            if (name.isEmpty) return null;
            return Attendee(
              name: name,
              role: (m['role'] ?? '').toString(),
              id: (m['id'] ?? m['member_id'])?.toString(),
              phone: (m['telephone'] ?? '').toString(),
            );
          }).whereType<Attendee>(),
        );

        if (_attendees.isEmpty && search.isEmpty)
          _attError = 'No members loaded.';
        else if (_attendees.isEmpty && search.isNotEmpty)
          _attError = 'No matching members found.';
        
        // Load pending action items now that attendees are loaded
        _loadPendingActionItems();
      });
    } catch (e) {
      setState(() => _attError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingAtt = false);
    }
  }

  Future<void> _pickFile(AgendaItem item) async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (res != null) {
      setState(() {
        for (var f in res.files) {
          if (!item.attachments.contains(f.name)) {
            item.attachments.add(f.name);
            if (f.path != null) item.paths.add(f.path!);
            if (f.bytes != null) item.bytes.add(f.bytes!);
          }
        }
      });
    }
  }

  void _generateSummary() {
    // Group attendees by status
    final presentMembers = _attendees
        .where((a) => a.status == 'present')
        .toList();
    final apologyMembers = _attendees
        .where((a) => a.status == 'absent_with_apology')
        .toList();
    final absentMembers = _attendees
        .where((a) => a.status == 'absent_without_apology')
        .toList();

    // Format attendee lists
    final presentText = presentMembers.isEmpty
        ? '  None'
        : presentMembers.map((a) => '  - ${a.name} (${a.role})').join('\n');
    final apologyText = apologyMembers.isEmpty
        ? '  None'
        : apologyMembers.map((a) => '  - ${a.name} (${a.role})').join('\n');
    final absentText = absentMembers.isEmpty
        ? '  None'
        : absentMembers.map((a) => '  - ${a.name} (${a.role})').join('\n');

    // Format agenda with titles and notes
    final agText = _agendas.isEmpty
        ? '  No agenda items'
        : _agendas
              .asMap()
              .entries
              .map((entry) {
                final index = entry.key + 1;
                final item = entry.value;
                final notes = item.notes.isNotEmpty
                    ? '\n    Notes: ${item.notes}'
                    : '';
                final attachments = item.attachments.isNotEmpty
                    ? '\n    Attachments: ${item.attachments.join(', ')}'
                    : '';
                return '  $index. ${item.title}$notes$attachments';
              })
              .join('\n\n');

    // Format action items
    final acText = _actions.isEmpty
        ? '  No action items'
        : _actions
              .map((a) {
                final responsibleName = _attendees
                    .firstWhere(
                      (att) => att.id == a.responsible,
                      orElse: () => Attendee(name: 'Unassigned'),
                    )
                    .name;
                final dueDate = a.dueDate != null
                    ? DateFormat.yMMMd().format(a.dueDate!)
                    : 'No deadline';
                return '  - ${a.description}\n    Responsible: $responsibleName | Due: $dueDate | Status: ${a.status}';
              })
              .join('\n\n');

    final meetingDateTime = DateFormat('EEEE, MMM d, yyyy @ h:mm a').format(
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute),
    );

    setState(() {
      _summary =
          '''
MEETING MINUTES SUMMARY
----------------------------
Title: ${_titleCtrl.text}
Date & Time: $meetingDateTime
Type: $_type ${(_isOnline && _linkCtrl.text.isNotEmpty) ? "($_linkCtrl.text)" : ""}
Location: ${_locCtrl.text.isNotEmpty ? _locCtrl.text : 'N/A'}

ATTENDANCE (Total: ${_attendees.length} Members)
Present (${presentMembers.length}):
$presentText

Absent with Apology (${apologyMembers.length}):
$apologyText

Absent without Apology (${absentMembers.length}):
$absentText

AGENDA & KEY DISCUSSIONS
$agText

ACTION ITEMS
$acText

GENERAL NOTES
${_notesCtrl.text.isEmpty ? 'No general notes recorded.' : _notesCtrl.text}
-----------------------------
''';
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Summary Preview', style: TextStyle(color: _brand)),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              _summary,
              style: TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _brand)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    // ... Submission logic (kept largely identical to original for functional integrity) ...

    if (_titleCtrl.text.isEmpty || _agendas.isEmpty)
      return _snack('Title and Agenda required', false);
    if (_summary.isEmpty)
      return _snack('Please generate the summary before submitting.', false);

    setState(() => _submitting = true);

    try {
      final uri = Uri.parse('${Config.baseUrl}/secretary/minutes');
      final attJson = _attendees
          .where((a) => a.id != null)
          .map(
            (a) => {'member_id': int.tryParse(a.id!) ?? 0, 'status': a.status},
          )
          .toList();

      final actJson = _actions
          .map(
            (a) => {
              'description': a.description,
              // Ensure responsible ID is parsed correctly
              'responsible_member_id': int.tryParse(a.responsible ?? '0'),
              'due_date': a.dueDate?.toIso8601String().split('T')[0],
              'status': a.status,
            },
          )
          .toList();

      final agJson = _agendas
          .asMap()
          .entries
          .map(
            (e) => {
              'title': e.value.title,
              'notes': e.value.notes,
              'order': e.key,
              'attachment_count': e.value.bytes.length,
            },
          )
          .toList();

      final fields = {
        'title': _titleCtrl.text,
        'meeting_date': DateFormat('yyyy-MM-dd').format(_date),
        'meeting_time': _time.format(context),
        'meeting_type': _type,
        'location': _locCtrl.text,
        'is_online': _isOnline,
        'online_link': _linkCtrl.text,
        'notes': _notesCtrl.text,
        'summary': _summary,
        'attendees': jsonEncode(attJson),
        'action_items': jsonEncode(actJson),
        'agenda_items': jsonEncode(agJson),
      };

      final hasFiles = _agendas.any((a) => a.bytes.isNotEmpty);
      final isEditing = widget.editMinute != null;
      final minuteId = isEditing ? widget.editMinute!['id'] : null;
      
      http.Response response;

      if (hasFiles) {
        final multipartFields = {
          // Required string fields for multipart
          ...fields.map((k, v) => MapEntry(k, v.toString())),
          'is_online': _isOnline ? '1' : '0',
          // Special handling for nested JSON arrays in multipart
          'attendees': jsonEncode(attJson),
          'action_items': jsonEncode(actJson),
          'agenda_items': jsonEncode(agJson),
          if (isEditing) '_method': 'PUT', // Laravel method spoofing for multipart
        };

        final files = <http.MultipartFile>[];
        for (int i = 0; i < _agendas.length; i++) {
          for (int j = 0; j < _agendas[i].bytes.length; j++) {
            files.add(
              http.MultipartFile.fromBytes(
                'agenda_${i}_file_$j',
                _agendas[i].bytes[j],
                filename: _agendas[i].attachments[j],
              ),
            );
          }
        }
        
        final uploadUri = isEditing 
            ? Uri.parse('${Config.baseUrl}/secretary/minutes/$minuteId')
            : uri;
            
        final streamed = await API().uploadMultipartWithFiles(
          url: uploadUri,
          fields: multipartFields,
          files: files,
        );
        response = await http.Response.fromStream(streamed);
      } else {
        final jsonPayload = Map<String, dynamic>.from(fields);
        jsonPayload['attendees'] = attJson;
        jsonPayload['action_items'] = actJson;
        jsonPayload['agenda_items'] = agJson;
        jsonPayload['is_online'] = _isOnline; // Send as boolean in JSON
        
        if (isEditing) {
          final updateUri = Uri.parse('${Config.baseUrl}/secretary/minutes/$minuteId');
          response = await API().putRequest(url: updateUri, data: jsonPayload);
        } else {
          response = await API().postRequest(url: uri, data: jsonPayload);
        }
      }

      final responseBody = response.body.trim();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _snack(isEditing ? 'Minutes updated successfully!' : 'Minutes saved successfully!', true);
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        if (responseBody.startsWith('<')) {
          throw Exception(
            'Server returned an unreadable error response (HTML). Status: ${response.statusCode}',
          );
        }
        try {
          final errorBody = jsonDecode(responseBody);
          throw Exception(errorBody['message'] ?? 'Failed to save minutes');
        } catch (_) {
          throw Exception(
            'Failed to save minutes. Status: ${response.statusCode}.',
          );
        }
      }
    } catch (e) {
      _snack('Submission Error: ${e.toString()}', false);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, bool success) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: success
              ? Colors.green.shade600
              : Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );

  // --- UI Styling Helpers ---

  InputDecoration _deco(String label, {IconData? icon, Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: icon != null ? Icon(icon, color: _brand) : null,
        suffixIcon: suffix,
        labelStyle: TextStyle(color: _brand.withOpacity(0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accentColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _lightBrand, width: 2),
        ),
        contentPadding: EdgeInsets.all(16),
      );

  Widget _inputDecorator(
    String label,
    String value,
    VoidCallback onTap, {
    IconData icon = Icons.calendar_today,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: _deco(label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: _brand,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(icon, size: 18, color: _brand.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Record Meeting Minutes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MinutesHistoryPage(),
                ),
              );
            },
            tooltip: 'View History',
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildInfo(),
            _Section(title: '1. Attendees & Status', child: _buildAttendance()),
            _Section(
              title: '2. Meeting Agenda',
              action: _addBtn(
                () => setState(() => _agendas.add(AgendaItem())),
                tooltip: 'Add Agenda Item',
              ),
              child: _buildAgenda(),
            ),
            _Section(
              title: '3. General Notes',
              child: TextField(
                controller: _notesCtrl,
                maxLines: 6,
                decoration: _deco('Detailed discussion notes and outcomes'),
              ),
            ),
            _Section(
              title: '4. Action Items',
              action: _addBtn(
                () => setState(() => _actions.add(ActionItem())),
                tooltip: 'Add Action Item',
              ),
              child: _buildActions(),
            ),
            SizedBox(height: 20),
            // --- New Generate Summary Button ---
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _lightBrand,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _generateSummary,
              icon: Icon(Icons.summarize),
              label: Text(
                'Generate Minutes Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            // --- Save Button ---
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? SpinKitRing(color: Colors.white, size: 20, lineWidth: 2)
                  : Icon(Icons.cloud_upload),
              label: Text(
                _submitting ? 'Saving...' : 'Save & Finalize Minutes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _addBtn(VoidCallback fn, {String tooltip = 'Add Item'}) => IconButton(
    icon: Icon(Icons.add_circle, color: _lightBrand, size: 28),
    onPressed: fn,
    tooltip: tooltip,
  );

  Widget _buildInfo() {
    return Card(
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meeting Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _brand,
              ),
            ),
            Divider(color: _accentColor, height: 20),
            TextField(
              controller: _titleCtrl,
              decoration: _deco('Meeting Title', icon: Icons.title),
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    decoration: _deco('Type', icon: Icons.meeting_room),
                    items: ['Physical', 'Virtual', 'Hybrid']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _type = v!;
                      _isOnline = (v == 'Virtual' || v == 'Hybrid');
                    }),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _locCtrl,
                    decoration: _deco('Location', icon: Icons.place),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _inputDecorator(
                    'Date',
                    DateFormat.yMMMd().format(_date),
                    () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: ColorScheme.light(primary: _brand),
                          ),
                          child: child!,
                        ),
                      );
                      if (d != null) setState(() => _date = d);
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _inputDecorator(
                    'Time',
                    _time.format(context),
                    () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _time,
                        builder: (context, child) => Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: ColorScheme.light(primary: _brand),
                          ),
                          child: child!,
                        ),
                      );
                      if (t != null) setState(() => _time = t);
                    },
                    icon: Icons.access_time,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SwitchListTile(
                title: Text(
                  'Is this an online component?',
                  style: TextStyle(color: _brand),
                ),
                value: _isOnline,
                activeColor: _brand,
                dense: true,
                onChanged: (v) => setState(() => _isOnline = v),
              ),
            ),
            if (_isOnline)
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: TextField(
                  controller: _linkCtrl,
                  decoration: _deco(
                    'Meeting Link (Zoom/Teams URL)',
                    icon: Icons.link,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendance() {
    // Calculate attendance statistics
    final presentCount = _attendees.where((a) => a.status == 'present').length;
    final apologyCount = _attendees
        .where((a) => a.status == 'absent_with_apology')
        .length;
    final absentCount = _attendees
        .where((a) => a.status == 'absent_without_apology')
        .length;

    return Column(
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: _deco(
            'Search Member by Name or Role',
            icon: Icons.search,
          ),
        ),
        SizedBox(height: 15),

        // Attendance Status Bar
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_brand.withOpacity(0.05), _lightBrand.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accentColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _brand,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusBadge(
                    'Present',
                    presentCount,
                    Colors.green,
                    Icons.check_circle,
                  ),
                  _buildStatusBadge(
                    'With Apology',
                    apologyCount,
                    Colors.orange,
                    Icons.info,
                  ),
                  _buildStatusBadge(
                    'Absent',
                    absentCount,
                    Colors.red,
                    Icons.cancel,
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 10),
        _loadingAtt
            ? Padding(
                padding: const EdgeInsets.all(20.0),
                child: SpinKitThreeBounce(color: _brand, size: 20),
              )
            : _attError != null
            ? Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(_attError!, style: TextStyle(color: Colors.red)),
              )
            : Column(
                children: [
                  // Present Members Section
                  _buildStatusSection(
                    'Present',
                    _attendees.where((a) => a.status == 'present').toList(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                  SizedBox(height: 8),

                  // With Apology Section
                  _buildStatusSection(
                    'Absent with Apology',
                    _attendees
                        .where((a) => a.status == 'absent_with_apology')
                        .toList(),
                    Colors.orange,
                    Icons.info,
                  ),
                  SizedBox(height: 8),

                  // Absent Section
                  _buildStatusSection(
                    'Absent without Apology',
                    _attendees
                        .where((a) => a.status == 'absent_without_apology')
                        .toList(),
                    Colors.red,
                    Icons.cancel,
                  ),
                ],
              ),
      ],
    );
  }

  DropdownMenuItem<String> _buildStatusItem(
    String value,
    String label,
    Color color,
  ) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          SizedBox(width: 8),
          Text(label, style: TextStyle(color: _brand)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(
    String title,
    List<Attendee> members,
    Color color,
    IconData icon,
  ) {
    if (members.isEmpty) {
      return SizedBox.shrink(); // Don't show empty sections
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            '$title (${members.length})',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 15,
            ),
          ),
          children: members.map((a) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          a.role,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _accentColor),
                    ),
                    child: DropdownButton<String>(
                      value: a.status,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: _brand,
                        size: 20,
                      ),
                      underline: SizedBox(),
                      isDense: true,
                      items: [
                        _buildStatusItem('present', 'Present', Colors.green),
                        _buildStatusItem(
                          'absent_with_apology',
                          'Apology',
                          Colors.orange,
                        ),
                        _buildStatusItem(
                          'absent_without_apology',
                          'Absent',
                          Colors.red,
                        ),
                      ],
                      onChanged: (v) => setState(() => a.status = v!),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAgenda() {
    if (_agendas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Click the + button to add the first agenda item.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return ReorderableListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      onReorder: (o, n) => setState(() {
        if (o < n) n--;
        final item = _agendas.removeAt(o);
        _agendas.insert(n, item);
      }),
      children: _agendas.asMap().entries.map((entry) {
        final item = entry.value;
        final index = entry.key;
        return Card(
          key: ValueKey(item),
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Theme(
            // Remove default divider line
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: _brand,
                radius: 14,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              title: TextFormField(
                initialValue: item.title,
                onChanged: (v) => item.title = v,
                style: TextStyle(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Agenda Title (e.g., Financial Report)',
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${item.attachments.length} files',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade400,
                      size: 22,
                    ),
                    onPressed: () async {
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
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 26,
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  26,
                                  22,
                                  26,
                                  18,
                                ),
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
                                        color: Color(0xFF0A1F44),
                                        size: 40,
                                      ),
                                    ),

                                    const SizedBox(height: 18),

                                    Text(
                                      'Delete Agenda Item',
                                      style: TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0A1F44),
                                        decoration: TextDecoration.none,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    Text(
                                      'Are you sure you want to delete "${item.title}"?',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
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
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              backgroundColor: Colors.teal,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text(
                                              'Not Now',
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
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              elevation: 6,
                                              shadowColor: Colors.red
                                                  .withOpacity(0.25),
                                              backgroundColor: Color(
                                                0xFF0A1F44,
                                              ),
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

                      if (confirm == true) {
                        setState(() => _agendas.remove(item));
                      }
                    },
                  ),
                ],
              ),

              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: TextEditingController(text: item.notes)
                          ..selection = TextSelection.collapsed(
                            offset: item.notes.length,
                          ),
                        onChanged: (v) => item.notes = v,
                        maxLines: 4,
                        decoration: _deco('Discussion/Decisions Notes'),
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: item.attachments
                            .asMap()
                            .entries
                            .map(
                              (entry) => Chip(
                                backgroundColor: _accentColor,
                                label: Text(
                                  entry.value,
                                  style: TextStyle(fontSize: 11),
                                ),
                                deleteIcon: Icon(Icons.close, size: 16),
                                onDeleted: () => setState(() {
                                  item.attachments.removeAt(entry.key);
                                  item.bytes.removeAt(entry.key);
                                  if (entry.key < item.paths.length)
                                    item.paths.removeAt(entry.key);
                                }),
                              ),
                            )
                            .toList(),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _pickFile(item),
                          icon: Icon(Icons.attach_file, color: _lightBrand),
                          label: Text(
                            'Attach Supporting Document(s)',
                            style: TextStyle(color: _lightBrand),
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
      }).toList(),
    );
  }

  Widget _buildActions() {
    return Column(
      children: _actions
          .map(
            (item) => Card(
              elevation: 2,
              margin: EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: item.description,
                            onChanged: (v) => item.description = v,
                            maxLines: 2,
                            decoration: _deco(
                              'Action/Task Description',
                              icon: Icons.playlist_add_check,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_forever,
                            color: Colors.red.shade400,
                          ),
                          onPressed: () async {
                            final confirm = await showGeneralDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              barrierColor: Colors.black.withOpacity(0.35),
                              transitionDuration: const Duration(
                                milliseconds: 260,
                              ),
                              pageBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                              transitionBuilder: (context, animation, _, __) {
                                final curved = CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutBack,
                                );

                                return ScaleTransition(
                                  scale: curved,
                                  child: Center(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 26,
                                      ),
                                      padding: const EdgeInsets.fromLTRB(
                                        26,
                                        22,
                                        26,
                                        18,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.94),
                                        borderRadius: BorderRadius.circular(26),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 1.4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.08,
                                            ),
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
                                              color: Colors.red.withOpacity(
                                                0.12,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.delete_forever_rounded,
                                              color: Colors.red.shade400,
                                              size: 40,
                                            ),
                                          ),

                                          const SizedBox(height: 18),

                                          Text(
                                            'Delete Action Item',
                                            style: TextStyle(
                                              fontSize: 23,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.red.shade400,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),

                                          const SizedBox(height: 10),

                                          const Text(
                                            'Are you sure you want to delete this action item?',
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
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  style: TextButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                    ),
                                                    backgroundColor:
                                                        Colors.teal,
                                                    foregroundColor:
                                                        Colors.white,
                                                  ),
                                                  child: const Text(
                                                    'Not Now',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      decoration:
                                                          TextDecoration.none,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 12),

                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  style: ElevatedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                    ),
                                                    elevation: 6,
                                                    shadowColor: Colors.red
                                                        .withOpacity(0.25),
                                                    backgroundColor: Color(
                                                      0xFF0A1F44,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      letterSpacing: 0.3,
                                                      decoration:
                                                          TextDecoration.none,
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

                            if (confirm == true) {
                              setState(() => _actions.remove(item));
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: item.responsible,
                            decoration: _deco('Responsible Member'),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Unassigned'),
                              ),
                              ..._attendees
                                  .where((a) => a.id != null)
                                  .map(
                                    (a) => DropdownMenuItem(
                                      value: a.id,
                                      child: Text(
                                        a.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                            ],
                            onChanged: (v) =>
                                setState(() => item.responsible = v),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _inputDecorator(
                            'Due Date',
                            item.dueDate != null
                                ? DateFormat.MMMd().format(item.dueDate!)
                                : 'Select Date',
                            () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: item.dueDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                                builder: (context, child) => Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: _brand,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (d != null) setState(() => item.dueDate = d);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const _Section({required this.title, required this.child, this.action});
  @override
  Widget build(BuildContext context) {
    final brand = Color(0xFF0A1F44);
    return Padding(
      padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: brand,
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 8.0),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
