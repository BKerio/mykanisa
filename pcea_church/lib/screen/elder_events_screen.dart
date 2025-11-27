import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pcea_church/components/responsive_layout.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/screen/elder_events_list.dart';

class ElderEventsScreen extends StatefulWidget {
  final Map<String, dynamic>? editingEvent;

  const ElderEventsScreen({super.key, this.editingEvent});

  @override
  State<ElderEventsScreen> createState() => _ElderEventsScreenState();
}

class _ElderEventsScreenState extends State<ElderEventsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isAllDay = false;
  bool _isSaving = false;
  int? _editingEventId; // Track which event is being edited

  @override
  void initState() {
    super.initState();
    // If editing an event, load its data into the form
    if (widget.editingEvent != null) {
      _loadEventForEditing(widget.editingEvent!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? (_startTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  void _loadEventForEditing(Map<String, dynamic> event) {
    final eventId = event['id'];
    if (eventId == null) return;

    setState(() {
      _editingEventId = eventId as int;
      _titleController.text = event['title']?.toString() ?? '';
      _descriptionController.text = event['description']?.toString() ?? '';
      _locationController.text = event['location']?.toString() ?? '';
      _isAllDay = event['is_all_day'] == true || event['is_all_day'] == 1;

      // Parse event date
      final eventDate = event['event_date']?.toString();
      if (eventDate != null) {
        try {
          _selectedDate = DateTime.parse(eventDate);
        } catch (e) {
          debugPrint('Error parsing event date: $e');
        }
      }

      // Parse start time
      final startTime = event['start_time']?.toString();
      if (startTime != null && startTime.isNotEmpty && !_isAllDay) {
        try {
          final timeParts = startTime.split(':');
          if (timeParts.length >= 2) {
            _startTime = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
          }
        } catch (e) {
          debugPrint('Error parsing start time: $e');
        }
      }

      // Parse end time
      final endTime = event['end_time']?.toString();
      if (endTime != null && endTime.isNotEmpty && !_isAllDay) {
        try {
          final timeParts = endTime.split(':');
          if (timeParts.length >= 2) {
            _endTime = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
          }
        } catch (e) {
          debugPrint('Error parsing end time: $e');
        }
      }
    });

    // Scroll to form (for mobile) - handled by the layout
  }

  void _cancelEdit() {
    setState(() {
      _editingEventId = null;
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _selectedDate = null;
      _startTime = null;
      _endTime = null;
      _isAllDay = false;
    });
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showSnack('Please choose a date for the event', false);
      return;
    }

    if (!_isAllDay && _startTime == null) {
      _showSnack('Please select a start time', false);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _startTime?.hour ?? 0,
        _startTime?.minute ?? 0,
      );

      DateTime? endDateTime;
      if (!_isAllDay && _endTime != null) {
        endDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }

      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'start_at': startDateTime.toIso8601String(),
        'all_day': _isAllDay,
        if (endDateTime != null) 'end_at': endDateTime.toIso8601String(),
      };

      final bool isEditing = _editingEventId != null;
      final Uri url = isEditing
          ? Uri.parse('${Config.baseUrl}/elder/events/$_editingEventId')
          : Uri.parse('${Config.baseUrl}/elder/events');

      final res = isEditing
          ? await API().putRequest(url: url, data: payload)
          : await API().postRequest(url: url, data: payload);

      final body = jsonDecode(res.body) as Map<String, dynamic>? ?? {};

      if (res.statusCode == 200 ||
          res.statusCode == 201 ||
          body['status'] == 200) {
        _showSnack(
          body['message']?.toString() ??
              (isEditing
                  ? 'Event updated successfully'
                  : 'Event created and shared with your congregation.'),
          true,
        );
        _cancelEdit();
        // Navigate back to list after successful save
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showSnack(
          body['message']?.toString() ??
              (isEditing ? 'Failed to update event' : 'Failed to create event'),
          false,
        );
      }
    } catch (e) {
      debugPrint('Error saving event: $e');
      _showSnack(
        'Something went wrong while ${_editingEventId != null ? 'updating' : 'saving'} the event',
        false,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, bool success) {
    API.showSnack(context, message, success: success);
  }

  DateTime _parseEventDateTime(Map<String, dynamic> event) {
    try {
      final eventDate = event['event_date']?.toString();
      final startTime = event['start_time']?.toString();

      if (eventDate != null) {
        final date = DateTime.parse(eventDate);
        if (startTime != null && startTime.isNotEmpty) {
          final timeParts = startTime.split(':');
          if (timeParts.length >= 2) {
            return DateTime(
              date.year,
              date.month,
              date.day,
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
            );
          }
        }
        return date;
      }
    } catch (e) {
      debugPrint('Error parsing event date: $e');
    }
    return DateTime.now();
  }

  String _formatEventDate(Map<String, dynamic> event) {
    try {
      final eventDate = event['event_date']?.toString();
      if (eventDate != null) {
        final date = DateTime.parse(eventDate);
        return DateFormat.yMMMd().format(date);
      }
    } catch (e) {
      debugPrint('Error formatting date: $e');
    }
    return 'Date TBD';
  }

  String _formatEventTime(Map<String, dynamic> event) {
    final isAllDay = event['is_all_day'] == true || event['is_all_day'] == 1;
    if (isAllDay) {
      return 'All Day';
    }

    try {
      final startTime = event['start_time']?.toString();
      final endTime = event['end_time']?.toString();

      if (startTime != null && startTime.isNotEmpty) {
        final timeParts = startTime.split(':');
        if (timeParts.length >= 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final start = TimeOfDay(hour: hour, minute: minute);
          final startFormatted = DateFormat.jm().format(
            DateTime(2000, 1, 1, start.hour, start.minute),
          );

          if (endTime != null && endTime.isNotEmpty) {
            final endTimeParts = endTime.split(':');
            if (endTimeParts.length >= 2) {
              final endHour = int.parse(endTimeParts[0]);
              final endMinute = int.parse(endTimeParts[1]);
              final end = TimeOfDay(hour: endHour, minute: endMinute);
              final endFormatted = DateFormat.jm().format(
                DateTime(2000, 1, 1, end.hour, end.minute),
              );
              return '$startFormatted - $endFormatted';
            }
          }

          return startFormatted;
        }
      }
    } catch (e) {
      debugPrint('Error formatting time: $e');
    }
    return 'Time TBD';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0A1F44),
        title: Text(
          _editingEventId != null ? 'Edit Event' : 'Create Event',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white, size: 30),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ElderEventsListScreen(),
                ),
              );
            },
            tooltip: 'View All Events',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE8F4FD),
      body: Stack(
        children: [
          ResponsiveLayout(
            mobile: _buildMobileLayout(),
            desktop: _buildDesktopLayout(),
          ),
          // Fixed button at bottom right
          Positioned(
            right: 16,
            bottom: 16,
            child: _editingEventId != null
                ? ElevatedButton.icon(
                    onPressed: () {
                      // Clear form and start new event
                      _cancelEdit();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New Event'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      elevation: 6,
                      shadowColor: Colors.black.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildFormCard(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return DesktopScaffoldFrame(
      title: '',
      primaryColor: const Color(0xFF35C2C1),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildFormCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _editingEventId != null ? 'Edit Event' : 'Create new event',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A1F44),
                    ),
                  ),
                ),
                if (_editingEventId != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSaving ? null : _cancelEdit,
                    tooltip: 'Cancel editing',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _editingEventId != null
                  ? 'Update the event details below.'
                  : 'Plan and share upcoming events with all members in your congregation.',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Event title *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (e.g. Main Sanctuary)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _selectedDate == null
                          ? 'Select date *'
                          : DateFormat.yMMMMd().format(_selectedDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('All day'),
                    value: _isAllDay,
                    onChanged: (v) {
                      setState(() {
                        _isAllDay = v;
                        if (v) {
                          _startTime = null;
                          _endTime = null;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            if (!_isAllDay) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStartTime,
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        _startTime == null
                            ? 'Start time *'
                            : _startTime!.format(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickEndTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _endTime == null
                            ? 'End time (optional)'
                            : _endTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSaving
                      ? (_editingEventId != null ? 'Updating...' : 'Saving...')
                      : (_editingEventId != null
                            ? 'Update Event'
                            : 'Save & share with congregation'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _saveEvent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
