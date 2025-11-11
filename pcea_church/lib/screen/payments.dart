import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneCtl = TextEditingController();

  final Map<String, TextEditingController> _amountCtrls = {
    'Tithe': TextEditingController(text: '0'),
    'Offering': TextEditingController(text: '0'),
    'Development': TextEditingController(text: '0'),
    'Thanksgiving': TextEditingController(text: '0'),
    'FirstFruit': TextEditingController(text: '0'),
    'Others': TextEditingController(text: '0'),
  };

  static const List<String> _accountTypes = [
    'Tithe',
    'Offering',
    'Development',
    'Thanksgiving',
    'FirstFruit',
    'Others',
  ];

  bool _submitting = false;
  String? _lastMessage;
  Color _lastMessageColor = Colors.green;
  String? _lastCheckoutId;
  List<Map<String, dynamic>> _activePledges = [];

  double get _totalAmount {
    double sum = 0;
    for (final ctrl in _amountCtrls.values) {
      final n = double.tryParse(ctrl.text.trim()) ?? 0;
      sum += n;
    }
    return sum;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_totalAmount <= 0) {
      setState(() {
        _lastMessage = 'Please enter at least one positive amount.';
        _lastMessageColor = Colors.red;
      });
      return;
    }

    setState(() => _submitting = true);

    try {
      final ek = await _getEKNumber();
      final selectedCodes = _accountTypes
          .where(
            (t) => (double.tryParse(_amountCtrls[t]!.text.trim()) ?? 0) > 0,
          )
          .map((t) => _mapCode(t))
          .toList();

      final codeSuffix = selectedCodes.isEmpty
          ? 'OT'
          : (selectedCodes.length == 1 ? selectedCodes.first : 'MULTI');
      final accountRef = ek.isNotEmpty ? '$ek$codeSuffix' : codeSuffix;

      // Build breakdown with only non-zero amounts
      final Map<String, double> breakdown = {};
      for (final t in _accountTypes) {
        final amount = double.tryParse(_amountCtrls[t]!.text.trim()) ?? 0;
        if (amount > 0) {
          breakdown[t] = amount;
        }
      }

      final resp = await API().postRequest(
        url: Uri.parse('${Config.baseUrl}/mpesa/stkpush'),
        data: {
          'phone': _phoneCtl.text.trim(),
          'amount': _totalAmount,
          'reference': accountRef,
          'breakdown': breakdown,
        },
      );

      final body = jsonDecode(resp.body);
      _lastCheckoutId = body['CheckoutRequestID']?.toString();
      final msg =
          body['CustomerMessage']?.toString() ??
          body['ResponseDescription']?.toString() ??
          'STK push initiated. Check your phone.';

      setState(() {
        _lastMessage = msg;
        _lastMessageColor = Colors.teal;
      });

      if (_lastCheckoutId != null && _lastCheckoutId!.isNotEmpty) {
        _pollStatus(_lastCheckoutId!);
      }
    } catch (e) {
      setState(() {
        _lastMessage = 'Error: $e';
        _lastMessageColor = Colors.red;
      });
    }

    setState(() => _submitting = false);
  }

  Future<void> _pollStatus(String checkoutId) async {
    const attempts = 8;
    for (int i = 0; i < attempts; i++) {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      try {
        final res = await API().getRequest(
          url: Uri.parse(
            '${Config.baseUrl}/payments/status?checkout_request_id=$checkoutId',
          ),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final state = (data['state'] ?? '').toString();
          final msg = (data['message'] ?? data['result_desc'] ?? '').toString();

          if (state == 'success') {
            setState(() {
              _lastMessage = msg.isNotEmpty ? msg : 'Payment successful!';
              _lastMessageColor = Colors.green.shade700;
            });
            // Reload pledges after successful payment
            _loadActivePledges();
            return;
          }
          if (state == 'failed') {
            setState(() {
              _lastMessage = msg.isNotEmpty ? msg : 'Payment failed.';
              _lastMessageColor = Colors.red.shade700;
            });
            return;
          }

          setState(() {
            _lastMessage = msg.isNotEmpty
                ? msg
                : 'Awaiting your confirmation on phone...';
            _lastMessageColor = Colors.blueGrey;
          });
        }
      } catch (_) {}
    }
  }

  Future<String> _getEKNumber() async {
    try {
      final res = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/members/me'),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final member = body['member'] as Map<String, dynamic>?;
        return (member?['e_kanisa_number'] ?? '').toString();
      }
    } catch (_) {}
    return '';
  }

  String _mapCode(String type) {
    switch (type) {
      case 'Tithe':
        return 'T';
      case 'Offering':
        return 'O';
      case 'Development':
        return 'D';
      case 'Thanksgiving':
        return 'TG';
      case 'FirstFruit':
        return 'FF';
      default:
        return 'OT';
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

  double _toDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? defaultValue;
  }

  Future<void> _loadActivePledges() async {
    try {
      final res = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/member/pledges?status=active'),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['status'] == 200) {
          setState(() {
            _activePledges = List<Map<String, dynamic>>.from(
              body['pledges'] ?? [],
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading pledges: $e');
    } finally {}
  }

  void _showPayPledgesDialog() {
    if (_activePledges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active pledges found. Create a pledge first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Group pledges by account type and calculate total remaining
    final Map<String, double> pledgeAmounts = {};
    final Map<String, double> maxAmounts = {};
    for (var pledge in _activePledges) {
      final accountType = pledge['account_type'] as String;
      final remaining = _toDouble(pledge['remaining_amount']);
      if (remaining > 0) {
        pledgeAmounts[accountType] =
            (pledgeAmounts[accountType] ?? 0) + remaining;
        maxAmounts[accountType] = pledgeAmounts[accountType]!;
      }
    }

    if (pledgeAmounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All your pledges are already fulfilled!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    // Create controllers for editable amounts in the dialog
    final Map<String, TextEditingController> dialogAmountCtrls = {};
    for (var entry in pledgeAmounts.entries) {
      if (_accountTypes.contains(entry.key)) {
        dialogAmountCtrls[entry.key] = TextEditingController(
          text: entry.value.toStringAsFixed(2),
        );
      }
    }

    // Show dialog with editable amounts
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Calculate total from dialog controllers
            double calculateTotal() {
              double total = 0;
              for (var ctrl in dialogAmountCtrls.values) {
                total += double.tryParse(ctrl.text.trim()) ?? 0;
              }
              return total;
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.flag, color: Color(0xFF0A1F44)),
                  SizedBox(width: 8),
                  Text('Pay Pledges'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit the amounts you want to pay for each pledge. You can pay less than the full amount.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ...pledgeAmounts.entries.map((entry) {
                      final accountType = entry.key;
                      final maxAmount = maxAmounts[accountType]!;
                      final ctrl = dialogAmountCtrls[accountType]!;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  accountType,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Max: KES ${maxAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: ctrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Amount to pay (KES)',
                                prefixIcon: const Icon(Icons.money),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                hintText: '0.00',
                              ),
                              onChanged: (_) {
                                setDialogState(() {});
                              },
                              validator: (value) {
                                final amount =
                                    double.tryParse(value?.trim() ?? '') ?? 0;
                                if (amount < 0) {
                                  return 'Amount cannot be negative';
                                }
                                if (amount > maxAmount) {
                                  return 'Amount cannot exceed remaining pledge';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'KES ${calculateTotal().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validate amounts
                    bool isValid = true;
                    for (var entry in pledgeAmounts.entries) {
                      final accountType = entry.key;
                      final ctrl = dialogAmountCtrls[accountType]!;
                      final amount =
                          double.tryParse(ctrl.text.trim()) ?? 0;
                      final maxAmount = maxAmounts[accountType]!;

                      if (amount < 0 || amount > maxAmount) {
                        isValid = false;
                        break;
                      }
                    }

                    if (!isValid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter valid amounts within the pledge limits.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Update the main form controllers with dialog values
                    for (var entry in dialogAmountCtrls.entries) {
                      final accountType = entry.key;
                      final amount =
                          double.tryParse(entry.value.text.trim()) ?? 0;
                      if (_accountTypes.contains(accountType)) {
                        _amountCtrls[accountType]!.text = amount.toStringAsFixed(2);
                      }
                    }

                    Navigator.pop(context);
                    setState(() {});

                    // Show success message
                    Future.delayed(const Duration(milliseconds: 300), () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Pledge amounts loaded. Review and proceed to payment.',
                          ),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1F44),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply Amounts'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Clean up controllers when dialog is closed (regardless of how it's closed)
      for (var ctrl in dialogAmountCtrls.values) {
        try {
          ctrl.dispose();
        } catch (_) {
          // Controller already disposed or error, ignore
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadActivePledges();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Cashless Contributions (M-Pesa)'),
        backgroundColor: Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_activePledges.isNotEmpty)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.flag),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: const Text(
                        '',
                        style: TextStyle(color: Colors.white, fontSize: 8),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: _showPayPledgesDialog,
              tooltip: 'Pay Pledges',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 100, // Extra padding to prevent overlap with bottom navbar
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_lastMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    color: _lastMessageColor.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: _lastMessageColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lastMessage!,
                              style: TextStyle(
                                color: _lastMessageColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Header
              Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 100,
                    color: Color(0xFF0A1F44),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Make a Contribution",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Support the church by selecting account type",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Phone number
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextFormField(
                    controller: _phoneCtl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Enter your M-Pesa phone number',
                      hintText: '0712345678',
                      prefixIcon: Icon(Icons.phone_android),
                      border: InputBorder.none,
                    ),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return 'Enter phone number';
                      if (t.length < 9) return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pay Pledges Button
              if (_activePledges.isNotEmpty)
                Card(
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: _showPayPledgesDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pay Your Pledges',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${_activePledges.length} active pledge(s)',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_activePledges.isNotEmpty) const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select accounts to contribute to:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 🌿 ExpansionTiles for each account
              ..._accountTypes.map((type) {
                final ctrl = _amountCtrls[type]!;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ExpansionTile(
                    leading: Icon(_iconForType(type), color: Color(0xFF0A1F44)),
                    title: Text(
                      type,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: TextFormField(
                          controller: ctrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Enter amount for $type (KES)',
                            prefixIcon: const Icon(Icons.money),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 10),

              // Total summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.summarize, color: Color(0xFF0A1F44)),
                    const SizedBox(width: 10),
                    const Text(
                      'Total amount to contribute:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'KES ${_totalAmount.toStringAsFixed(2)}',
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
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.payment),
                  label: const Text(
                    'Make Contribution',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
