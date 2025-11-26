import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:intl/intl.dart';

// --- Theme Constants (Ensuring consistency with the assumed app theme) ---
class AppColors {
  static const Color primary = Color(0xFF0A1F44); // Dark Blue
  static const Color primaryLight = Color(0xFF4DB6AC);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color accent = Color(0xFFFFA000); // Orange/Accent
  static const Color textDark = Color(0xFF263238);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
}

class PledgesPage extends StatefulWidget {
  const PledgesPage({super.key});

  @override
  State<PledgesPage> createState() => _PledgesPageState();
}

class _PledgesPageState extends State<PledgesPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _pledges = [];
  Map<String, dynamic>? _summary;
  String _filterStatus = 'active'; // Changed default filter to 'active'
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
    for (var type in _accountTypes) type: TextEditingController(),
  };

  final Map<String, TextEditingController> _descriptionCtrls = {
    for (var type in _accountTypes) type: TextEditingController(),
  };

  final Map<String, DateTime?> _targetDates = {
    for (var type in _accountTypes) type: null,
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
        _showSnackbar(
          'Error loading pledges. Pull down to refresh.',
          Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _createPledge() {
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

    final totalAmount = _getTotalPledgeAmount();
    if (totalAmount <= 0) {
      _showSnackbar('Please enter at least one pledge amount.', Colors.red);
      return;
    }

    setState(() => _submitting = true);

    try {
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

      int successCount = 0;
      int failCount = 0;

      // Note: Submitting pledges one-by-one as the backend likely doesn't support bulk creation endpoint used here.
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
            // Optionally log failure details if available in res.body
          }
        } catch (e) {
          failCount++;
        }
      }

      if (mounted) {
        if (successCount > 0) {
          final message = failCount > 0
              ? '$successCount pledge(s) created. $failCount failed.'
              : '$successCount pledge(s) created successfully!';
          _showSnackbar(
            message,
            failCount > 0 ? AppColors.warning : AppColors.success,
          );
          _cancelCreatePledge();
          _loadPledges();
        } else {
          _showSnackbar(
            'Failed to create pledges. Please try again.',
            Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Submission Error: $e', Colors.red);
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

    // In edit mode, we use the original account type
    String? currentAccountType = isEditing
        ? pledge['account_type'] as String?
        : null;

    final amountCtrl = TextEditingController(
      text: pledge != null
          ? _toDouble(pledge['pledge_amount']).toStringAsFixed(2)
          : '',
    );
    final descriptionCtrl = TextEditingController(
      text: pledge?['description'] ?? '',
    );
    DateTime? targetDate = pledge?['target_date'] != null
        ? DateTime.tryParse(pledge!['target_date'])
        : null;

    final accountTypes = [
      'Tithe',
      'Offering',
      'Development',
      'Thanksgiving',
      'FirstFruit',
      'Others',
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.flag, color: AppColors.primary),
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
                  // Account Type Selection (Only for creation)
                  if (!isEditing)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Account Type',
                        prefixIcon: Icon(Icons.account_balance),
                        border: OutlineInputBorder(),
                      ),
                      value: currentAccountType,
                      items: accountTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          currentAccountType = value;
                        });
                      },
                      validator: (v) =>
                          v == null ? 'Select account type' : null,
                    ),
                  if (isEditing)
                    _buildDisabledFormField(
                      label: 'Account Type',
                      value: currentAccountType!,
                      icon: Icons.account_balance,
                    ),
                  const SizedBox(height: 16),
                  // Pledge Amount
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
                  // Description
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
                  // Target Date Picker
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
                        initialDate: targetDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365 * 5),
                        ),
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
                    currentAccountType != null) {
                  try {
                    Map<String, dynamic> data = {
                      'pledge_amount': double.parse(amountCtrl.text),
                      'description': descriptionCtrl.text.isEmpty
                          ? null
                          : descriptionCtrl.text,
                      'target_date': targetDate != null
                          ? DateFormat('yyyy-MM-dd').format(targetDate!)
                          : null,
                    };

                    if (!isEditing) {
                      data['account_type'] = currentAccountType;
                    }

                    final res = await (isEditing
                        ? API().putRequest(
                            url: Uri.parse(
                              '${Config.baseUrl}/member/pledges/${pledge['id']}',
                            ),
                            data: data,
                          )
                        : API().postRequest(
                            url: Uri.parse('${Config.baseUrl}/member/pledges'),
                            data: data,
                          ));

                    if (res.statusCode == 200 || res.statusCode == 201) {
                      Navigator.pop(context);
                      _loadPledges();
                      _showSnackbar(
                        'Pledge ${isEditing ? 'updated' : 'created'} successfully!',
                        AppColors.success,
                      );
                    } else {
                      final body = jsonDecode(res.body);
                      _showSnackbar(
                        body['message'] ?? 'Error processing pledge',
                        Colors.red,
                      );
                    }
                  } catch (e) {
                    _showSnackbar('An unexpected error occurred.', Colors.red);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Update Pledge' : 'Create Pledge'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledFormField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        fillColor: Colors.grey.shade100,
        filled: true,
      ),
      enabled: false,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  void _showSnackbar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
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
        return AppColors.info;
      case 'fulfilled':
        return AppColors.success;
      case 'cancelled':
        return Colors.grey.shade500;
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Pledges'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadPledges,
              color: AppColors.primary,
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
                    color: AppColors.surface,
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
                  const Divider(height: 1, color: Colors.grey),

                  // Pledges List - Grouped by Account Type
                  Expanded(
                    child: _pledges.isEmpty
                        ? _buildEmptyState()
                        : _buildGroupedPledgesList(),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPledge,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black87,
        icon: const Icon(Icons.add),
        label: const Text('New Pledge'),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Pledges'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _cancelCreatePledge,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions/Header
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Multi-Pledge Entry",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter pledge amounts for any of the categories below. Only categories with an amount greater than zero will be submitted.",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Pledge Tiles
            ..._accountTypes.map((type) => _buildPledgeFormTile(type)),

            const SizedBox(height: 30),

            // Total summary & Submit Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL PLEDGE:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        'KES ${_getTotalPledgeAmount().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _submitPledges,
                      icon: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _submitting
                            ? 'Submitting Pledges...'
                            : 'Confirm & Create Pledges',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPledgeFormTile(String type) {
    final amountCtrl = _pledgeAmountCtrls[type]!;
    final descCtrl = _descriptionCtrls[type]!;
    final targetDate = _targetDates[type];
    final hasAmount = _toDouble(amountCtrl.text) > 0;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasAmount ? AppColors.success : Colors.grey.shade200,
          width: hasAmount ? 2 : 1,
        ),
      ),
      elevation: hasAmount ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        key: ValueKey(type), // Ensures correct state management
        leading: Icon(
          _iconForType(type),
          color: hasAmount ? AppColors.success : AppColors.primary,
        ),
        title: Text(
          type,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: hasAmount ? AppColors.success : AppColors.textDark,
          ),
        ),
        subtitle: Text(
          hasAmount
              ? 'Pledge: KES ${_toDouble(amountCtrl.text).toStringAsFixed(2)}'
              : 'Tap to enter pledge amount',
          style: TextStyle(
            color: hasAmount ? Colors.green.shade700 : Colors.grey.shade600,
            fontWeight: hasAmount ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Pledge Amount (KES)*',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
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
                        : 'Target: ${DateFormat('MMM dd, yyyy').format(targetDate)}',
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
                      initialDate: targetDate ?? DateTime.now(),
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
  }

  Widget _buildSummaryCard() {
    final totalPledged = _toDouble(_summary?['total_pledged']);
    final totalFulfilled = _toDouble(_summary?['total_fulfilled']);
    final totalRemaining = _toDouble(_summary?['total_remaining']);
    final percentage = _toDouble(_summary?['fulfillment_percentage']);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Pledge Portfolio Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Pledged',
                  totalPledged,
                  AppColors.info,
                  Icons.archive_outlined,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Fulfilled',
                  totalFulfilled,
                  AppColors.success,
                  Icons.check_circle_outline,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Remaining',
                  totalRemaining,
                  AppColors.warning,
                  Icons.watch_later_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'KES ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
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
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _filterStatus = status);
            _loadPledges();
          }
        },
        backgroundColor: Colors.grey.shade100,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        elevation: isSelected ? 2 : 0,
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
        ? DateTime.tryParse(pledge['target_date'])
        : null;
    final description = pledge['description'] ?? '';
    final isActive = status == 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _statusColor(status).withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          _iconForType(accountType),
          color: _statusColor(status),
          size: 30,
        ),
        title: Text(
          accountType,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'KES ${pledgeAmount.toStringAsFixed(2)} pledged',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            if (targetDate != null)
              Text(
                'Target: ${DateFormat('MMM dd, yyyy').format(targetDate)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_statusColor(status)),
              minHeight: 6,
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(1)}% Complete | Remaining: KES ${remainingAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: isActive
            ? IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                onPressed: () => _editPledge(pledge),
                tooltip: 'Edit Pledge',
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
        onTap: () {
          // Could open a detailed view or directly use the edit dialog for active items
          if (isActive) {
            _editPledge(pledge);
          } else if (description.isNotEmpty) {
            // Show description for fulfilled/cancelled items
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('$accountType Details'),
                content: Text(description),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildGroupedPledgesList() {
    // Group pledges by account type
    final Map<String, List<Map<String, dynamic>>> groupedPledges = {};

    for (var pledge in _pledges) {
      final accountType = pledge['account_type'] ?? 'Others';
      if (!groupedPledges.containsKey(accountType)) {
        groupedPledges[accountType] = [];
      }
      groupedPledges[accountType]!.add(pledge);
    }

    // Sort account types according to the standard order
    final sortedAccountTypes = groupedPledges.keys.toList()
      ..sort((a, b) {
        final indexA = _accountTypes.indexOf(a);
        final indexB = _accountTypes.indexOf(b);
        if (indexA == -1 && indexB == -1) return a.compareTo(b);
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedAccountTypes.length,
      itemBuilder: (context, index) {
        final accountType = sortedAccountTypes[index];
        final pledgesForType = groupedPledges[accountType]!;

        // If there's only one pledge, show the detailed card directly (simpler UI)
        if (pledgesForType.length == 1) {
          return _buildPledgeCard(pledgesForType[0]);
        }

        // If multiple pledges for same type, show grouped section
        return _buildGroupedPledgeSection(accountType, pledgesForType);
      },
    );
  }

  Widget _buildGroupedPledgeSection(
    String accountType,
    List<Map<String, dynamic>> pledges,
  ) {
    double totalPledged = 0;
    double totalFulfilled = 0;

    for (var pledge in pledges) {
      totalPledged += _toDouble(pledge['pledge_amount']);
      totalFulfilled += _toDouble(pledge['fulfilled_amount']);
    }

    final overallPercentage = totalPledged > 0
        ? (totalFulfilled / totalPledged * 100)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(
          _iconForType(accountType),
          color: AppColors.primary,
          size: 30,
        ),
        title: Text(
          '$accountType Pledges',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${pledges.length} individual pledge${pledges.length > 1 ? 's' : ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Pledged: KES ${totalPledged.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${overallPercentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ),
        children: [
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 12),
          ...pledges.asMap().entries.map((entry) {
            final pledge = entry.value;
            // Use a compact list item for nested pledges
            return _buildCompactPledgeListItem(pledge);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCompactPledgeListItem(Map<String, dynamic> pledge) {
    final pledgeAmount = _toDouble(pledge['pledge_amount']);
    final fulfilledAmount = _toDouble(pledge['fulfilled_amount']);
    final status = pledge['status'] ?? 'active';
    final isFulfilled = status == 'fulfilled';
    final targetDate = pledge['target_date'] != null
        ? DateTime.tryParse(pledge['target_date'])
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isFulfilled ? Icons.check_circle : Icons.pending_outlined,
                size: 18,
                color: _statusColor(status),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pledged: KES ${pledgeAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Paid: KES ${fulfilledAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isFulfilled
                          ? AppColors.success
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (targetDate != null)
                Text(
                  DateFormat('MMM yyyy').format(targetDate),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              if (status == 'active')
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  color: AppColors.primary,
                  onPressed: () => _editPledge(pledge),
                  tooltip: 'Edit Pledge',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final message = _filterStatus == 'active'
        ? "You have no active pledges. Create a new pledge!"
        : "No ${_filterStatus} pledges found.";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (!_showCreateForm)
            ElevatedButton.icon(
              onPressed: _createPledge,
              icon: const Icon(Icons.add),
              label: const Text('Start New Pledge'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
