import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:pcea_church/components/responsive_layout.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';

class ViewEventsScreen extends StatefulWidget {
  const ViewEventsScreen({super.key});

  @override
  State<ViewEventsScreen> createState() => _ViewEventsScreenState();
}

class _ViewEventsScreenState extends State<ViewEventsScreen> {
  bool _isLoading = false;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _events = [];
  String? _error;

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
        url: Uri.parse('${Config.baseUrl}/member/events'),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>?;

        if (body != null) {
          List<Map<String, dynamic>> items = [];

          // Handle different response formats
          if (body['events'] is List) {
            items = List<Map<String, dynamic>>.from(body['events']);
            debugPrint('Loaded ${items.length} events from events array');
          } else if (body['data'] is List) {
            items = List<Map<String, dynamic>>.from(body['data']);
            debugPrint('Loaded ${items.length} events from data array');
          } else if (body['status'] == 200 && body.containsKey('events')) {
            // Handle nested events structure
            final eventsData = body['events'];
            if (eventsData is List) {
              items = List<Map<String, dynamic>>.from(eventsData);
            } else if (eventsData is Map && eventsData['data'] is List) {
              items = List<Map<String, dynamic>>.from(eventsData['data']);
            }
            debugPrint('Loaded ${items.length} events from nested structure');
          }

          // Log if no events found but response was successful
          if (items.isEmpty && body['status'] == 200) {
            debugPrint(
              'No events found in response. Response body: ${res.body}',
            );
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

          debugPrint('Successfully loaded and sorted ${items.length} events');
        } else {
          debugPrint('Response body is null or invalid');
          setState(() {
            _events = [];
            _error = 'Invalid response from server';
          });
        }
      } else {
        final errorBody = jsonDecode(res.body) as Map<String, dynamic>?;
        final errorMessage =
            errorBody?['message']?.toString() ??
            'Failed to load events (status ${res.statusCode})';
        debugPrint('Error loading events: $errorMessage');
        setState(() {
          _events = [];
          _error = errorMessage;
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
      // Handle both string and null values from backend
      final startTime = event['start_time'];
      final endTime = event['end_time'];

      // Convert to string if not null, otherwise use null
      final startTimeStr = startTime != null ? startTime.toString() : null;
      final endTimeStr = endTime != null && endTime != 'null'
          ? endTime.toString()
          : null;

      if (startTimeStr != null &&
          startTimeStr.isNotEmpty &&
          startTimeStr != 'null') {
        // Handle time format with or without seconds (e.g., "06:30:00" or "06:30")
        final timeParts = startTimeStr.split(':');
        if (timeParts.length >= 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final start = TimeOfDay(hour: hour, minute: minute);
          final startFormatted = DateFormat.jm().format(
            DateTime(2000, 1, 1, start.hour, start.minute),
          );

          // Only show end time if it exists and is not null
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Church Events',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF0A1F44),
          elevation: 0,
        ),
        body: _buildBody(),
      ),
      desktop: Scaffold(
        body: DesktopScaffoldFrame(
          title: 'Church Events',
          primaryColor: const Color(0xFF35C2C1),
          child: DesktopPageShell(child: _buildBody()),
        ),
      ),
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
                  backgroundColor: const Color(0xFF35C2C1),
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
                      'No upcoming events',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No events have been scheduled for your congregation yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
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
    final creator = event['creator'] != null
        ? event['creator']['full_name']?.toString()
        : null;

    return Card(
      elevation: isPast ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isPast ? Colors.grey.shade50 : Colors.white,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(16),
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
                          : const Color(0xFF35C2C1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event,
                      color: isPast
                          ? Colors.grey.shade600
                          : const Color(0xFF35C2C1),
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
              if (creator != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: Colors.black),
                    const SizedBox(width: 4),
                    Text(
                      'Created by Elder: $creator',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetails(Map<String, dynamic> event) {
    final title = event['title']?.toString() ?? 'Untitled Event';
    final description = event['description']?.toString();
    final location = event['location']?.toString();
    final dateStr = _formatEventDate(event);
    final timeStr = _formatEventTime(event);
    final creator = event['creator'] != null
        ? event['creator']['full_name']?.toString()
        : null;
    final isPast = _isEventPast(event);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isPast
                          ? Colors.grey.shade300
                          : const Color(0xFF35C2C1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.event,
                      color: isPast
                          ? Colors.grey.shade600
                          : const Color(0xFF35C2C1),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A1F44),
                          ),
                        ),
                        if (isPast)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Past Event',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.calendar_today, dateStr),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.access_time, timeStr),
              if (location != null && location.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow(Icons.location_on, location),
              ],
              if (creator != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(Icons.person_outline, 'Created by $creator'),
              ],
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1F44),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }
}
