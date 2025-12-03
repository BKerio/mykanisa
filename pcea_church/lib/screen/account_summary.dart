import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Theme Constants ---
class AppColors {
  static const Color primary = Color(0xFF0A1F44);
  static const Color primaryLight = Color(0xFF4DB6AC);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color accent = Color(0xFFFFA000);
  static const Color textDark = Color(0xFF263238);
  static const Color textLight = Color(0xFF78909C);
}

class LedgerPage extends StatefulWidget {
  const LedgerPage({super.key});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  bool _loading = true;
  bool _isExporting = false;
  String _fullName = '';
  String _ekanisa = '';
  String _congregation = '';
  List<_Payment> _payments = [];
  List<Map<String, dynamic>> _pledges = [];
  String? _profileImageUrl;

  static const List<String> codes = ['T', 'O', 'D', 'TG', 'FF', 'OT'];
  static const Map<String, String> labels = {
    'T': 'Tithe',
    'O': 'Offering',
    'D': 'Development',
    'TG': 'Thanksgiving',
    'FF': 'First Fruit',
    'OT': 'Others',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // Load saved profile image URL from preferences first
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedImageUrl = prefs.getString('profile_image_url');
        if (savedImageUrl != null && savedImageUrl.isNotEmpty) {
          _profileImageUrl = savedImageUrl;
        }
      } catch (_) {}

