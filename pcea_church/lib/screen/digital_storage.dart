import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pcea_church/config/server.dart';
import 'dart:convert';
import '../method/api.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class MemberDigitalFileScreen extends StatefulWidget {
  const MemberDigitalFileScreen({super.key});

  @override
  State<MemberDigitalFileScreen> createState() =>
      _MemberDigitalFileScreenState();
}

class _MemberDigitalFileScreenState extends State<MemberDigitalFileScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _digitalFile;
  TabController? _tabController;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 7,
      vsync: this,
    ); // Profile, Family, Attendance, Finance, Tasks, Comm, Logs
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchMember(String query) async {
    if (query.trim().isEmpty) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _digitalFile = null;
      });
    }

    try {
      final searchRes = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/elder/members?q=$query'),
      );

      if (searchRes.statusCode == 200) {
        final data = jsonDecode(searchRes.body);
        final members = data['data'];

        if (members != null && (members as List).isNotEmpty) {
          final memberId = members[0]['id'];
          await _fetchDigitalFile(memberId);
        } else {
          _showError('No member found matching "$query"');
        }
      } else {
        _showError('Search failed');
      }
    } catch (e) {
      _showError('Error searching member: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDigitalFile(int id) async {
    try {
      final response = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/elder/members/$id/digital-file'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _digitalFile = data['data'];
            // Reset to first tab when new data loads to ensure UI consistency
            _tabController?.animateTo(0);
          });
        }
      } else {
        _showError('Failed to load digital file');
      }
    } catch (e) {
      _showError('Error fetching digital file: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _generatePdf() async {
    if (_digitalFile == null) return;

    final pdf = pw.Document();
    final profile = _digitalFile!['profile'];
    await PdfGoogleFonts.nunitoExtraLight();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontRegular = await PdfGoogleFonts.nunitoRegular();

    // Helper for section headers
    pw.Widget sectionHeader(String title) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                font: fontBold,
                color: PdfColors.green800,
              ),
            ),
            pw.Divider(color: PdfColors.green800),
          ],
        ),
      );
    }

    // Helper for key-value info rows
    pw.Widget infoRow(String label, String? value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 120,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  color: PdfColors.grey700,
                  font: fontRegular,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value ?? '-',
                style: pw.TextStyle(font: fontRegular, fontSize: 10),
              ),
            ),
          ],
        ),
      );
    }

    // Helper for table headers
    pw.TextStyle headerStyle() => pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      font: fontBold,
      fontSize: 10,
      color: PdfColors.white,
    );
    pw.TextStyle cellStyle() => pw.TextStyle(font: fontRegular, fontSize: 10);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // --- Header ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PCEA SGM CHURCH',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        font: fontBold,
                        color: PdfColor(10 / 255, 31 / 255, 68 / 255),
                      ),
                    ),
                    pw.Text(
                      'Member Digital File',
                      style: pw.TextStyle(
                        fontSize: 14,
                        font: fontRegular,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Printed: ${_dateTimeFormat.format(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    font: fontRegular,
                    color: PdfColors.grey,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // --- Profile Summary ---
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                color: PdfColors.grey50,
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 60,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColor(10 / 255, 31 / 255, 68 / 255),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        (profile['full_name'] ?? profile['name'] ?? '?')
                            .toString()[0]
                            .toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          font: fontBold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        profile['full_name'] ?? profile['name'] ?? 'Unknown',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          font: fontBold,
                        ),
                      ),
                      pw.Text(
                        profile['e_kanisa_number'] ?? 'No Number',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        profile['email'] ?? '',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // --- Personal Details ---
            sectionHeader('Personal & Church Details'),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      infoRow('Phone', profile['telephone']),
                      infoRow(
                        'National ID',
                        profile['id_number'] ?? profile['national_id'],
                      ),
                      infoRow(
                        'Date of Birth',
                        profile['dob'] ??
                            profile['pk_dob'] ??
                            profile['date_of_birth'],
                      ),
                      infoRow('Gender', profile['gender']),
                      infoRow('Marital Status', profile['marital_status']),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      infoRow('District', profile['district']),
                      infoRow('Congregation', profile['congregation']),
                      infoRow('Parish', profile['parish']),
                      infoRow(
                        'Baptized',
                        (profile['is_baptized'] == true ||
                                profile['is_baptized'] == 1)
                            ? 'Yes'
                            : 'No',
                      ),
                      infoRow(
                        'Holy Communion',
                        (profile['takes_holy_communion'] == true ||
                                profile['takes_holy_communion'] == 1)
                            ? 'Yes'
                            : 'No',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- Family ---
            if ((_digitalFile!['profile']['dependencies'] as List?)
                    ?.isNotEmpty ??
                false) ...[
              sectionHeader('Family & Dependents'),
              pw.Wrap(
                spacing: 10,
                runSpacing: 10,
                children: (_digitalFile!['profile']['dependencies'] as List)
                    .map((d) {
                      return pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey200),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(4),
                          ),
                        ),
                        width: 150,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              d['name'],
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                font: fontBold,
                                fontSize: 10,
                              ),
                            ),
                            pw.Text(
                              'Born: ${d['year_of_birth']}',
                              style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList(),
              ),
            ],

            // --- Attendance ---
            if ((_digitalFile!['attendances'] as List?)?.isNotEmpty ??
                false) ...[
              sectionHeader('Service Attendance History'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.green700,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Event Type', style: headerStyle()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Date', style: headerStyle()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Method', style: headerStyle()),
                      ),
                    ],
                  ),
                  ...(_digitalFile!['attendances'] as List).map((a) {
                    final isScanned = a['scanned_at'] != null;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            a['event_type'] ?? 'Service',
                            style: cellStyle(),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(a['event_date'], style: cellStyle()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            isScanned ? 'Scanned' : 'Manual',
                            style: cellStyle().copyWith(
                              color: isScanned
                                  ? PdfColors.blue800
                                  : PdfColors.black,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],

            // --- Contributions ---
            if ((_digitalFile!['contributions'] as List?)?.isNotEmpty ??
                false) ...[
              sectionHeader('Contributions & Finance'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.teal700,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Type', style: headerStyle()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Date', style: headerStyle()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Amount', style: headerStyle()),
                      ),
                    ],
                  ),
                  ...(_digitalFile!['contributions'] as List).map((c) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            c['contribution_type'].toString().toUpperCase(),
                            style: cellStyle(),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            _dateFormat.format(
                              DateTime.parse(c['contribution_date']),
                            ),
                            style: cellStyle(),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'KES ${c['amount']}',
                            style: cellStyle().copyWith(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],

            // --- Tasks ---
            if ((_digitalFile!['tasks'] as List?)?.isNotEmpty ?? false) ...[
              sectionHeader('Assigned Tasks'),
              pw.Column(
                children: (_digitalFile!['tasks'] as List).map((t) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 5),
                    padding: const pw.EdgeInsets.all(5),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey200),
                      color: PdfColors.orange50,
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Text(t['description'], style: cellStyle()),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          t['status'],
                          style: cellStyle().copyWith(
                            color: t['status'] == 'Done'
                                ? PdfColors.green800
                                : PdfColors.orange800,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            // --- Communications ---
            if ((_digitalFile!['communications'] as List?)?.isNotEmpty ??
                false) ...[
              sectionHeader('Communication Log'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue800,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Context', style: headerStyle()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Subject', style: headerStyle()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Date', style: headerStyle()),
                      ),
                    ],
                  ),
                  ...(_digitalFile!['communications'] as List).map((c) {
                    final profileId = _digitalFile!['profile']['id'];
                    final isOutbound = c['sent_by'] == profileId;
                    String context =
                        c['context'] ??
                        (isOutbound ? 'To Elder' : 'From Elder');

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            context,
                            style: cellStyle().copyWith(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(c['title'] ?? '-', style: cellStyle()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            _dateFormat.format(DateTime.parse(c['created_at'])),
                            style: cellStyle().copyWith(fontSize: 8),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],

            // --- Logs ---
            if ((_digitalFile!['audit_logs'] as List?)?.isNotEmpty ??
                false) ...[
              sectionHeader('Audit Trail'),
              pw.ListView.builder(
                itemCount: (_digitalFile!['audit_logs'] as List)
                    .take(10)
                    .length,
                itemBuilder: (context, index) {
                  final l = (_digitalFile!['audit_logs'] as List)[index];
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text(
                      '• ${l['action']} - ${_dateTimeFormat.format(DateTime.parse(l['created_at']))}',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  );
                },
              ),
            ],
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // _pdfInfoRow helper removed as it's now inside _generatePdf for better font scoping

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Digital File'),
        backgroundColor: const Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        actions: [
          if (_digitalFile != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, size: 30),
              onPressed: _generatePdf,
              tooltip: 'Export PDF',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Phone or ID',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                    ),
                    onSubmitted: _searchMember,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _searchMember(_searchController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1F44),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),

          if (_isLoading)
            Expanded(
              child: Center(
                child: SpinKitFadingCircle(
                  size: 64,
                  duration: const Duration(milliseconds: 1800),
                  itemBuilder: (context, index) {
                    final palette = const [
                      Color(0xFF0A1F44),
                      Color(0xFF8B0000),
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
          else if (_digitalFile != null)
            Expanded(child: _buildFileContent())
          else
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_shared,
                      size: 120,
                      color: Color(0xFF0A1F44),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Search for a member to view their digital file',
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileContent() {
    final profile = _digitalFile!['profile'];

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: profile['profile_image_url'] != null
                    ? NetworkImage(profile['profile_image_url'])
                    : null,
                child: profile['profile_image_url'] == null
                    ? Text(
                        (profile['full_name'] ?? profile['name'] ?? '?')
                            .toString()[0]
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile['full_name'] ??
                          profile['name'] ??
                          'Unknown Member',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      profile['e_kanisa_number'] ?? 'No Number',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      profile['email'] ?? '',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tabs
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0A1F44),
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Family'),
            Tab(text: 'Attendance'),
            Tab(text: 'Finance'),
            Tab(text: 'Tasks'),
            Tab(text: 'Comm.'),
            Tab(text: 'Logs'),
          ],
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(),
              _buildFamilyTab(),
              _buildAttendanceTab(),
              _buildFinanceTab(),
              _buildTasksTab(),
              _buildCommunicationsTab(),
              _buildLogsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    final p = _digitalFile!['profile'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoTile('Phone', p['telephone']),
        _infoTile('National ID', p['id_number'] ?? p['national_id']),
        _infoTile(
          'Date of Birth',
          p['dob'] ?? p['pk_dob'] ?? p['date_of_birth'] ?? '-',
        ),
        _infoTile('Gender', p['gender']),
        _infoTile('Marital Status', p['marital_status']),
        const Divider(),
        _infoTile(
          'Baptized',
          (p['is_baptized'] == true ||
                  p['is_baptized'] == 1 ||
                  p['is_baptized'] == '1')
              ? 'Yes'
              : 'No',
        ),
        _infoTile(
          'Holy Communion',
          (p['takes_holy_communion'] == true ||
                  p['takes_holy_communion'] == 1 ||
                  p['takes_holy_communion'] == '1')
              ? 'Yes'
              : 'No',
        ),
        const Divider(),
        _infoTile('District', p['district']),
        _infoTile('Congregation', p['congregation']),
        _infoTile('Parish', p['parish']),
      ],
    );
  }

  Widget _infoTile(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyTab() {
    final deps = _digitalFile!['profile']['dependencies'] as List?;
    if (deps == null || deps.isEmpty)
      return const Center(child: Text('No dependents listed'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deps.length,
      itemBuilder: (context, index) {
        final d = deps[index];
        final photoUrls = d['photo_urls'] as List?;
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.person, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text('Birth Year: ${d['year_of_birth']}'),
                        ],
                      ),
                    ),
                  ],
                ),
                if (photoUrls != null && photoUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photoUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, pIndex) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            photoUrls[pIndex],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTab() {
    final att = _digitalFile!['attendances'] as List?;
    final meetAtt = _digitalFile!['meeting_attendance'] as List?;

    if ((att == null || att.isEmpty) && (meetAtt == null || meetAtt.isEmpty)) {
      return const Center(child: Text('No attendance records found'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (att != null && att.isNotEmpty) ...[
          const Text(
            'Regular Services',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...att.map((a) {
            final isScanned = a['scanned_at'] != null;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isScanned ? Icons.qr_code_scanner : Icons.event_available,
                color: isScanned ? Colors.blue : Colors.green,
              ),
              title: Text(a['event_type'] ?? 'Service'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_dateFormat.format(DateTime.parse(a['event_date']))),
                  if (isScanned)
                    Text(
                      'Scanned: ${a['scanned_at']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF0A1F44),
                      ),
                    ),
                ],
              ),
            );
          }),
          const Divider(),
        ],
        if (meetAtt != null && meetAtt.isNotEmpty) ...[
          const Text(
            'Meeting Attendance',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...meetAtt.map(
            (m) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.meeting_room, color: Colors.blue),
              title: Text(m['title']),
              subtitle: Text(
                '${m['meeting_type']} • ${_dateFormat.format(DateTime.parse(m['meeting_date']))}',
              ),
              trailing: Chip(
                label: Text(m['status']),
                backgroundColor: m['status'] == 'present'
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                labelStyle: TextStyle(
                  color: m['status'] == 'present' ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFinanceTab() {
    final conts = _digitalFile!['contributions'] as List?;
    if (conts == null || conts.isEmpty)
      return const Center(child: Text('No contribution history'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conts.length,
      itemBuilder: (context, index) {
        final c = conts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF0A1F44),
              child: Icon(Icons.attach_money, color: Colors.white),
            ),
            title: Text(c['contribution_type'].toString().toUpperCase()),
            subtitle: Text(
              _dateFormat.format(DateTime.parse(c['contribution_date'])),
            ),
            trailing: Text(
              'KES ${c['amount']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A1F44),
                fontSize: 15,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTasksTab() {
    final tasks = _digitalFile!['tasks'] as List?;
    if (tasks == null || tasks.isEmpty)
      return const Center(child: Text('No action items assigned'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final t = tasks[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        t['meeting_title'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: t['status'] == 'Done'
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        t['status'],
                        style: TextStyle(
                          fontSize: 10,
                          color: t['status'] == 'Done'
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(t['description'], style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 8),
                if (t['due_date'] != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${_dateFormat.format(DateTime.parse(t['due_date']))}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommunicationsTab() {
    final comms = _digitalFile!['communications'] as List?;
    if (comms == null || comms.isEmpty)
      return const Center(child: Text('No communication history'));

    final profileId = _digitalFile!['profile']['id'];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: comms.length,
      itemBuilder: (context, index) {
        final c = comms[index];
        final isOutbound = c['sent_by'] == profileId; // Sent BY member

        // Determine badge label and color based on context/type
        String contextLabel =
            c['context'] ?? (isOutbound ? 'To Elder' : 'From Elder');
        Color badgeColor = isOutbound
            ? Colors.blue.shade100
            : Colors.green.shade100;
        Color textColor = isOutbound
            ? Colors.blue.shade900
            : Colors.green.shade900;
        if (c['type'] == 'broadcast') {
          badgeColor = Colors.orange.shade100;
          textColor = Colors.orange.shade900;
        } else if (c['type'] == 'group') {
          badgeColor = Colors.purple.shade100;
          textColor = Colors.purple.shade900;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            contextLabel,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _dateTimeFormat.format(DateTime.parse(c['created_at'])),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  c['title'] ?? 'No Subject',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(c['message'] ?? ''),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogsTab() {
    final logs = _digitalFile!['audit_logs'] as List?;
    if (logs == null || logs.isEmpty)
      return const Center(child: Text('No activity logs found'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final l = logs[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history, size: 20),
          title: Text(l['action'] ?? 'Activity'),
          subtitle: Text(
            '${l['details'] ?? ''}\n${_dateFormat.format(DateTime.parse(l['created_at']))}',
          ),
          isThreeLine: true,
        );
      },
    );
  }
}
