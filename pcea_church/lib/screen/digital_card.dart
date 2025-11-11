import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gal/gal.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';

class DigitalCardScreen extends StatefulWidget {
  const DigitalCardScreen({super.key});

  @override
  State<DigitalCardScreen> createState() => _DigitalCardScreenState();
}

class _DigitalCardScreenState extends State<DigitalCardScreen> {
  Map<String, dynamic>? memberData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    try {
      final response = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/members/me'),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200) {
          setState(() {
            memberData = body['member'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = body['message'] ?? 'Failed to load member data';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load member data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading member data: $e';
        isLoading = false;
      });
    }
  }

  String _generateQRData() {
    if (memberData == null) return '';

    final qrData = {
      'type': 'PCEA_MEMBER',
      'member_id': memberData!['id'],
      'e_kanisa_number': memberData!['e_kanisa_number'],
      'full_name': memberData!['full_name'],
      'congregation': memberData!['congregation'],
      'parish': memberData!['parish'],
      'presbytery': memberData!['presbytery'],
      'region': memberData!['region'],
      'generated_at': DateTime.now().toIso8601String(),
    };

    return jsonEncode(qrData);
  }

  Future<void> _saveCardToGallery() async {
    try {
      // Check if gal has permission
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        bool granted = await Gal.requestAccess();
        if (!granted) {
          _showMessage('Gallery access permission required to save card');
          return;
        }
      }

      // Capture the card as image
      final RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to gallery using gal
      await Gal.putImageBytes(
        pngBytes,
        album: "PCEA Church",
        name: "PCEA_Member_Card_${memberData!['e_kanisa_number']}",
      );

      _showMessage('Card saved to gallery successfully!', isSuccess: true);
    } catch (e) {
      _showMessage('Error saving card: $e');
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  void _showLargeQR() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scan QR Code',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: QrImageView(
                    data: _generateQRData(),
                    version: QrVersions.auto,
                    size: 250.0,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    errorStateBuilder: (cxt, err) {
                      return Container(
                        child: const Center(
                          child: Text(
                            'QR Code Error',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'E-Kanisa: ${memberData!['e_kanisa_number'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  memberData!['full_name'] ?? 'N/A',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  final GlobalKey _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      appBar: AppBar(
        title: const Text('Digital Membership Card'),
        backgroundColor: const Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (memberData != null) ...[
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: _showLargeQR,
              tooltip: 'View Large QR',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _saveCardToGallery,
              tooltip: 'Save Card',
            ),
          ],
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMemberData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _buildDigitalCard(),
                ),
              ),
            ),
    );
  }

  Widget _buildDigitalCard() {
    return Container(
      width: 480,
      height: 380,
      decoration: BoxDecoration(
        color: Color(0xFF0A1F44),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),

          // Card content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          "assets/icon.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PCEA CHURCH',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'MEMBER CARD',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Main content area with member details and QR code
                Expanded(
                  child: Row(
                    children: [
                      // Left side - Member details
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              memberData!['full_name'] ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'E-Kanisa: ${memberData!['e_kanisa_number'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${memberData!['congregation'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${memberData!['parish'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${memberData!['presbytery'] ?? 'N/A'}, ${memberData!['region'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Right side - Large QR Code
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black26, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: QrImageView(
                            data: _generateQRData(),
                            version: QrVersions.auto,
                            size: 136,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            errorStateBuilder: (cxt, err) {
                              return Container(
                                child: const Center(
                                  child: Text(
                                    'QR Error',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Footer
                Row(
                  children: [
                    const Spacer(),
                    Text(
                      'Valid Member',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
