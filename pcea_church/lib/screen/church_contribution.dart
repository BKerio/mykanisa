import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';

class ElderContributionsScreen extends StatefulWidget {
  const ElderContributionsScreen({super.key});

  @override
  State<ElderContributionsScreen> createState() =>
      _ElderContributionsScreenState();
}

class _ElderContributionsScreenState extends State<ElderContributionsScreen> {
  List<Map<String, dynamic>> _payments = [];
  List<String> _congregations = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _selectedCongregation;
  String? _selectedStatus;
  String? _dateFrom;
  String? _dateTo;
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  final int _perPage = 20;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCongregations();
    _loadContributions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCongregations() async {
    setState(() {});

    try {
      final result = await API().getRequest(
        url: Uri.parse(
          '${Config.baseUrl}/elder/contributions-meta/congregations',
        ),
      );

      if (result.statusCode == 200) {
        final response = jsonDecode(result.body);
        setState(() {
          _congregations = List<String>.from(response);
        });
      } else {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading congregations: $e');
      setState(() {});
    }
  }

  Future<void> _loadContributions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final params = <String, String>{
        'page': _currentPage.toString(),
        'per_page': _perPage.toString(),
      };

      if (_searchQuery.isNotEmpty) {
        params['q'] = _searchQuery;
      }
      if (_selectedCongregation != null && _selectedCongregation!.isNotEmpty) {
        params['congregation'] = _selectedCongregation!;
      }
      if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
        params['status'] = _selectedStatus!;
      }
      if (_dateFrom != null && _dateFrom!.isNotEmpty) {
        params['date_from'] = _dateFrom!;
      }
      if (_dateTo != null && _dateTo!.isNotEmpty) {
        params['date_to'] = _dateTo!;
      }

      final uri = Uri.parse(
        '${Config.baseUrl}/elder/contributions',
      ).replace(queryParameters: params);

      final result = await API().getRequest(url: uri);

      if (result.statusCode == 200) {
        final response = jsonDecode(result.body);
        setState(() {
          _payments = List<Map<String, dynamic>>.from(response['data'] ?? []);
          _currentPage = response['current_page'] ?? 1;
          _totalPages = response['last_page'] ?? 1;
          _total = response['total'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load contributions';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading contributions: $e');
      setState(() {
        _error = 'Error loading contributions: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getContributionType(String? accountReference) {
    if (accountReference == null) return 'General';
    if (accountReference.endsWith('T')) return 'Tithe';
    if (accountReference.endsWith('O')) return 'Offering';
    if (accountReference.endsWith('D')) return 'Development';
    if (accountReference.endsWith('TG')) return 'Thanksgiving';
    if (accountReference.endsWith('FF')) return 'First Fruit';
    return 'General';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is num) return amount.toDouble();
    if (amount is String) {
      return double.tryParse(amount) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(
              start: DateTime.parse(_dateFrom!),
              end: DateTime.parse(_dateTo!),
            )
          : null,
    );

    if (picked != null) {
      setState(() {
        _dateFrom = picked.start.toIso8601String().split('T')[0];
        _dateTo = picked.end.toIso8601String().split('T')[0];
      });
      _currentPage = 1;
      _loadContributions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0A1F44),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "Church Contributions.",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _currentPage = 1;
              _loadContributions();
            },
            tooltip: 'Refresh',
          ),
        ],
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, receipt, or Kanisa number...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              _currentPage = 1;
                              _loadContributions();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  onSubmitted: (_) {
                    _currentPage = 1;
                    _loadContributions();
                  },
                ),
                const SizedBox(height: 12),
                // Filter Row
                Row(
                  children: [
                    // Congregation Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCongregation,
                        decoration: InputDecoration(
                          labelText: 'Congregation',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Congregations'),
                          ),
                          ..._congregations.map(
                            (cong) => DropdownMenuItem<String>(
                              value: cong,
                              child: Text(cong),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCongregation = value;
                          });
                          _currentPage = 1;
                          _loadContributions();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Status Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Status'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'confirmed',
                            child: Text('Confirmed'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'failed',
                            child: Text('Failed'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                          _currentPage = 1;
                          _loadContributions();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Date Range Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _dateFrom != null && _dateTo != null
                          ? '${_formatDate(_dateFrom)} - ${_formatDate(_dateTo)}'
                          : 'Select Date Range',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
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
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.grey.shade700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadContributions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _payments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No contributions found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Summary Card
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '$_total',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'Total Payments',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            Column(
                              children: [
                                Text(
                                  'KES ${_payments.fold<double>(0, (sum, p) => sum + _parseAmount(p['amount'])).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Payments List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _payments.length,
                          itemBuilder: (context, index) {
                            final payment = _payments[index];
                            final member =
                                payment['member'] as Map<String, dynamic>?;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member?['full_name'] ?? 'Unknown Member',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (member?['e_kanisa_number'] != null)
                                      Text(
                                        'Kanisa No: ${member!['e_kanisa_number']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(
                                            payment['created_at']?.toString(),
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.category,
                                          size: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getContributionType(
                                            payment['account_reference']
                                                ?.toString(),
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (payment['mpesa_receipt_number'] !=
                                        null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.receipt,
                                            size: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            payment['mpesa_receipt_number'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'KES ${_parseAmount(payment['amount']).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          payment['status']?.toString() ?? '',
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        payment['status']
                                                ?.toString()
                                                .toUpperCase() ??
                                            '',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(
                                            payment['status']?.toString() ?? '',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  _showPaymentDetails(payment);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      // Pagination
                      if (_totalPages > 1)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Page $_currentPage of $_totalPages',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: _currentPage > 1
                                        ? () {
                                            setState(() {
                                              _currentPage--;
                                            });
                                            _loadContributions();
                                          }
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: _currentPage < _totalPages
                                        ? () {
                                            setState(() {
                                              _currentPage++;
                                            });
                                            _loadContributions();
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    final member = payment['member'] as Map<String, dynamic>?;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    'Amount',
                    'KES ${_parseAmount(payment['amount']).toStringAsFixed(2)}',
                  ),
                  _buildDetailRow(
                    'Status',
                    payment['status']?.toString().toUpperCase() ?? '',
                  ),
                  _buildDetailRow(
                    'Date',
                    _formatDate(payment['created_at']?.toString()),
                  ),
                  if (payment['mpesa_receipt_number'] != null)
                    _buildDetailRow(
                      'M-Pesa Receipt',
                      payment['mpesa_receipt_number'],
                    ),
                  if (payment['account_reference'] != null)
                    _buildDetailRow('Reference', payment['account_reference']),
                  if (member != null) ...[
                    const Divider(height: 32),
                    const Text(
                      'Member Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Name', member['full_name'] ?? ''),
                    if (member['e_kanisa_number'] != null)
                      _buildDetailRow(
                        'E-Kanisa Number',
                        member['e_kanisa_number'],
                      ),
                    if (member['congregation'] != null)
                      _buildDetailRow('Congregation', member['congregation']),
                    if (member['telephone'] != null)
                      _buildDetailRow('Phone', member['telephone']),
                    if (member['email'] != null)
                      _buildDetailRow('Email', member['email']),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
