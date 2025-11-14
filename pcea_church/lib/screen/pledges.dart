import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:intl/intl.dart';

class PledgesPage extends StatefulWidget {
  const PledgesPage({super.key});

  @override
  State<PledgesPage> createState() => _PledgesPageState();
}

class _PledgesPageState extends State<PledgesPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _pledges = [];
  Map<String, dynamic>? _summary;
  String _filterStatus = 'all'; // all, active, fulfilled, cancelled
  bool _showCreateForm = false;
  bool _submitting = false;

  static const List<String> _accountTypes = [
    'Tithe',
    'Offering',
    'Development',
    'Thanksgiving',
    'FirstFruit',
    'Others',
  ];

  final Map<String, TextEditingController> _pledgeAmountCtrls = {
    'Tithe': TextEditingController(text: ''),
    'Offering': TextEditingController(text: ''),
    'Development': TextEditingController(text: ''),
    'Thanksgiving': TextEditingController(text: ''),
    'FirstFruit': TextEditingController(text: ''),
    'Others': TextEditingController(text: ''),
  };

  final Map<String, TextEditingController> _descriptionCtrls = {
    'Tithe': TextEditingController(text: ''),
    'Offering': TextEditingController(text: ''),
    'Development': TextEditingController(text: ''),
    'Thanksgiving': TextEditingController(text: ''),
    'FirstFruit': TextEditingController(text: ''),
    'Others': TextEditingController(text: ''),
  };

  final Map<String, DateTime?> _targetDates = {
    'Tithe': null,
    'Offering': null,
    'Development': null,
    'Thanksgiving': null,
    'FirstFruit': null,
    'Others': null,
  };

  @override
  void initState() {
    super.initState();
    _loadPledges();
  }

  @override
  void dispose() {
    for (var ctrl in _pledgeAmountCtrls.values) {
      ctrl.dispose();
    }
    for (var ctrl in _descriptionCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPledges() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final url = _filterStatus == 'all'
          ? Uri.parse('${Config.baseUrl}/member/pledges')
          : Uri.parse('${Config.baseUrl}/member/pledges?status=$_filterStatus');

      final res = await API().getRequest(url: url);

      if (mounted && res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['status'] == 200) {
          setState(() {
            _pledges = List<Map<String, dynamic>>.from(body['pledges'] ?? []);
            _summary = body['summary'] != null
                ? Map<String, dynamic>.from(body['summary'])
                : null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading pledges: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createPledge() async {
    setState(() {
      _showCreateForm = true;
    });
  }

  void _cancelCreatePledge() {
    setState(() {
      _showCreateForm = false;
      // Clear all form fields
      for (var ctrl in _pledgeAmountCtrls.values) {
        ctrl.clear();
      }
      for (var ctrl in _descriptionCtrls.values) {
        ctrl.clear();
      }
      for (var key in _targetDates.keys) {
        _targetDates[key] = null;
      }
    });
  }

  double _getTotalPledgeAmount() {
    double sum = 0;
    for (final ctrl in _pledgeAmountCtrls.values) {
      final n = double.tryParse(ctrl.text.trim()) ?? 0;
      sum += n;
    }
    return sum;
  }

  Future<void> _submitPledges() async {
    if (_submitting) return;

    // Validate that at least one pledge amount is entered
    if (_getTotalPledgeAmount() <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one pledge amount.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      // Build list of pledges to create
      final List<Map<String, dynamic>> pledgesToCreate = [];

      for (final accountType in _accountTypes) {
        final amount =
            double.tryParse(_pledgeAmountCtrls[accountType]!.text.trim()) ?? 0;
        if (amount > 0) {
          final pledgeData = <String, dynamic>{
            'account_type': accountType,
            'pledge_amount': amount,
          };

          final description = _descriptionCtrls[accountType]!.text.trim();
          if (description.isNotEmpty) {
            pledgeData['description'] = description;
          }

          final targetDate = _targetDates[accountType];
          if (targetDate != null) {
            pledgeData['target_date'] = DateFormat(
              'yyyy-MM-dd',
            ).format(targetDate);
          }

          pledgesToCreate.add(pledgeData);
        }
      }

      // Create pledges one by one (or update backend to accept bulk)
      int successCount = 0;
      int failCount = 0;

      for (final pledgeData in pledgesToCreate) {
        try {
          final res = await API().postRequest(
            url: Uri.parse('${Config.baseUrl}/member/pledges'),
            data: pledgeData,
          );

          if (res.statusCode == 201) {
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          failCount++;
          debugPrint(
            'Error creating pledge for ${pledgeData['account_type']}: $e',
          );
        }
      }

      if (mounted) {
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                failCount > 0
                    ? '$successCount pledge(s) created. $failCount failed.'
                    : '$successCount pledge(s) created successfully!',
              ),
              backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
            ),
          );
          _cancelCreatePledge();
          _loadPledges();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create pledges. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _editPledge(Map<String, dynamic> pledge) async {
    await _showPledgeDialog(pledge: pledge);
  }

  Future<void> _showPledgeDialog({Map<String, dynamic>? pledge}) async {
    final isEditing = pledge != null;
    final formKey = GlobalKey<FormState>();
    final accountTypeCtrl = TextEditingController(
      text: isEditing ? pledge['account_type'] : '',
    );
    final amountCtrl = TextEditingController(
      text: pledge != null
          ? _toDouble(pledge['pledge_amount']).toStringAsFixed(2)
          : '',
    );
    final descriptionCtrl = TextEditingController(
      text: pledge?['description'] ?? '',
    );
    DateTime? targetDate = pledge?['target_date'] != null
        ? DateFormat('yyyy-MM-dd').parse(pledge?['target_date'])
        : null;

    final accountTypes = [
      'Tithe',
      'Offering',
      'Development',
      'Thanksgiving',
      'FirstFruit',
      'Others',
    ];

    // For dropdown state - use a list to maintain state across rebuilds
    final dropdownState = [
      isEditing ? pledge['account_type'] as String? : null,
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.flag, color: Color(0xFF0A1F44)),
              const SizedBox(width: 8),
              Text(isEditing ? 'Edit Pledge' : 'Create Pledge'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isEditing)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Account Type',
                        prefixIcon: Icon(Icons.account_balance),
                        border: OutlineInputBorder(),
                      ),
                      value: dropdownState[0],
                      items: accountTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          dropdownState[0] = value;
                          accountTypeCtrl.text = value ?? '';
                        });
                      },
                      validator: (v) => dropdownState[0] == null
                          ? 'Select account type'
                          : null,
                    ),
                  if (!isEditing) const SizedBox(height: 16),
                  if (isEditing)
                    TextFormField(
                      controller: TextEditingController(
                        text: accountTypeCtrl.text,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Account Type',
                        prefixIcon: Icon(Icons.account_balance),
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),
                  if (isEditing) const SizedBox(height: 16),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Pledge Amount (KES)',
                      prefixIcon: Icon(Icons.money),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final amount = double.tryParse(v ?? '') ?? 0;
                      if (amount <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      targetDate == null
                          ? 'Target Date (Optional)'
                          : 'Target: ${DateFormat('yyyy-MM-dd').format(targetDate!)}',
                    ),
                    trailing: targetDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setDialogState(() => targetDate = null);
                            },
                          )
                        : null,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            targetDate ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 2),
                        ),
                      );
                      if (date != null) {
                        setDialogState(() => targetDate = date);
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate() &&
                    (isEditing || accountTypeCtrl.text.isNotEmpty)) {
                  try {
                    if (isEditing) {
                      // Update existing pledge
                      final updateData = <String, dynamic>{
                        'pledge_amount': double.parse(amountCtrl.text),
                        'description': descriptionCtrl.text.isEmpty
                            ? null
                            : descriptionCtrl.text,
                        'target_date': targetDate != null
                            ? DateFormat('yyyy-MM-dd').format(targetDate!)
                            : null,
                      };

                      final res = await API().putRequest(
                        url: Uri.parse(
                          '${Config.baseUrl}/member/pledges/${pledge['id']}',
                        ),
                        data: updateData,
                      );

                      if (res.statusCode == 200) {
                        Navigator.pop(context);
                        _loadPledges();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pledge updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        final body = jsonDecode(res.body);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                body['message'] ?? 'Error updating pledge',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } else {
                      // Create new pledge
                      final res = await API().postRequest(
                        url: Uri.parse('${Config.baseUrl}/member/pledges'),
                        data: {
                          'account_type': accountTypeCtrl.text,
                          'pledge_amount': double.parse(amountCtrl.text),
                          if (descriptionCtrl.text.isNotEmpty)
                            'description': descriptionCtrl.text,
                          if (targetDate != null)
                            'target_date': DateFormat(
                              'yyyy-MM-dd',
                            ).format(targetDate!),
                        },
                      );

                      if (res.statusCode == 201) {
                        Navigator.pop(context);
                        _loadPledges();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pledge created successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        final body = jsonDecode(res.body);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                body['message'] ?? 'Error creating pledge',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1F44),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Update Pledge' : 'Create Pledge'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Tithe':
        return Icons.volunteer_activism_outlined;
      case 'Offering':
        return Icons.card_giftcard_outlined;
      case 'Development':
        return Icons.construction_outlined;
      case 'Thanksgiving':
        return Icons.celebration_outlined;
      case 'FirstFruit':
        return Icons.local_florist_outlined;
      case 'Others':
      default:
        return Icons.savings_outlined;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
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

  double _toDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    if (_showCreateForm) {
      return _buildCreateForm();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('My Pledges'),
        backgroundColor: const Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPledges,
              child: Column(
                children: [
                  // Summary Card
                  if (_summary != null) _buildSummaryCard(),

                  // Filter Chips
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'All'),
                          _buildFilterChip('active', 'Active'),
                          _buildFilterChip('fulfilled', 'Fulfilled'),
                          _buildFilterChip('cancelled', 'Cancelled'),
                        ],
                      ),
                    ),
                  ),

                  // Pledges List
                  Expanded(
                    child: _pledges.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _pledges.length,
                            itemBuilder: (context, index) {
                              return _buildPledgeCard(_pledges[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPledge,
        backgroundColor: const Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Pledge'),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Create Pledges'),
        backgroundColor: const Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _cancelCreatePledge,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 100,
        ),
        child: Column(
          children: [
            // Header
            Column(
              children: [
                const Icon(Icons.flag, size: 120, color: Color(0xFF0A1F44)),
                const SizedBox(height: 10),
                Text(
                  "Create Your Pledges",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Pledge to multiple accounts at once",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 25),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select accounts to pledge to:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            // ExpansionTiles for each account type
            ..._accountTypes.map((type) {
              final amountCtrl = _pledgeAmountCtrls[type]!;
              final descCtrl = _descriptionCtrls[type]!;
              final targetDate = _targetDates[type];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: Icon(
                    _iconForType(type),
                    color: const Color(0xFF0A1F44),
                  ),
                  title: Text(
                    type,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: amountCtrl.text.isNotEmpty
                      ? Text(
                          'KES ${(double.tryParse(amountCtrl.text.trim()) ?? 0).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Pledge Amount (KES)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final amount = double.tryParse(v ?? '') ?? 0;
                              if (amount < 0) {
                                return 'Amount cannot be negative';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descCtrl,
                            decoration: InputDecoration(
                              labelText: 'Description (Optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.calendar_today),
                            title: Text(
                              targetDate == null
                                  ? 'Target Date (Optional)'
                                  : 'Target: ${DateFormat('yyyy-MM-dd').format(targetDate)}',
                            ),
                            trailing: targetDate != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _targetDates[type] = null;
                                      });
                                    },
                                  )
                                : null,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate:
                                    targetDate ??
                                    DateTime.now().add(
                                      const Duration(days: 30),
                                    ),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365 * 2),
                                ),
                              );
                              if (date != null) {
                                setState(() {
                                  _targetDates[type] = date;
                                });
                              }
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 16),

            // Total summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.summarize, color: Color(0xFF0A1F44)),
                  const SizedBox(width: 10),
                  const Text(
                    'Total Pledge Amount:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    'KES ${_getTotalPledgeAmount().toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1F44),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submitPledges,
                icon: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.flag),
                label: Text(
                  _submitting
                      ? 'Creating...'
                      : 'Create Pledges - KES ${_getTotalPledgeAmount().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1F44),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalPledged = _toDouble(_summary?['total_pledged']);
    final totalFulfilled = _toDouble(_summary?['total_fulfilled']);
    final totalRemaining = _toDouble(_summary?['total_remaining']);
    final percentage = _toDouble(_summary?['fulfillment_percentage']);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const Text(
            'Pledge Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1F44),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Pledged',
                  totalPledged,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Fulfilled',
                  totalFulfilled,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Remaining',
                  totalRemaining,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}% Fulfilled',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          'KES ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterStatus = status);
          _loadPledges();
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF0A1F44),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPledgeCard(Map<String, dynamic> pledge) {
    final accountType = pledge['account_type'] ?? '';
    final pledgeAmount = _toDouble(pledge['pledge_amount']);
    final fulfilledAmount = _toDouble(pledge['fulfilled_amount']);
    final remainingAmount = _toDouble(pledge['remaining_amount']);
    final status = pledge['status'] ?? 'active';
    final percentage = pledgeAmount > 0
        ? (fulfilledAmount / pledgeAmount * 100)
        : 0.0;
    final targetDate = pledge['target_date'] != null
        ? DateFormat('yyyy-MM-dd').parse(pledge['target_date'])
        : null;
    final description = pledge['description'] ?? '';
    final isActive = status == 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconForType(accountType), color: const Color(0xFF0A1F44)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    accountType,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isActive)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: const Color(0xFF0A1F44),
                    onPressed: () => _editPledge(pledge),
                    tooltip: 'Edit Pledge',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _statusColor(status)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (description.isNotEmpty) ...[
              Text(description, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pledged: KES ${pledgeAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Fulfilled: KES ${fulfilledAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Remaining: KES ${remainingAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (targetDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Target Date',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(targetDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                status == 'fulfilled' ? Colors.green : Colors.blue,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(1)}% Complete',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No pledges found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new pledge to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
