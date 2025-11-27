import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pcea_church/components/responsive_layout.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/screen/elder_events_screen.dart';

class ElderEventsListScreen extends StatefulWidget {
  const ElderEventsListScreen({super.key});

  @override
  State<ElderEventsListScreen> createState() => _ElderEventsListScreenState();
}

class _ElderEventsListScreenState extends State<ElderEventsListScreen> {
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isDeleting = false;
  List<Map<String, dynamic>> _events = [];
  String? _error;
  int? _deletingEventId;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() => _isRefreshing = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final res = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/elder/events'),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>?;
        if (body != null && body['status'] == 200) {
          List<Map<String, dynamic>> items = [];

          if (body['events'] is List) {
            items = List<Map<String, dynamic>>.from(body['events']);
          } else if (body['data'] is List) {
            items = List<Map<String, dynamic>>.from(body['data']);
          }

          // Sort events: upcoming first, then past
          items.sort((a, b) {
            final aDate = _parseEventDateTime(a);
            final bDate = _parseEventDateTime(b);
            final aIsPast = aDate.isBefore(DateTime.now());
            final bIsPast = bDate.isBefore(DateTime.now());

            // Upcoming events first
            if (aIsPast != bIsPast) {
              return aIsPast ? 1 : -1;
            }

            // Then sort by date (upcoming: ascending, past: descending)
            if (aIsPast) {
              return bDate.compareTo(aDate); // Past events: most recent first
            } else {
              return aDate.compareTo(bDate); // Upcoming events: soonest first
            }
          });

          setState(() {
            _events = items;
            _error = null;
          });
        } else {
          setState(() {
            _events = [];
            _error = body?['message']?.toString() ?? 'Failed to load events';
          });
        }
      } else {
        setState(() {
          _events = [];
          _error = 'Failed to load events (status ${res.statusCode})';
        });
      }
    } catch (e) {
      debugPrint('Error loading events: $e');
      setState(() {
        _events = [];
        _error = 'Failed to load events. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
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
        return DateFormat('EEEE, MMMM d, y').format(date);
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
      final startTime = event['start_time'];
      final endTime = event['end_time'];

      final startTimeStr = startTime != null ? startTime.toString() : null;
      final endTimeStr = endTime != null && endTime != 'null'
          ? endTime.toString()
          : null;

      if (startTimeStr != null &&
          startTimeStr.isNotEmpty &&
          startTimeStr != 'null') {
        final timeParts = startTimeStr.split(':');
        if (timeParts.length >= 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final start = TimeOfDay(hour: hour, minute: minute);
          final startFormatted = DateFormat.jm().format(
            DateTime(2000, 1, 1, start.hour, start.minute),
          );

          if (endTimeStr != null &&
              endTimeStr.isNotEmpty &&
              endTimeStr != 'null') {
            final endTimeParts = endTimeStr.split(':');
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

  bool _isEventPast(Map<String, dynamic> event) {
    final eventDateTime = _parseEventDateTime(event);
    return eventDateTime.isBefore(DateTime.now());
  }

  Future<void> _deleteEvent(int eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
          'Are you sure you want to delete this event? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
      _deletingEventId = eventId;
    });

    try {
      final res = await API().deleteRequest(
        url: Uri.parse('${Config.baseUrl}/elder/events/$eventId'),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>? ?? {};

      if (res.statusCode == 200 || body['status'] == 200) {
        API.showSnack(
          context,
          body['message']?.toString() ?? 'Event deleted successfully',
          success: true,
        );
        await _loadEvents();
      } else {
        API.showSnack(
          context,
          body['message']?.toString() ?? 'Failed to delete event',
          success: false,
        );
      }
    } catch (e) {
      debugPrint('Error deleting event: $e');
      API.showSnack(
        context,
        'Something went wrong while deleting the event',
        success: false,
      );
    } finally {
      setState(() {
        _isDeleting = false;
        _deletingEventId = null;
      });
    }
  }

  void _navigateToEditEvent(Map<String, dynamic> event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ElderEventsScreen(editingEvent: event),
      ),
    ).then((_) {
      // Reload events when returning from edit page
      _loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: Scaffold(
        appBar: AppBar(
          title: const Text('My Events', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF0A1F44),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ElderEventsScreen(),
                  ),
                ).then((_) => _loadEvents());
              },
              tooltip: 'Create New Event',
            ),
          ],
        ),
        body: _buildBody(),
      ),
      desktop: Scaffold(
        body: DesktopScaffoldFrame(
          title: '',
          primaryColor: const Color(0xFF35C2C1),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'My Events',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ElderEventsScreen(),
                          ),
                        ).then((_) => _loadEvents());
                      },
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Create New Event',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: DesktopPageShell(child: _buildBody())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null && _events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadEvents(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_events.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadEvents(isRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No events yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first event to share with your congregation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ElderEventsScreen(),
                          ),
                        ).then((_) => _loadEvents());
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Separate upcoming and past events
    final upcomingEvents = _events.where((e) => !_isEventPast(e)).toList();
    final pastEvents = _events.where((e) => _isEventPast(e)).toList();

    return RefreshIndicator(
      onRefresh: () => _loadEvents(isRefresh: true),
      child: CustomScrollView(
        slivers: [
          if (_isRefreshing)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (upcomingEvents.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Upcoming Events',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _buildEventCard(upcomingEvents[index], false);
                }, childCount: upcomingEvents.length),
              ),
            ),
          ],
          if (pastEvents.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Past Events',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildEventCard(pastEvents[index], true),
                  );
                }, childCount: pastEvents.length),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, bool isPast) {
    final title = event['title']?.toString() ?? 'Untitled Event';
    final description = event['description']?.toString();
    final location = event['location']?.toString();
    final dateStr = _formatEventDate(event);
    final timeStr = _formatEventTime(event);
    final eventId = event['id'] as int?;
    final isDeleting = _isDeleting && _deletingEventId == eventId;

    return Card(
      elevation: isPast ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isPast ? Colors.grey.shade50 : Colors.white,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.grey.shade300
                        : const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event,
                    color: isPast
                        ? Colors.grey.shade600
                        : const Color(0xFF2E7D32),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isPast
                              ? Colors.grey.shade700
                              : const Color(0xFF0A1F44),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      if (location != null && location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
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
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _isDeleting
                      ? null
                      : () => _navigateToEditEvent(event),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _isDeleting || eventId == null
                      ? null
                      : () => _deleteEvent(eventId),
                  icon: isDeleting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

