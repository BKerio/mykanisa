import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// PACKAGES
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gal/gal.dart';
// THIS IMPORT IS REQUIRED FOR BARCODES
import 'package:barcode_widget/barcode_widget.dart';

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
  final GlobalKey _cardKey = GlobalKey();

  // PCEA Brand Colors
  final Color _pceaBlue = const Color(0xFF003366);
  final Color _pceaGold = const Color(0xFFD4AF37);

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

  // 1. DATA GENERATION FOR BARCODE
  // We strip this down to the unique ID so the barcode remains short and scannable.
  String _generateBarcodeData() {
    if (memberData == null) return '000000';
    return memberData!['e_kanisa_number'] ?? '000000';
  }

  // 2. DATA GENERATION FOR QR (Hidden fallback if needed)
  String _generateQRData() {
    if (memberData == null) return '';
    final qrData = {
      'type': 'PCEA',
      'id': memberData!['id'],
      'kanisa': memberData!['e_kanisa_number'],
    };
    return jsonEncode(qrData);
  }

  Future<void> _saveCardToGallery() async {
    try {
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        bool granted = await Gal.requestAccess();
        if (!granted) {
          _showMessage('Gallery access permission required');
          return;
        }
      }

      final RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      await Gal.putImageBytes(
        pngBytes,
        album: "PCEA Church",
        name: "PCEA_Member_${memberData!['e_kanisa_number']}",
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
        backgroundColor: isSuccess
            ? Colors.green.shade700
            : Colors.red.shade700,
      ),
    );
  }

  // POPUP FOR LARGER VIEW
  void _showLargeScannerView() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scanner View',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan the barcode below',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // LARGE BARCODE DISPLAY
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: _generateBarcodeData(),
                    drawText: true,
                    height: 100,
                    width: double.infinity,
                    style: const TextStyle(
                      fontSize: 18,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pceaBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Digital Membership'),
        centerTitle: true,
        backgroundColor: _pceaBlue,
        foregroundColor: Colors.white,
        actions: [
          if (memberData != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _saveCardToGallery,
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: _pceaBlue))
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 40, color: Colors.red),
                  const SizedBox(height: 10),
                  Text(errorMessage!),
                  ElevatedButton(
                    onPressed: _loadMemberData,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Center(
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: _buildBarcodeCard(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Tap card to enlarge barcode",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBarcodeCard() {
    final imageUrl = memberData?['profile_image_url'];

    return GestureDetector(
      onTap: _showLargeScannerView,
      child: Container(
        width: 360,
        height: 540,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _pceaBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_pceaBlue, const Color(0xFF001F3F)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative Circle
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 30,
                  ),
                ),
              ),
            ),

            Column(
              children: [
                // 1. Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _pceaGold,
                        ),
                        child: ClipOval(
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(Icons.person, color: _pceaBlue),
                                )
                              : Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.white,
                                  child: Icon(
                                    Icons.person,
                                    color: _pceaBlue,
                                    size: 40,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PCEA CHURCH',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'OFFICIAL MEMBER',
                            style: TextStyle(
                              color: _pceaGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white24, thickness: 1),

                // 2. Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "NAME",
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        memberData!['full_name']?.toUpperCase() ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "CONGREGATION",
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        memberData!['congregation'] ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 3. BARCODE FOOTER (THE FIX)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // --- BARCODE WIDGET ---
                      // Code 128 is the standard "short" barcode
                      BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: _generateBarcodeData(),
                        drawText:
                            false, // We draw customized text below instead
                        color: Colors.black,
                        width: double.infinity,
                        height: 60, // Fixed height for clean look
                      ),
                      const SizedBox(height: 8),
                      // The Readable Text
                      Text(
                        memberData!['e_kanisa_number'] ?? '',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "MEMBER ID",
                        style: TextStyle(
                          color: _pceaBlue.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
