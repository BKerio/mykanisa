import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:file_picker/file_picker.dart';

class MinutesPage extends StatefulWidget {
  @override
  _MinutesPageState createState() => _MinutesPageState();
}

class _MinutesPageState extends State<MinutesPage> {
  // Header
  final _titleController = TextEditingController(text: "Weekly Standup");
  DateTime _meetingDate = DateTime.now();
  TimeOfDay _meetingTime = TimeOfDay.now();
  String _meetingType = 'Virtual';
  final _locationController = TextEditingController();
  bool _isOnline = true;
  final _onlineLinkController = TextEditingController();

  // Attendance (fetched from API similar to members.dart)
  final List<Attendee> _attendees = [];
  final List<Attendee> _filteredAttendees = [];
  final _attendeeSearchController = TextEditingController();
  bool _isLoadingAttendance = false;
  String? _attendanceError;
  Timer? _attendanceSearchDebounce;

  // Agenda
  List<AgendaItem> _agendaItems = [];

  // Rich notes
  final _richNotesController = TextEditingController();

  // Actions
  List<ActionItem> _actionItems = [];

  // Attachments (simulated)
  List<String> _attachments = [];

  // Summary
  String _summary = '';
  final Map<String, String> _attendanceStatus = {}; // key => status

  // Utility
  String get formattedDate => DateFormat.yMMMd().format(_meetingDate);
  String get formattedTime => _meetingTime.format(context);

  // For small UI niceties
  @override
  void initState() {
    super.initState();
    _loadMembers();
    _attendeeSearchController.addListener(_debouncedAttendanceSearch);
  }

  @override
  void dispose() {
    _attendanceSearchDebounce?.cancel();
    _attendeeSearchController
      ..removeListener(_debouncedAttendanceSearch)
      ..dispose();
    _titleController.dispose();
    _locationController.dispose();
    _onlineLinkController.dispose();
    _richNotesController.dispose();
    super.dispose();
  }