      final memberRes = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/members/me'),
      );
      final summaryRes = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/contributions/summary'),
      );

      if (mounted) {
        if (memberRes.statusCode == 200) {
          final memberBody = jsonDecode(memberRes.body) as Map<String, dynamic>;
          final member = memberBody['member'] as Map<String, dynamic>?;
          _fullName = (member?['full_name'] ?? '').toString();
          _ekanisa = (member?['e_kanisa_number'] ?? '').toString();
          _congregation = (member?['congregation'] ?? '').toString();
          final apiImageUrl = member?['profile_image_url'];
          if (apiImageUrl != null && apiImageUrl.toString().isNotEmpty) {
            _profileImageUrl = apiImageUrl.toString();
          }
        }

        if (summaryRes.statusCode == 200) {
          final summaryBody =
              jsonDecode(summaryRes.body) as Map<String, dynamic>;
          if ((summaryBody['status'] ?? 200) == 200) {
            final summary = summaryBody['summary'] as List<dynamic>?;
            if (summary != null) {
              _payments = summary
                  .map((item) => _Payment.fromContributionJson(item))
                  .toList();
            }
          }
        }
      }

      // Load pledges separately - don't fail if this errors
      try {
        final pledgesRes = await API().getRequest(
          url: Uri.parse('${Config.baseUrl}/member/pledges'),
        );
        if (mounted && pledgesRes.statusCode == 200) {
          final pledgesBody =
              jsonDecode(pledgesRes.body) as Map<String, dynamic>;
          if ((pledgesBody['status'] ?? 200) == 200) {
            final pledges = pledgesBody['pledges'] as List<dynamic>?;
            if (pledges != null) {
              setState(() {
                _pledges = pledges
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList();
              });
            }
          }
        }
      } catch (pledgeError) {
        // Log but don't fail the entire load if pledges fail
        debugPrint('Error loading pledges: $pledgeError');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Connection error. Please pull to refresh.');
        debugPrint('Error loading data: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Map<_MonthKey, Map<String, double>> _compute() {
    final Map<_MonthKey, Map<String, double>> out = {};
    for (final p in _payments) {
      final monthKey = _MonthKey(p.createdAt.year, p.createdAt.month);
      final code = _mapContributionTypeToCode(p.contributionType);
      if (code == null) continue;
      out.putIfAbsent(monthKey, () => {for (final c in codes) c: 0.0});
      out[monthKey]![code] = (out[monthKey]![code] ?? 0) + p.amount;
    }
    return SplayTreeMap<_MonthKey, Map<String, double>>(
      (a, b) => b.compareTo(a),
    )..addAll(out);
  }

  String? _mapContributionTypeToCode(String contributionType) {
    switch (contributionType.toLowerCase()) {
      case 'tithe':
        return 'T';
      case 'offering':
        return 'O';
      case 'development':
        return 'D';
      case 'thanksgiving':
        return 'TG';
      case 'firstfruit':
        return 'FF';
      case 'others':
        return 'OT';
      default:
        return null;
    }
  }

  String _formatMoney(double v) => v.toStringAsFixed(2);

  double _toDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? defaultValue;
  }

  double _calculateGrandTotal(Map<_MonthKey, Map<String, double>> data) {
    double total = 0;
    data.values.forEach((row) {
      row.values.forEach((val) => total += val);
    });
    return total;
  }

  // --- PDF Logic (Kept functional but cleaned up) ---
  Future<void> _exportToPdf() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final totalsByMonth = _compute();
      final monthKeys = totalsByMonth.keys.toList();

      // Revert sort for PDF (Oldest first usually better for printing, or keep desc)
      monthKeys.sort((a, b) => a.compareTo(b));

      final font = await PdfGoogleFonts.openSansRegular();
      final boldFont = await PdfGoogleFonts.openSansBold();
      final theme = pw.ThemeData.withFont(base: font, bold: boldFont);

      Uint8List? logoBytes;
      try {
        logoBytes = (await rootBundle.load(
          'assets/icon.png',
        )).buffer.asUint8List();
      } catch (_) {}
      final image = logoBytes != null ? pw.MemoryImage(logoBytes) : null;

      final pdf = pw.Document(theme: theme);

      final grandTotals = {for (final c in codes) c: 0.0};
      for (final key in monthKeys) {
        final row = totalsByMonth[key]!;
        for (final code in codes) {
          grandTotals[code] = grandTotals[code]! + (row[code] ?? 0);
        }
      }
      final totalOfTotals = grandTotals.values.fold<double>(0, (a, b) => a + b);

      // Calculate pledge totals
      double totalPledged = 0;
      double totalFulfilled = 0;
      double totalRemaining = 0;
      final List<List<String>> pledgeRows = [];

      if (_pledges.isNotEmpty) {
        for (var pledge in _pledges) {
          final pledgeAmount = _toDouble(pledge['pledge_amount']);
          final fulfilledAmount = _toDouble(pledge['fulfilled_amount']);
          final remainingAmount = _toDouble(pledge['remaining_amount']);
          final status = (pledge['status'] ?? 'active')
              .toString()
              .toUpperCase();
          final accountType = (pledge['account_type'] ?? '').toString();

          totalPledged += pledgeAmount;
          totalFulfilled += fulfilledAmount;
          totalRemaining += remainingAmount;

          pledgeRows.add([
            accountType,
            _formatMoney(pledgeAmount),
            _formatMoney(fulfilledAmount),
            _formatMoney(remainingAmount),
            status,
          ]);
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          header: (context) => pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'My Contribution Report',
                  style: pw.Theme.of(context).header3,
                ),
                pw.Text(DateTime.now().toString().substring(0, 16)),
              ],
            ),
          ),
          build: (context) {
            final List<pw.Widget> widgets = [];

            // Member information
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Member: $_fullName',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text('Kanisa Number: $_ekanisa'),
                  pw.Text('Congregation: $_congregation'),
                  pw.SizedBox(height: 20),
                ],
              ),
            );

            // Pledges Section (if any)
            if (_pledges.isNotEmpty) {
              widgets.add(
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MY PLEDGES',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Table.fromTextArray(
                      headers: [
                        'Account Type',
                        'Pledged',
                        'Fulfilled',
                        'Remaining',
                        'Status',
                      ],
                      data: [
                        ...pledgeRows,
                        [
                          'TOTAL',
                          _formatMoney(totalPledged),
                          _formatMoney(totalFulfilled),
                          _formatMoney(totalRemaining),
                          '',
                        ],
                      ],
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.blue,
                      ),
                      cellAlignment: pw.Alignment.centerRight,
                      cellAlignments: {
                        0: pw.Alignment.centerLeft,
                        4: pw.Alignment.centerLeft,
                      },
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                    ),
                    pw.SizedBox(height: 30),
                  ],
                ),
              );
            }

            // Contributions Section (if any)
            if (_payments.isNotEmpty && monthKeys.isNotEmpty) {
              widgets.add(
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MY CONTRIBUTIONS',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Table.fromTextArray(
                      headers: [
                        'Month',
                        ...codes.map((c) => labels[c]!),
                        'Total',
                      ],
                      data: [
                        ...monthKeys.map((key) {
                          final row = totalsByMonth[key]!;
                          final total = row.values.fold<double>(
                            0,
                            (a, b) => a + b,
                          );
                          return [
                            key.label(),
                            ...codes.map((c) => _formatMoney(row[c] ?? 0)),
                            _formatMoney(total),
                          ];
                        }),
                        [
                          'GRAND TOTAL',
                          ...codes.map((c) => _formatMoney(grandTotals[c]!)),
                          _formatMoney(totalOfTotals),
                        ],
                      ],
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.teal,
                      ),
                      cellAlignment: pw.Alignment.centerRight,
                      cellAlignments: {0: pw.Alignment.centerLeft},
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                    ),
                  ],
                ),
              );
            }

            return [
              pw.Stack(
                children: [
                  if (image != null)
                    pw.Positioned(
                      top: 0,
                      right: 0,
                      child: pw.Opacity(
                        opacity: 0.1,
                        child: pw.Image(image, width: 100),
                      ),
                    ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: widgets,
                  ),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: '$_fullName.${_ekanisa}.pdf',
      );
    } catch (e) {
      _showErrorSnackbar('Failed to generate PDF');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // --- UI Widgets ---

  @override
  Widget build(BuildContext context) {
    final totalsByMonth = _compute();
    final monthKeys = totalsByMonth.keys.toList();
    final grandTotal = _calculateGrandTotal(totalsByMonth);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton:
          (_payments.isNotEmpty || _pledges.isNotEmpty) && !_loading
          ? FloatingActionButton.extended(
              onPressed: _isExporting ? null : _exportToPdf,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black87,
              elevation: 4,
              icon: _isExporting
                  ? SpinKitFadingCircle(
                      size: 20,
                      duration: const Duration(milliseconds: 3200),
                      itemBuilder: (context, index) {
                        final palette = [
                          Colors.black87,
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
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(_isExporting ? 'Generating...' : 'Export PDF'),
            )
          : null,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white24,
                        child: _buildProfileAvatarContent(),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Kanisa Number: $_ekanisa',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: Text(
                innerBoxIsScrolled ? 'My Contributions' : '',
                style: const TextStyle(color: Colors.white),
              ),
              centerTitle: true,
            ),
          ];
        },
        body: _loading
            ? Center(
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
              )
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                child: _payments.isEmpty && _pledges.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Total Summary Card (moved above pledges)
                            if (_payments.isNotEmpty) ...[
                              _buildSummaryCard(grandTotal),
                              const SizedBox(height: 24),
                            ],

                            // Pledges Section (if any)
                            if (_pledges.isNotEmpty) ...[
                              _buildPledgesSection(),
                              const SizedBox(height: 24),
                            ],

                            // Contributions Section (table and legend)
                            if (_payments.isNotEmpty) ...[
                              // Table Section
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Monthly Breakdown",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Icon(
                                    Icons.swipe_left,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildLedgerTable(totalsByMonth, monthKeys),

                              const SizedBox(height: 24),

                              // Legend Section
                              const Text(
                                "Contribution Codes",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildLegend(),
                            ],
                          ],
                        ),
                      ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            "No contributions or pledges found",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh"),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.money, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              const Text(
                "Total Contribution made",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 8),
          Text(
            "KES ${_formatMoney(total)}",
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily:
                  'Monospace', // Or use a specific monospace font if available
            ),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.house_rounded, size: 16, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                _congregation.isNotEmpty ? _congregation : "Main Congregation",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerTable(
    Map<_MonthKey, Map<String, double>> totalsByMonth,
    List<_MonthKey> monthKeys,
  ) {
    // Calculate footer totals
    final footerTotals = {for (final c in codes) c: 0.0};
    for (final m in monthKeys) {
      for (final c in codes) {
        footerTotals[c] = footerTotals[c]! + (totalsByMonth[m]![c] ?? 0);
      }
    }
    final grandTotal = footerTotals.values.fold<double>(0, (a, b) => a + b);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          columnSpacing: 24,
          horizontalMargin: 20,
          border: TableBorder(
            verticalInside: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
          columns: [
            const DataColumn(
              label: Text(
                'Month',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...codes.map(
              (c) => DataColumn(
                label: Text(
                  c,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                numeric: true,
                tooltip: labels[c],
              ),
            ),
            const DataColumn(
              label: Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
            ),
          ],
          rows: [
            ...monthKeys.asMap().entries.map((entry) {
              final idx = entry.key;
              final key = entry.value;
              final row = totalsByMonth[key]!;
              final rowTotal = row.values.fold<double>(0, (a, b) => a + b);

              return DataRow(
                color: MaterialStateProperty.resolveWith<Color?>((
                  Set<MaterialState> states,
                ) {
                  return idx.isEven ? Colors.white : Colors.grey.shade50;
                }),
                cells: [
                  DataCell(
                    Text(
                      key.label(),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  ...codes.map((c) {
                    final val = row[c] ?? 0;
                    return DataCell(
                      Text(
                        val == 0 ? '-' : _formatMoney(val),
                        style: TextStyle(
                          color: val == 0
                              ? Colors.grey[300]
                              : AppColors.textDark,
                        ),
                      ),
                    );
                  }),
                  DataCell(
                    Text(
                      _formatMoney(rowTotal),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            }),
            // Total Row
            DataRow(
              color: MaterialStateProperty.all(
                AppColors.primary.withOpacity(0.05),
              ),
              cells: [
                const DataCell(
                  Text(
                    'TOTAL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                ...codes.map(
                  (c) => DataCell(
                    Text(
                      _formatMoney(footerTotals[c] ?? 0),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _formatMoney(grandTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: codes.map((c) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "$c ",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
                TextSpan(
                  text: labels[c],
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPledgesSection() {
    // Group pledges by account type to avoid duplicates
    final Map<String, Map<String, dynamic>> groupedPledges = {};

    for (var pledge in _pledges) {
      final accountType = pledge['account_type'] ?? 'Others';

      if (!groupedPledges.containsKey(accountType)) {
        groupedPledges[accountType] = {
          'account_type': accountType,
          'pledge_amount': 0.0,
          'fulfilled_amount': 0.0,
          'remaining_amount': 0.0,
          'status': 'active',
          'count': 0,
        };
      }

      final group = groupedPledges[accountType]!;
      group['pledge_amount'] =
          (group['pledge_amount'] as double) +
          _toDouble(pledge['pledge_amount']);
      group['fulfilled_amount'] =
          (group['fulfilled_amount'] as double) +
          _toDouble(pledge['fulfilled_amount']);
      group['remaining_amount'] =
          (group['remaining_amount'] as double) +
          _toDouble(pledge['remaining_amount']);
      group['count'] = (group['count'] as int) + 1;

      // Determine status: if any is active, show active; if all fulfilled, show fulfilled
      final pledgeStatus = pledge['status'] ?? 'active';
      if (pledgeStatus == 'active' && group['status'] != 'active') {
        group['status'] = 'active';
      } else if (pledgeStatus == 'fulfilled' && group['status'] == 'active') {
        // Keep active if there are any active pledges
      } else if (pledgeStatus == 'cancelled') {
        group['status'] = 'cancelled';
      }
    }

    // Sort by account type order
    final accountTypeOrder = [
      'Tithe',
      'Offering',
      'Development',
      'Thanksgiving',
      'FirstFruit',
      'Others',
    ];
    final sortedPledges = groupedPledges.values.toList()
      ..sort((a, b) {
        final aType = a['account_type'] as String;
        final bType = b['account_type'] as String;
        final aIndex = accountTypeOrder.indexOf(aType);
        final bIndex = accountTypeOrder.indexOf(bType);
        if (aIndex == -1 && bIndex == -1) return aType.compareTo(bType);
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });

    // Calculate totals
    double totalPledged = 0;
    double totalFulfilled = 0;
    double totalRemaining = 0;

    for (var pledge in sortedPledges) {
      totalPledged += _toDouble(pledge['pledge_amount']);
      totalFulfilled += _toDouble(pledge['fulfilled_amount']);
      totalRemaining += _toDouble(pledge['remaining_amount']);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pledges Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.flag, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    "My Pledges towards the church",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "Pledge Summary",
                style: TextStyle(color: AppColors.textLight, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPledgeSummaryItem(
                      "Total Pledged",
                      totalPledged,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildPledgeSummaryItem(
                      "Fulfilled",
                      totalFulfilled,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildPledgeSummaryItem(
                      "Remaining",
                      totalRemaining,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pledges Table
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
              columnSpacing: 24,
              horizontalMargin: 20,
              border: TableBorder(
                verticalInside: BorderSide(
                  color: Colors.grey.shade100,
                  width: 1,
                ),
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    'Account Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Pledged',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'Fulfilled',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'Remaining',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: [
                ...sortedPledges.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final pledge = entry.value;
                  final pledgeAmount = _toDouble(pledge['pledge_amount']);
                  final fulfilledAmount = _toDouble(pledge['fulfilled_amount']);
                  final remainingAmount = _toDouble(pledge['remaining_amount']);
                  final status = pledge['status'] ?? 'active';
                  final accountType = pledge['account_type'] ?? '';
                  final count = pledge['count'] as int;

                  return DataRow(
                    color: MaterialStateProperty.resolveWith<Color?>((
                      Set<MaterialState> states,
                    ) {
                      return idx.isEven ? Colors.white : Colors.grey.shade50;
                    }),
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Text(
                              accountType,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (count > 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatMoney(pledgeAmount),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatMoney(fulfilledAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatMoney(remainingAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getStatusColor(status)),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPledgeSummaryItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          'KES ${_formatMoney(value)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.blue;
      case 'fulfilled':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildProfileAvatarContent() {
    // If we have a profile image URL, try to render it
    if (_profileImageUrl != null && _profileImageUrl!.trim().isNotEmpty) {
      String imageUrl = _profileImageUrl!.trim();
      if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
        final base = Config.baseUrl.replaceAll('/api', '');
        imageUrl = base + (imageUrl.startsWith('/') ? imageUrl : '/$imageUrl');
      }
      return ClipOval(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: 200,
          height: 200,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'M',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            );
          },
        ),
      );
    }

    // Fallback to first letter avatar
    return Text(
      _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'M',
      style: const TextStyle(
        fontSize: 24,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// --- Models & Helpers (Unchanged logic, just helper class) ---

class _Payment {
  final String accountReference;
  final double amount;
  final DateTime createdAt;
  final String contributionType;

  _Payment({
    required this.accountReference,
    required this.amount,
    required this.createdAt,
    required this.contributionType,
  });

  factory _Payment.fromContributionJson(Map<String, dynamic> j) {
    // FIX: Parse the date from the API response instead of using DateTime.now()
    final dateString =
        (j['created_at'] ?? j['transaction_date'] ?? j['date'] ?? '')
            .toString();
    DateTime date;

    if (dateString.isNotEmpty) {
      // Safely parse the date string. If parsing fails, fall back to today.
      date = DateTime.tryParse(dateString) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    return _Payment(
      accountReference: (j['contribution_type'] ?? '').toString(),
      amount: (j['total_amount'] is num)
          ? (j['total_amount'] as num).toDouble()
          : double.tryParse(j['total_amount'].toString()) ?? 0.0,
      createdAt: date, // <--- FIXED to use the parsed date
      contributionType: (j['contribution_type'] ?? '').toString(),
    );
  }
}

class _MonthKey implements Comparable<_MonthKey> {
  final int year;
  final int month;
  _MonthKey(this.year, this.month);

  String label() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return (month >= 1 && month <= 12)
        ? '${months[month - 1]} $year'
        : '$month $year';
  }

  @override
  int compareTo(_MonthKey other) {
    if (year != other.year) return year.compareTo(other.year);
    return month.compareTo(other.month);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MonthKey &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => year.hashCode ^ month.hashCode;
}
