import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'dart:convert';

class MeetingMinutesPage extends StatefulWidget {
  const MeetingMinutesPage({Key? key}) : super(key: key);

  @override
  State<MeetingMinutesPage> createState() => _MeetingMinutesPageState();
}

class _MeetingMinutesPageState extends State<MeetingMinutesPage> {
  final _formKey = GlobalKey<FormState>();

  // Dynamic member data from database
  List<Map<String, dynamic>> _members = [];
  bool _loadingMembers = false;
  String? _errorMessage;

  // Form fields
  String? _selectedMeetingType;
  DateTime? _meetingDate;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _agendaTitleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // Dynamic lists / selections
  List<String> _agendas = [
    'Devotion and Prayer',
    'Call to order',
    'Confirmation of previous meeting',
    'Matter arising',
    'Agenda',
    'A.O.B',
  ]; // will hold agenda titles; numbering is index+1

  // Agenda details for each item
  Map<String, String> _agendaDetails = {};
  String? _selectedAgenda;
  final TextEditingController _agendaSearchController = TextEditingController();
  String _agendaSearchQuery = '';
  final Set<String> _apologies = {};
  final Set<String> _present = {};

  // PDF upload state
  String? _selectedPdfPath;

  // Auto-generated minute number
  String _minuteNumber = '';

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _agendaTitleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _loadingMembers = true;
      _errorMessage = null;
    });

    try {
      final response = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/members'),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['members'] != null) {
          setState(() {
            _members = List<Map<String, dynamic>>.from(body['members']);
            _loadingMembers = false;
          });
        } else {
          setState(() {
            _errorMessage =
                'Failed to load members: ${body['message'] ?? 'Unknown error'}';
            _loadingMembers = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load members. Please try again.';
          _loadingMembers = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading members: $e';
        _loadingMembers = false;
      });
    }
  }

  void _generateMinuteNumber() {
    // Example format: MTGTYPE-YYYYMMDD-HHMMSS
    final ts = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final type = (_selectedMeetingType ?? 'GEN').replaceAll(' ', '');
    setState(() {
      _minuteNumber = '$type-$ts';
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _meetingDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _meetingDate = date;
        _dateController.text = DateFormat('yyyy-MM-dd').format(date);
      });
    }
  }

  Future<void> _showMultiSelectDialog({
    required String title,
    required Set<String> selectedSet,
  }) async {
    if (_loadingMembers) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Loading members...')));
      return;
    }

    if (_errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
      return;
    }

    final picked = Set<String>.from(selectedSet);
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: _members.isEmpty
                ? const Center(child: Text('No members found'))
                : ListView(
              shrinkWrap: true,
                    children: _members.map((member) {
                      final memberName = member['full_name'] ?? 'Unknown';
                      final memberId = member['id']?.toString() ?? '';
                      final displayName = '$memberName (ID: $memberId)';

                return CheckboxListTile(
                        value: picked.contains(memberName),
                        title: Text(displayName),
                        subtitle: Text(member['e_kanisa_number'] ?? ''),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                              picked.add(memberName);
                      } else {
                              picked.remove(memberName);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedSet
                    ..clear()
                    ..addAll(picked);
                  // ensure people in apologies are not in present at same time
                  if (identical(selectedSet, _apologies)) {
                    _present.removeAll(_apologies);
                  } else if (identical(selectedSet, _present)) {
                    _apologies.removeAll(_present);
                  }
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _postMinutes() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_agendas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one agenda item.')),
      );
      return;
    }

    setState(() {
      _loadingMembers = true;
    });

    try {
      // Create complete agenda structure with both titles and details
      final completeAgendas = <Map<String, dynamic>>[];
      for (int i = 0; i < _agendas.length; i++) {
        final agendaTitle = _agendas[i];
        final agendaContent = _agendaDetails[agendaTitle] ?? '';
        completeAgendas.add({
          'id': i + 1,
          'title': agendaTitle,
          'content': agendaContent,
          'completed': agendaContent.isNotEmpty,
        });
      }

      final data = {
        'meetingType': _selectedMeetingType,
        'date': _meetingDate?.toIso8601String(),
        'agendas': completeAgendas, // Send complete agenda structure
        'agendaDetails': _agendaDetails, // Keep for backward compatibility
        'apologies': _apologies.toList(),
        'present': _present.toList(),
        'minuteNumber': _minuteNumber,
        'title': _agendaTitleController.text.isNotEmpty 
            ? _agendaTitleController.text 
            : '${_selectedMeetingType} - ${DateFormat('MMM dd, yyyy').format(_meetingDate!)}',
        'content': _contentController.text,
      };

      print('Sending minutes data to: ${Config.baseUrl}/minutes');
      print('Data: $data');

      final response = await API().postRequest(
        url: Uri.parse('${Config.baseUrl}/minutes'),
        data: data,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minutes posted successfully.')),
        );
        // If a PDF has been selected, upload it and link to this minute
        if (_selectedPdfPath != null && _selectedPdfPath!.isNotEmpty) {
          try {
            final uploadRes = await API().uploadMultipart(
              url: Uri.parse('${Config.baseUrl}/minutes/upload'),
              fields: {
                'minuteNumber': _minuteNumber,
              },
              fileField: 'file',
              filePath: _selectedPdfPath!,
            );
            if (uploadRes.statusCode == 200 || uploadRes.statusCode == 201) {
              API.showSnack(context, 'PDF uploaded successfully.');
            } else {
              API.showSnack(context, 'PDF upload failed (${uploadRes.statusCode}).', success: false);
            }
          } catch (e) {
            API.showSnack(context, 'PDF upload error: $e', success: false);
          }
        }

        // Clear form after successful post
        _clearForm();
      } else {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post minutes: ${body['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      print('Error posting minutes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting minutes: $e')),
      );
    } finally {
      setState(() {
        _loadingMembers = false;
      });
    }
  }

  void _clearForm() {
    setState(() {
      _selectedMeetingType = null;
      _meetingDate = null;
      _dateController.clear();
      _agendaTitleController.clear();
      _contentController.clear();
      _agendas.clear();
      _agendaDetails.clear();
      _selectedAgenda = null;
      _apologies.clear();
      _present.clear();
      _minuteNumber = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Meeting Minutes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0A1F44),
        elevation: 0,
        shadowColor: Colors.transparent,
        actions: [
          if (_errorMessage != null)
            IconButton(
              onPressed: _fetchMembers,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Members',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loading and error states
              if (_loadingMembers)
                const Card(
                  color: Colors.blue,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(width: 16),
                        Text(
                          'Loading members...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_errorMessage != null)
                Card(
                  color: Colors.red.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        TextButton(
                          onPressed: _fetchMembers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_loadingMembers || _errorMessage != null)
                const SizedBox(height: 16),
              // 1. Which Meeting
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.meeting_room,
                            color: const Color(0xFF0A1F44),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Meeting Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMeetingType,
                items: const [
                  DropdownMenuItem(
                    value: 'Board Meeting',
                    child: Text('Board Meeting'),
                  ),
                  DropdownMenuItem(
                    value: 'Finance Committee',
                    child: Text('Finance Committee'),
                  ),
                  DropdownMenuItem(
                    value: 'Project Steering',
                    child: Text('Project Steering'),
                  ),
                  DropdownMenuItem(
                    value: 'Staff Meeting',
                    child: Text('Staff Meeting'),
                  ),
                ],
                        decoration: InputDecoration(
                  labelText: 'Which meeting *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                ),
                onChanged: (v) {
                  setState(() {
                    _selectedMeetingType = v;
                    _generateMinuteNumber();
                  });
                },
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Select meeting type'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Date
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: const Color(0xFF0A1F44),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Meeting Date',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                        decoration: InputDecoration(
                  labelText: 'Date of the meeting *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          suffixIcon: Icon(
                            Icons.calendar_today,
                            color: const Color(0xFF0A1F44),
                          ),
                ),
                onTap: _pickDate,
                validator: (_) =>
                    (_meetingDate == null) ? 'Pick meeting date' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                children: [
                          Icon(Icons.people, color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Members Present',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                  ),
                ],
              ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade50,
                              ),
                              child: GestureDetector(
                                onTap: () => _showMultiSelectDialog(
                                  title: 'Select Members Present',
                                  selectedSet: _present,
                                ),
                                child: Text(
                                  _present.isEmpty
                                      ? 'Tap to select members present'
                                      : '${_present.length} member(s) selected',
                                  style: TextStyle(
                                    color: _present.isEmpty
                                        ? Colors.grey.shade600
                                        : Colors.black87,
                                    fontWeight: _present.isEmpty
                                        ? FontWeight.normal
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showMultiSelectDialog(
                              title: 'Select Members Present',
                              selectedSet: _present,
                            ),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_off, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Apologies',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade50,
                      ),
                      child: GestureDetector(
                        onTap: () => _showMultiSelectDialog(
                          title: 'Select Apologies',
                          selectedSet: _apologies,
                        ),
                            child: Text(
                              _apologies.isEmpty
                                      ? 'Tap to select members with apologies'
                                      : '${_apologies.length} member(s) selected',
                              style: TextStyle(
                                color: _apologies.isEmpty
                                    ? Colors.grey.shade600
                                        : Colors.black87,
                                    fontWeight: _apologies.isEmpty
                                        ? FontWeight.normal
                                        : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                          ElevatedButton.icon(
                    onPressed: () => _showMultiSelectDialog(
                      title: 'Select Apologies',
                      selectedSet: _apologies,
                    ),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                  ),
                ],
              ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Agendas (dropdown + form system)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              Row(
                children: [
                          Icon(Icons.list_alt, color: const Color(0xFF0A1F44)),
                          const SizedBox(width: 8),
                          Text(
                            'Meeting Agendas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search bar for agendas
                      TextFormField(
                        controller: _agendaSearchController,
                        onChanged: (v) => setState(
                          () => _agendaSearchQuery = v.trim().toLowerCase(),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search agenda…',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF0A1F44),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF0A1F44),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF0A1F44),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Alternative: Button-based agenda selection
                      if (_selectedAgenda == null) ...[
                        Text(
                          'Select an agenda item to work on:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _agendas
                              .asMap()
                              .entries
                              .where(
                                (e) =>
                                    _agendaSearchQuery.isEmpty ||
                                    e.value.toLowerCase().contains(
                                      _agendaSearchQuery,
                                    ),
                              )
                              .map((entry) {
                                final index =
                                    entry.key; // original order for numbering
                                final agenda = entry.value;
                                final isCompleted = _agendaDetails.containsKey(
                                  agenda,
                                );

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedAgenda = agenda;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? Colors.green.shade50
                                          : const Color(
                                              0xFF0A1F44,
                                            ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isCompleted
                                            ? Colors.green.shade300
                                            : const Color(0xFF0A1F44),
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: isCompleted
                                                ? Colors.green.shade200
                                                : const Color(
                                                    0xFF0A1F44,
                                                  ).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Center(
                                            child: isCompleted
                                                ? Icon(
                                                    Icons.check,
                                                    size: 12,
                                                    color:
                                                        Colors.green.shade700,
                                                  )
                                                : Text(
                                                    '${index + 1}',
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF0A1F44,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          agenda,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: isCompleted
                                                ? Colors.green.shade800
                                                : const Color(0xFF0A1F44),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Dropdown to select agenda (alternative method)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedAgenda,
                          decoration: InputDecoration(
                            labelText: 'Select Agenda Item',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            prefixIcon: const Icon(
                              Icons.list_alt,
                              color: Color(0xFF0A1F44),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF0A1F44),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF0A1F44),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          hint: const Text('Choose an agenda item to work on'),
                          isExpanded: true,
                          isDense: true,
                          menuMaxHeight: 320,
                          dropdownColor: Colors.white,
                          icon: const Icon(
                            Icons.expand_more,
                            color: Color(0xFF0A1F44),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0A1F44),
                          ),
                          items: _agendas
                              .asMap()
                              .entries
                              .where(
                                (e) =>
                                    _agendaSearchQuery.isEmpty ||
                                    e.value.toLowerCase().contains(
                                      _agendaSearchQuery,
                                    ),
                              )
                              .map((entry) {
                                final index = entry.key;
                                final agenda = entry.value;
                                return DropdownMenuItem<String>(
                                  value: agenda,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Center(
                            child: Text(
                                              '${index + 1}',
                              style: TextStyle(
                                                color: Colors.orange.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            agenda,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedAgenda = value;
                            });
                          },
                          validator: (value) => value == null
                              ? 'Please select an agenda item'
                              : null,
                        ),
                      ),

                      // Expanded form for selected agenda
                      if (_selectedAgenda != null) ...[
                        const SizedBox(height: 16),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1F44).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF0A1F44),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0A1F44).withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with agenda info
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0A1F44,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(
                                        0xFF0A1F44,
                                      ).withOpacity(0.2),
                                      child: Text(
                                        '${_agendas.indexOf(_selectedAgenda!) + 1}',
                                        style: TextStyle(
                                          color: const Color(0xFF0A1F44),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Agenda ${_agendas.indexOf(_selectedAgenda!) + 1}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFF0A1F44),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            _selectedAgenda!,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF0A1F44),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedAgenda = null;
                                            });
                                          },
                                          icon: Icon(
                                            Icons.arrow_back,
                                            color: const Color(0xFF0A1F44),
                                          ),
                                          tooltip: 'Back to agenda selection',
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedAgenda = null;
                                            });
                                          },
                                          icon: Icon(
                                            Icons.close,
                                            color: const Color(0xFF0A1F44),
                                          ),
                                          tooltip: 'Close agenda',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
              ),
              const SizedBox(height: 16),

                              // Content writing area
                              Text(
                                'Write the content for this agenda item:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: TextFormField(
                                  initialValue:
                                      _agendaDetails[_selectedAgenda] ?? '',
                                  maxLines: 8,
                                  minLines: 4,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Enter detailed notes, decisions, discussions, or outcomes for "${_selectedAgenda}"...\n\nExample:\n- Key points discussed\n- Decisions made\n- Action items assigned\n- Next steps',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _agendaDetails[_selectedAgenda!] = value;
                                    });
                                  },
                                ),
                              ),

                              // Character count and save indicator
              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(_agendaDetails[_selectedAgenda] ?? '').length} characters',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (_agendaDetails[_selectedAgenda]
                                          ?.isNotEmpty ==
                                      true)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Colors.green.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Saved',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Show completed agenda items
                      if (_agendaDetails.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.checklist,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Completed Agenda Items (${_agendaDetails.length}/${_agendas.length})',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
              ),
              const SizedBox(height: 12),
                              ..._agendaDetails.entries.map((entry) {
                                final agenda = entry.key;
                                final details = entry.value;
                                final index = _agendas.indexOf(agenda);
                                final isSelected = _selectedAgenda == agenda;

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Card(
                                    elevation: isSelected ? 3 : 1,
                                    color: isSelected
                                        ? Colors.blue.shade50
                                        : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isSelected
                                            ? Colors.blue.shade300
                                            : Colors.grey.shade200,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isSelected
                                            ? Colors.blue.shade100
                                            : Colors.green.shade100,
                                        child: Icon(
                                          isSelected ? Icons.edit : Icons.check,
                                          color: isSelected
                                              ? Colors.blue.shade700
                                              : Colors.green.shade700,
                                          size: 16,
                                        ),
                                      ),
                                      title: Text(
                                        '${index + 1}. $agenda',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.blue.shade800
                                              : Colors.grey.shade800,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            details.length > 80
                                                ? '${details.substring(0, 80)}...'
                                                : details,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (details.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.text_fields,
                                                  size: 12,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${details.length} characters',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isSelected
                                                  ? Icons.close
                                                  : Icons.edit,
                                              color: isSelected
                                                  ? Colors.red.shade600
                                                  : Colors.blue.shade600,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (isSelected) {
                                                  _selectedAgenda = null;
                                                } else {
                                                  _selectedAgenda = agenda;
                                                }
                                              });
                                            },
                                            tooltip: isSelected
                                                ? 'Close editing'
                                                : 'Edit this agenda',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Apologies (multi-select)

              // 9. Post button
              Container(
                margin: const EdgeInsets.only(top: 24, bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );
                      if (result != null && result.files.single.path != null) {
                        setState(() {
                          _selectedPdfPath = result.files.single.path!;
                        });
                        API.showSnack(context, 'PDF attached');
                      }
                    } catch (e) {
                      API.showSnack(context, 'Failed to pick PDF: $e', success: false);
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                  label: Text(
                    _selectedPdfPath == null ? 'Attach PDF (optional)' : 'PDF attached',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_present.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Select at least one member present'),
                        ),
                      );
                      return;
                    }
                    _generateMinuteNumber();
                    _postMinutes();
                  },
                  icon: const Icon(Icons.send, size: 20),
                  label: const Text(
                    'Post Minutes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1F44),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
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