  String _presenceKey(Attendee attendee) {
    return attendee.id ?? attendee.name;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AttendeeStatus.present:
        return Colors.green.shade700;
      case AttendeeStatus.absentWithApology:
        return Colors.orange.shade700;
      case AttendeeStatus.absentWithoutApology:
        return Colors.red.shade700;
      default:
        return const Color(0xFF0A1F44);
    }
  }

  Color _getActionStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade700;
      case 'In progress':
        return Colors.blue.shade700;
      case 'Done':
        return Colors.green.shade700;
      default:
        return const Color(0xFF0A1F44);
    }
  }

  IconData _getActionStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.pending;
      case 'In progress':
        return Icons.refresh;
      case 'Done':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  void _debouncedAttendanceSearch() {
    _attendanceSearchDebounce?.cancel();
    _attendanceSearchDebounce = Timer(
      const Duration(milliseconds: 800),
      () => _loadMembers(
        useSearch: _attendeeSearchController.text.trim().isNotEmpty,
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required int value,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMembers({bool useSearch = false}) async {
    setState(() {
      _isLoadingAttendance = true;
      _attendanceError = null;
    });

    try {
      final query = <String, String>{'per_page': '100'};
      final search = _attendeeSearchController.text.trim();
      if (useSearch && search.isNotEmpty) {
        query['q'] = search;
      }

      final uri = Uri.parse(
        '${Config.baseUrl}/elder/members',
      ).replace(queryParameters: query);

      final response = await API().getRequest(url: uri);
      Map<String, dynamic>? body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {
        body = null;
      }

      if (response.statusCode != 200) {
        final message = body?['message']?.toString();
        setState(() {
          _attendanceError = message ?? 'Failed to load members.';
          _attendees.clear();
          _filteredAttendees.clear();
        });
        return;
      }

      if (body == null) {
        setState(() {
          _attendanceError = 'Unexpected response from server.';
          _attendees.clear();
          _filteredAttendees.clear();
        });
        return;
      }

      List<Map<String, dynamic>> parsed = [];
      if (body.containsKey('data') && body['data'] is List) {
        parsed = List<Map<String, dynamic>>.from(body['data']);
      } else if (body.containsKey('members')) {
        final raw = body['members'];
        if (raw is List) {
          parsed = List<Map<String, dynamic>>.from(raw);
        } else if (raw is Map<String, dynamic> && raw['data'] is List) {
          parsed = List<Map<String, dynamic>>.from(raw['data']);
        }
      } else if (body['status'] == 200 && body['data'] is List) {
        parsed = List<Map<String, dynamic>>.from(body['data']);
      }

      final attendees = parsed
          .map((m) {
            final fullName = (m['full_name'] ?? '').toString().trim();
            if (fullName.isEmpty) return null;
            final role = (m['role'] ?? '').toString();
            final id = (m['id'] ?? m['member_id'])?.toString();
            final phone = (m['telephone'] ?? '').toString();
            final key = id ?? fullName;
            final status =
                _attendanceStatus[key] ??
                AttendeeStatus.present; // default present
            return Attendee(
              name: fullName,
              role: role,
              id: id,
              status: status,
              phone: phone,
            );
          })
          .whereType<Attendee>()
          .toList();

      setState(() {
        _attendees
          ..clear()
          ..addAll(attendees);
        _filteredAttendees
          ..clear()
          ..addAll(attendees);
        if (_attendees.isEmpty) {
          _attendanceError = useSearch && search.isNotEmpty
              ? 'No members found matching "$search".'
              : 'No members found.';
        }
      });
    } catch (e) {
      setState(() {
        _attendanceError = 'Failed to load members: ${e.toString()}';
        _attendees.clear();
        _filteredAttendees.clear();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAttendance = false;
        });
      }
    }
  }

  void _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _meetingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _meetingDate = d);
  }

  void _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _meetingTime);
    if (t != null) setState(() => _meetingTime = t);
  }

  void _addAttendee() {
    showDialog(
      context: context,
      builder: (context) {
        final tc = TextEditingController();
        final role = TextEditingController();
        return AlertDialog(
          title: Text('Add attendee'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tc,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: role,
                decoration: InputDecoration(labelText: 'Role (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              child: Text('Add'),
              onPressed: () {
                if (tc.text.trim().isEmpty) return;
                setState(() {
                  final newAttendee = Attendee(
                    name: tc.text.trim(),
                    role: role.text.trim(),
                  );
                  _attendees.add(newAttendee);
                  _filteredAttendees.add(newAttendee);
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _addAgendaItem() {
    setState(() {
      _agendaItems.add(AgendaItem(title: 'New item', notes: ''));
    });
  }

  Future<void> _pickFileForAgenda(AgendaItem item) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var file in result.files) {
            final fileName = file.name;
            if (!item.attachments.contains(fileName)) {
              item.attachments.add(fileName);
            }
          }
        });
        _showSnack('${result.files.length} file(s) attached successfully');
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      _showSnack('Error picking file. Please try again.');
    }
  }

  Widget _buildAgendaItemCard(AgendaItem item, int index) {
    return Dismissible(
      key: ValueKey(item),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => setState(() => _agendaItems.remove(item)),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Header - Always visible
              InkWell(
                onTap: () => setState(() => item.expanded = !item.expanded),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0A1F44).withOpacity(0.1),
                        const Color(0xFF0A1F44).withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Drag handle
                      ReorderableDragStartListener(
                        index: index,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.drag_handle,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Number badge
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0A1F44), Color(0xFF1a3a6b)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0A1F44).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title field
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: item.title)
                            ..selection = TextSelection.collapsed(
                              offset: item.title.length,
                            ),
                          onChanged: (v) => setState(() => item.title = v),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A1F44),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter agenda title...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      // Attachment count badge
                      if (item.attachments.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_file,
                                size: 14,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.attachments.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Expand/Collapse icon with animation
                      AnimatedRotation(
                        turns: item.expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: const Color(0xFF0A1F44),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Expandable content with animation
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notes field
                      TextField(
                        controller: TextEditingController(text: item.notes)
                          ..selection = TextSelection.collapsed(
                            offset: item.notes.length,
                          ),
                        onChanged: (v) => setState(() => item.notes = v),
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Add notes or discussion points...',
                          prefixIcon: const Icon(
                            Icons.note_outlined,
                            color: Color(0xFF0A1F44),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF0A1F44),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      // Attachments section
                      if (item.attachments.isNotEmpty) ...[
                        Text(
                          'Attachments',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: item.attachments.map((attachment) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.insert_drive_file,
                                    size: 16,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    attachment,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        item.attachments.remove(attachment);
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _pickFileForAgenda(item),
                            icon: const Icon(Icons.attach_file, size: 18),
                            label: Text(
                              item.attachments.isEmpty
                                  ? 'Add Attachment'
                                  : 'Add More',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A1F44),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => item.expanded = false),
                            icon: const Icon(Icons.unfold_less, size: 18),
                            label: const Text('Collapse'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                crossFadeState: item.expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addActionItem() {
    setState(() {
      _actionItems.add(
        ActionItem(description: '', responsible: null, dueDate: null),
      );
    });
  }

  void _addAttachment() {
    // Simulated add, replace with file picker logic if needed
    setState(() {
      _attachments.add('file_${_attachments.length + 1}.pdf');
    });
  }

  void _generateSummary() {
    final presentCount = _attendees
        .where((a) => a.status == AttendeeStatus.present)
        .length;
    final absentWithApology = _attendees
        .where((a) => a.status == AttendeeStatus.absentWithApology)
        .length;
    final absentWithoutApology = _attendees
        .where((a) => a.status == AttendeeStatus.absentWithoutApology)
        .length;
    final absentCount = absentWithApology + absentWithoutApology;
    final agendas = _agendaItems.map((a) => '- ${a.title}').join('\n');
    final actions = _actionItems
        .asMap()
        .entries
        .map(
          (e) =>
              '${e.key + 1}. ${e.value.description} [${e.value.responsible ?? "Unassigned"}]',
        )
        .join('\n');

    setState(() {
      _summary =
          '''
Title: ${_titleController.text}
When: $formattedDate, $formattedTime
Type: $_meetingType ${_isOnline ? "(online)" : ""}
Location: ${_locationController.text}

Attendance:
- Present: $presentCount
- Absent (with apology): $absentWithApology
- Absent (without apology): $absentWithoutApology
Total absent: $absentCount

Agenda:
$agendas

Key notes:
${_richNotesController.text.isEmpty ? "(none)" : _richNotesController.text}

Action items:
${actions.isEmpty ? "(none)" : actions}
''';
    });

    // Optionally show a preview dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Summary Preview'),
        content: SingleChildScrollView(child: Text(_summary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleAllPresent(bool val) {
    final status = val
        ? AttendeeStatus.present
        : AttendeeStatus.absentWithoutApology;
    setState(() {
      for (final a in _attendees) {
        a.status = status;
        _attendanceStatus[_presenceKey(a)] = status;
      }
    });
  }

  void _setAllStatus(String status) {
    setState(() {
      for (final a in _attendees) {
        a.status = status;
        _attendanceStatus[_presenceKey(a)] = status;
      }
    });
  }

  bool _isSubmitting = false;

  Future<void> _submitMinutes() async {
    // Validate required fields
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Please enter a meeting title');
      return;
    }

    if (_agendaItems.isEmpty) {
      _showSnack('Please add at least one agenda item');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Prepare attendees data
      final attendeesData = _attendees.map((attendee) {
        return {
          'member_id': int.tryParse(attendee.id ?? '') ?? 0,
          'status': attendee.status,
        };
      }).where((a) => a['member_id'] != 0).toList();

      // Prepare agenda items data
      final agendaItemsData = _agendaItems.asMap().entries.map((entry) {
        return {
          'title': entry.value.title,
          'notes': entry.value.notes,
          'order': entry.key,
          'attachments': entry.value.attachments,
        };
      }).toList();

      // Prepare action items data
      final actionItemsData = _actionItems.map((item) {
        return {
          'description': item.description,
          'responsible_member_id': item.responsible != null 
              ? int.tryParse(item.responsible!) 
              : null,
          'due_date': item.dueDate?.toIso8601String().split('T')[0],
          'status': item.status,
        };
      }).toList();

      // Prepare the complete payload
      final payload = {
        'title': _titleController.text.trim(),
        'meeting_date': DateFormat('yyyy-MM-dd').format(_meetingDate),
        'meeting_time': _meetingTime.format(context),
        'meeting_type': _meetingType,
        'location': _locationController.text.trim(),
        'is_online': _isOnline,
        'online_link': _onlineLinkController.text.trim(),
        'notes': _richNotesController.text.trim(),
        'summary': _summary,
        'attendees': attendeesData,
        'agenda_items': agendaItemsData,
        'action_items': actionItemsData,
      };

      final uri = Uri.parse('${Config.baseUrl}/secretary/minutes');
      final response = await API().postRequest(url: uri, data: payload);

      final body = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          API.showSnack(context, 'Minutes saved successfully!', success: true);
          Navigator.pop(context);
        }
      } else {
        final message = body['message'] ?? 'Failed to save minutes';
        if (mounted) {
          API.showSnack(context, message, success: false);
        }
      }
    } catch (e) {
      if (mounted) {
        API.showSnack(
          context,
          'Error saving minutes: ${e.toString()}',
          success: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAttendees = _filteredAttendees;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Meeting Minutes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSubmitting ? null : _submitMinutes,
            tooltip: 'Save Minutes',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _showSnack('Export to PDF requested'),
          ),
          PopupMenuButton<String>(
            onSelected: (s) => _showSnack(s),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'Share', child: Text('Share')),
              const PopupMenuItem(
                value: 'Version history',
                child: Text('Version history'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(14),
          children: [
            _buildHeader(),
            SizedBox(height: 12),
            _buildAttendanceSection(filteredAttendees),
            SizedBox(height: 12),
            _buildAgendaSection(),
            SizedBox(height: 12),
            _buildRichNotesSection(),
            SizedBox(height: 12),
            _buildActionItemsSection(),
            SizedBox(height: 12),
            _buildAttachmentsSection(),
            SizedBox(height: 12),
            _buildSummarySection(),
            SizedBox(height: 18),
            _buildFooterActions(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1F44).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF0A1F44),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'General Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A1F44),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Meeting Title
            TextField(
              controller: _titleController,
              decoration: _styledInput('Meeting Title'),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                // Meeting Type Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _meetingType,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF0A1F44),
                    ),
                    iconSize: 28,
                    decoration: _styledInput('Meeting Type'),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF0A1F44),
                      fontWeight: FontWeight.w500,
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 8,
                    items: [
                      DropdownMenuItem(
                        value: 'Physical',
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 20,
                              color: Color(0xFF0A1F44),
                            ),
                            const SizedBox(width: 8),
                            const Text('Physical'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Virtual',
                        child: Row(
                          children: [
                            Icon(
                              Icons.video_call,
                              size: 20,
                              color: Color(0xFF0A1F44),
                            ),
                            const SizedBox(width: 8),
                            const Text('Virtual'),
                          ],
                        ),
                      ),

                      DropdownMenuItem(
                        value: 'Hybrid',
                        child: Row(
                          children: [
                            Icon(
                              Icons.wifi_tethering,
                              size: 20,
                              color: Color(0xFF0A1F44),
                            ),
                            const SizedBox(width: 8),
                            const Text('Hybrid'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _meetingType = v ?? _meetingType),
                  ),
                ),

                const SizedBox(width: 12),

                // Location Input
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: _styledInput('Location'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Date and Time pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _styledInput('Date'),
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Color(0xFF0A1F44),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _styledInput('Time'),
                      child: Text(
                        formattedTime,
                        style: const TextStyle(
                          color: Color(0xFF0A1F44),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Online Meeting Toggle
            Row(
              children: [
                const Text(
                  'Online meeting',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _isOnline,
                  activeColor: const Color(0xFF0A1F44),
                  onChanged: (v) => setState(() => _isOnline = v),
                ),
              ],
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              child: _isOnline
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: _onlineLinkController,
                        decoration: _styledInput('Online link'),
                      ),
                    )
                  : Container(),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _styledInput(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: const TextStyle(color: Color(0xFF0A1F44)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0A1F44), width: 2),
      ),
    );
  }

  Widget _buildAttendanceSection(List<Attendee> filteredAttendees) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1F44).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups_outlined,
                    color: Color(0xFF0A1F44),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Meeting Attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A1F44),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildStatChip(
                  label: 'Present',
                  value: _attendees
                      .where((a) => a.status == AttendeeStatus.present)
                      .length,
                  color: Colors.green.shade50,
                  textColor: Colors.green.shade800,
                ),
                _buildStatChip(
                  label: 'Absent (apology)',
                  value: _attendees
                      .where(
                        (a) => a.status == AttendeeStatus.absentWithApology,
                      )
                      .length,
                  color: Colors.orange.shade50,
                  textColor: Colors.orange.shade800,
                ),
                _buildStatChip(
                  label: 'Absent (no apology)',
                  value: _attendees
                      .where(
                        (a) => a.status == AttendeeStatus.absentWithoutApology,
                      )
                      .length,
                  color: Colors.red.shade50,
                  textColor: Colors.red.shade800,
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _attendeeSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search attendees',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF0A1F44),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF0A1F44),
                          width: 2,
                        ),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF0A1F44),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1F44),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    tooltip: 'Add attendee',
                    onPressed: _addAttendee,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton(
                  onPressed: () => _toggleAllPresent(true),
                  child: const Text('Mark all present'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      _setAllStatus(AttendeeStatus.absentWithApology),
                  child: const Text('All absent (apology)'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      _setAllStatus(AttendeeStatus.absentWithoutApology),
                  child: const Text('All absent (no apology)'),
                ),
              ],
            ),
            Divider(),
            if (_isLoadingAttendance)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: SpinKitFadingCircle(
                    size: 64,
                    duration: const Duration(
                      milliseconds: 1800,
                    ), // Adjusted duration
                    itemBuilder: (context, index) {
                      final palette = [
                        Color(0xFF0A1F44),
                        Colors.red,
                        Colors.blue,
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
            else if (_attendanceError != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      _attendanceError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _loadMembers(
                        useSearch: _attendeeSearchController.text
                            .trim()
                            .isNotEmpty,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1F44),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else if (filteredAttendees.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: const [
                    Icon(Icons.people_outline, color: Colors.grey, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'No members found. Try refreshing.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filteredAttendees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final a = filteredAttendees[i];
                    return Dismissible(
                      key: ValueKey(_presenceKey(a)),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.red,
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => setState(() {
                        _attendanceStatus.remove(_presenceKey(a));
                        _attendees.remove(a);
                        _filteredAttendees.remove(a);
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(
                                0xFF0A1F44,
                              ).withOpacity(0.08),
                              foregroundColor: const Color(0xFF0A1F44),
                              child: Text('${i + 1}'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (a.role.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      a.role,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.grey.shade700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (a.phone.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_outlined,
                                          size: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            a.phone,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: a.status,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: _getStatusColor(a.status),
                                  size: 24,
                                ),
                                iconSize: 24,
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: _getStatusColor(
                                    a.status,
                                  ).withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: _getStatusColor(
                                        a.status,
                                      ).withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: _getStatusColor(
                                        a.status,
                                      ).withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: _getStatusColor(a.status),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: AttendeeStatus.present,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 18,
                                          color: Colors.green.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Present',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: AttendeeStatus.absentWithApology,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 18,
                                          color: Colors.orange.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        const Flexible(
                                          child: Text(
                                            'Absent (apology)',
                                            style: TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: AttendeeStatus.absentWithoutApology,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.cancel_outlined,
                                          size: 18,
                                          color: Colors.red.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        const Flexible(
                                          child: Text(
                                            'Absent (no apology)',
                                            style: TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() {
                                    a.status = v;
                                    _attendanceStatus[_presenceKey(a)] = v;
                                  });
                                },
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _getStatusColor(a.status),
                                  fontWeight: FontWeight.w600,
                                ),
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                elevation: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Agenda Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1F44),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addAgendaItem,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1F44),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Agenda List
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _agendaItems.removeAt(oldIndex);
                  _agendaItems.insert(newIndex, item);
                });
              },
              children: _agendaItems
                  .asMap()
                  .map((index, item) {
                    return MapEntry(index, _buildAgendaItemCard(item, index));
                  })
                  .values
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichNotesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meeting Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _richNotesController,
              maxLines: 10,
              minLines: 8,
              style: const TextStyle(fontSize: 15, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Type meeting notes here...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF0A1F44),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItemsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Action Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addActionItem,
                  icon: Icon(Icons.add_task),
                  label: Text('Add'),
                ),
              ],
            ),
            SizedBox(height: 8),
            ReorderableListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _actionItems.removeAt(oldIndex);
                  _actionItems.insert(newIndex, item);
                });
              },
              children: _actionItems
                  .asMap()
                  .map((i, it) {
                    final uniqueKey = 'action_$i';
                    return MapEntry(
                      i,
                      Dismissible(
                        key: Key(uniqueKey),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          setState(() {
                            _actionItems.removeAt(i);
                          });
                        },
                        child: ReorderableDragStartListener(
                          index: i,
                          key: Key('${uniqueKey}_drag'),
                          child: Card(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Drag handle
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.drag_handle,
                                          size: 18,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          controller:
                                              TextEditingController(
                                                  text: it.description,
                                                )
                                                ..selection =
                                                    TextSelection.collapsed(
                                                      offset:
                                                          it.description.length,
                                                    ),
                                          onChanged: (v) {
                                            setState(() => it.description = v);
                                          },
                                          decoration: InputDecoration(
                                            labelText: 'Description',
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF0A1F44),
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      PopupMenuButton<String>(
                                        onSelected: (s) =>
                                            setState(() => it.status = s),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 8,
                                        itemBuilder: (_) => [
                                          PopupMenuItem(
                                            value: 'Pending',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.pending,
                                                  size: 20,
                                                  color: Colors.orange.shade700,
                                                ),
                                                const SizedBox(width: 12),
                                                const Text('Pending'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'In progress',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.refresh,
                                                  size: 20,
                                                  color: Colors.blue.shade700,
                                                ),
                                                const SizedBox(width: 12),
                                                const Text('In progress'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'Done',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  size: 20,
                                                  color: Colors.green.shade700,
                                                ),
                                                const SizedBox(width: 12),
                                                const Text('Done'),
                                              ],
                                            ),
                                          ),
                                        ],
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getActionStatusColor(
                                              it.status,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: _getActionStatusColor(
                                                it.status,
                                              ).withOpacity(0.5),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getActionStatusIcon(it.status),
                                                size: 16,
                                                color: _getActionStatusColor(
                                                  it.status,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                it.status,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: _getActionStatusColor(
                                                    it.status,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: it.responsible,
                                          icon: Icon(
                                            Icons.arrow_drop_down,
                                            color: const Color(0xFF0A1F44),
                                          ),
                                          iconSize: 28,
                                          decoration: InputDecoration(
                                            labelText: 'Responsible',
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                            prefixIcon: Icon(
                                              Icons.person_outline,
                                              color: const Color(0xFF0A1F44),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF0A1F44),
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 16,
                                                ),
                                          ),
                                          items: [
                                            DropdownMenuItem<String>(
                                              value: null,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.person_off,
                                                    size: 20,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    'Unassigned',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (_attendees.isNotEmpty)
                                              ..._attendees.where((a) => a.name.trim().isNotEmpty).map((
                                                a,
                                              ) {
                                                final name = a.name.trim();
                                                return DropdownMenuItem<String>(
                                                  value: name,
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 12,
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF0A1F44,
                                                            ).withOpacity(0.1),
                                                        child: Text(
                                                          name[0].toUpperCase(),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                  0xFF0A1F44,
                                                                ),
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              name,
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            if (a
                                                                .role
                                                                .isNotEmpty)
                                                              Text(
                                                                a.role,
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade600,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                          ],
                                          onChanged: (v) => setState(
                                            () => it.responsible = v,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF0A1F44),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          dropdownColor: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          elevation: 8,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 140,
                                        child: InkWell(
                                          onTap: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate:
                                                  it.dueDate ?? DateTime.now(),
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                            );
                                            if (picked != null)
                                              setState(
                                                () => it.dueDate = picked,
                                              );
                                          },
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Due Date',
                                              filled: true,
                                              fillColor: Colors.grey.shade50,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF0A1F44),
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 12,
                                                  ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 16,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    it.dueDate == null
                                                        ? 'Not set'
                                                        : DateFormat.yMMMd()
                                                              .format(
                                                                it.dueDate!,
                                                              ),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: it.dueDate == null
                                                          ? Colors.grey.shade600
                                                          : const Color(
                                                              0xFF0A1F44,
                                                            ),
                                                      fontWeight:
                                                          it.dueDate == null
                                                          ? FontWeight.normal
                                                          : FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
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
                        ),
                      ),
                    );
                  })
                  .values
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attachments',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addAttachment,
                  icon: Icon(Icons.attach_file),
                  label: Text('Add File'),
                ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _attachments.map((f) {
                return Chip(
                  label: Text(f),
                  avatar: Icon(Icons.insert_drive_file),
                  onDeleted: () => setState(() => _attachments.remove(f)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Summary Preview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _generateSummary,
                  child: Text('Generate Summary'),
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _summary.isEmpty ? 'No summary generated yet' : _summary,
                style: TextStyle(height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _generateSummary(),
            icon: const Icon(Icons.summarize),
            label: const Text('Generate Summary'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitMinutes,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.cloud_upload),
            label: Text(_isSubmitting ? 'Saving...' : 'Save Minutes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1F44),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// Models
class Attendee {
  String name;
  String role;
  String? id;
  String status;
  String phone;

  Attendee({
    required this.name,
    this.role = '',
    this.id,
    this.status = AttendeeStatus.present,
    this.phone = '',
  });
}

class AttendeeStatus {
  static const present = 'present';
  static const absentWithApology = 'absent_with_apology';
  static const absentWithoutApology = 'absent_without_apology';
}

class AgendaItem {
  String title;
  String notes;
  bool expanded;
  List<String> attachments;

  AgendaItem({
    required this.title,
    this.notes = '',
    this.expanded = true,
    List<String>? attachments,
  }) : attachments = attachments ?? [];
}

class ActionItem {
  String description;
  String? responsible;
  DateTime? dueDate;
  String status;

  ActionItem({
    required this.description,
    this.responsible,
    this.dueDate,
    this.status = 'Pending',
  });
}
