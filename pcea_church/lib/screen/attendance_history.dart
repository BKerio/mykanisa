import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pcea_church/config/api_connection.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({Key? key}) : super(key: key);

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  bool _isLoading = true;
  List<dynamic> _attendanceList = [];
  String? _error;
  
  // Date Filters
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Event Type Filter
  String? _selectedEventType;
  final List<String> _eventTypes = [
    "All",
    "Sunday Service",
    "Holy Communion",
    "Weekly Meeting",
    "AGM",
    "Other"
  ];
  
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _fetchAttendanceHistory();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0A1F44),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0A1F44),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isLoading = true;
      });
      _fetchAttendanceHistory();
    }
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedEventType = null;
      _isLoading = true;
    });
    _fetchAttendanceHistory();
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    
    // Calculate stats
    final totalPresent = _attendanceList.length;
    final String dateRangeText = _startDate != null && _endDate != null 
        ? "${DateFormat('MMM d, y').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}"
        : "All Time";
    final String eventTypeText = _selectedEventType != null && _selectedEventType != "All"
        ? " ($_selectedEventType)"
        : "";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Attendance Report$eventTypeText", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(dateRangeText, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border(left: pw.BorderSide(color: PdfColors.blue, width: 4))
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Summary", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.SizedBox(height: 5),
                  pw.Text("Total Attendance: $totalPresent events attended."),
                  pw.Text("Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}"),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
              cellAlignment: pw.Alignment.centerLeft,
              data: <List<String>>[
                <String>['Date', 'Event', 'Check-in Time', 'Status'],
                ..._attendanceList.map((record) => <String>[
                  DateFormat('yyyy-MM-dd').format(DateTime.parse(record['event_date'])),
                  (record['event_type'] ?? 'Event').toString(),
                  DateFormat('h:mm a').format(DateTime.parse(record['scanned_at'])),
                  'Present'
                ]).toList(),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'attendance_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  Future<void> _fetchAttendanceHistory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString(
        'token',
      ); // Adjust key if different in your app

      if (token == null) {
        setState(() {
          _error = "Authentication token not found. Please log in.";
          _isLoading = false;
        });
        return;
      }

      Uri url = Uri.parse(API.memberAttendance);
      
      // Add query parameters if dates are selected
      if (_startDate != null && _endDate != null) {
        String start = _dateFormat.format(_startDate!);
        String end = _dateFormat.format(_endDate!);
        // Append correctly
        if (url.query.isEmpty) {
             url = Uri.parse("${API.memberAttendance}?start_date=$start&end_date=$end");
        } else {
             // This branch unlikely hit with current logic but good practice
             url = Uri.parse("$url&start_date=$start&end_date=$end");
        }
      }
      
      if (_selectedEventType != null && _selectedEventType != "All") {
        String eventParam = _selectedEventType!;
        if (url.query.isEmpty) {
            url = Uri.parse("${API.memberAttendance}?event_type=$eventParam");
        } else {
            url = Uri.parse("$url&event_type=$eventParam");
        }
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200) {
          setState(() {
            _attendanceList =
                data['data']['data']; // Laravel pagination structure
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? "Failed to load data";
            _isLoading = false;
          });
        }
      } else {
        String errorMessage = "Server error: ${response.statusCode}";
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (_) {}

        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Connection error: $e";
        _isLoading = false;
      });
    }
  }

  void _showEventTypePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Select Event Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._eventTypes.map((type) {
                final isSelected = (_selectedEventType ?? "All") == type;
                return ListTile(
                  leading: Icon(
                    type == "All" ? Icons.calendar_view_month : Icons.event,
                    color: isSelected ? const Color(0xFF0A1F44) : Colors.grey,
                  ),
                  title: Text(
                    type == "All" ? "All Event Types" : type,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF0A1F44) : Colors.black,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFF0A1F44))
                      : null,
                  onTap: () {
                    setState(() {
                       _selectedEventType = type;
                       _isLoading = true;
                    });
                    Navigator.pop(context);
                    _fetchAttendanceHistory();
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Attendance History"),
        backgroundColor: const Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
            if (_attendanceList.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Export PDF',
                onPressed: _generatePdf,
              ),
        ],
      ),
      body: Column(
        children: [
            // Date Filter Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey[50],
              child: Column(
                children: [
                    // Date Filter Row
                    Row(
                        children: [
                            Expanded(
                                child: InkWell(
                                    onTap: _selectDateRange,
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                        decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.white,
                                        ),
                                        child: Row(
                                            children: [
                                                Icon(Icons.calendar_today, size: 18, color: const Color(0xFF0A1F44)),
                                                const SizedBox(width: 8),
                                                Text(
                                                    _startDate != null && _endDate != null
                                                        ? "${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}"
                                                        : "Filter by Date Range",
                                                    style: TextStyle(
                                                        color: _startDate != null ? const Color(0xFF0A1F44) : Colors.grey[600],
                                                        fontWeight: _startDate != null ? FontWeight.w600 : FontWeight.normal
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                ),
                            ),
                            const SizedBox(width: 12),
                            // Clear Button Logic
                            if (_startDate != null || (_selectedEventType != null && _selectedEventType != "All"))
                                IconButton(
                                    icon: const Icon(Icons.close, color: Colors.grey),
                                    onPressed: _clearFilter,
                                    tooltip: "Clear All Filters",
                                )
                            else
                                Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF0A1F44).withOpacity(0.1),
                                        shape: BoxShape.circle
                                    ),
                                    child: const Icon(Icons.filter_list, size: 20, color: Color(0xFF0A1F44)),
                                )
                        ],
                    ),
                    const SizedBox(height: 12),
                    
                    // NEW Event Type Picker (Matching Group Leader Dashboard Style)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14), // Matches reference
                        boxShadow: [
                           // Optional subtle shadow if desired, reference had it on parent container
                        ],
                      ),
                      child: GestureDetector(
                        onTap: () => _showEventTypePicker(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_note, color: Color(0xFF0A1F44)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Event Type',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (_selectedEventType == null || _selectedEventType == "All") 
                                          ? 'All Event Types' 
                                          : _selectedEventType!,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            Expanded(child: _isLoading
          ? Center(
              child: SpinKitFadingCircle(
                size: 64,
                duration: const Duration(
                  milliseconds: 1800,
                ), // Adjusted duration
                itemBuilder: (context, index) {
                  final palette = const [
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
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _fetchAttendanceHistory();
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            )
          : _attendanceList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "No attendance records found yet.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchAttendanceHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _attendanceList.length,
                itemBuilder: (context, index) {
                  final record = _attendanceList[index];
                  final date = DateTime.parse(record['event_date']);
                  final scannedAt = DateTime.parse(record['scanned_at']);
                  final eventType = record['event_type'] ?? 'Event';

                  // Determine icon based on event type
                  IconData eventIcon = Icons.event;
                  Color iconColor = Color(0xFF0A1F44);

                  if (eventType.toString().toLowerCase().contains('sunday')) {
                    eventIcon = Icons.church_rounded;
                    iconColor = Color(0xFF0A1F44);
                  } else if (eventType.toString().toLowerCase().contains(
                    'communion',
                  )) {
                    eventIcon = Icons.local_bar;
                    iconColor = Color(0xFF0A1F44);
                  } else if (eventType.toString().toLowerCase().contains(
                    'meeting',
                  )) {
                    eventIcon = Icons.groups;
                    iconColor = Color(0xFF0A1F44);
                  }

                  return Card(
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(eventIcon, color: iconColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eventType,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 12,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat(
                                        'EEEE, MMM d, yyyy',
                                      ).format(date),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                DateFormat('h:mm a').format(scannedAt),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.green[100]!),
                                ),
                                child: const Text(
                                  'Present',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            )
        ]
    ),
    );
  }
}
