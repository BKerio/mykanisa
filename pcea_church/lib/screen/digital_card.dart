import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
  final GlobalKey _cardKey = GlobalKey();

  // PCEA Primary Color
  static const Color primaryNavy = Color(0xFF0A1F44);

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
      'phone': memberData!['telephone'] ?? '',
      'baptized': memberData!['is_baptized'] ?? false,
      'taking_holy_communion': memberData!['takes_holy_communion'] ?? false,
    };

    return jsonEncode(qrData);
  }

  Future<void> _saveCardToGallery() async {
    if (_cardKey.currentContext == null || memberData == null) return;

    try {
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        bool granted = await Gal.requestAccess();
        if (!granted) {
          _showMessage('Gallery access permission required to save card');
          return;
        }
      }

      final RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // Using a higher pixel ratio (5.0) for a sharper image capture
      final image = await boundary.toImage(pixelRatio: 5.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

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
        backgroundColor: isSuccess
            ? Colors.green.shade700
            : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLargeQR() {
    if (memberData == null) return;
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
                      return const Center(
                        child: Text(
                          'QR Code Error',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kanisa No: ${memberData!['e_kanisa_number'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      appBar: AppBar(
        title: const Text('Digital Membership Card'),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (memberData != null) ...[
            IconButton(
              icon: const Icon(Icons.qr_code_2_sharp),
              onPressed: _showLargeQR,
              tooltip: 'View Large QR',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _saveCardToGallery,
              tooltip: 'Save Card to Gallery',
            ),
          ],
        ],
      ),
      body: isLoading
          ? Center(
              child: SpinKitFadingCircle(
                size: 64,
                duration: const Duration(milliseconds: 1800),
                itemBuilder: (context, index) {
                  final palette = const [
                    primaryNavy,
                    Color(0xFF8B0000), // Deep Red accent
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
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Center(
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _buildDigitalCard(),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileAvatar(String? imageUrl) {
    const double size = 120;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/icon.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset(
                'assets/icon.png', // Fallback
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget _buildDigitalCard() {
    final member = memberData!;
    final imageUrl = member['profile_image_url'];
    final qrData = _generateQRData();

    // Standard credit card dimensions (e.g., 350x220 pixels)
    const double cardWidth = 480;
    const double cardHeight = 280;

    // A secondary accent color (Gold/Yellowish) for emphasis
    const Color accentColor = Color(0xFFFDD835); // Amber/Gold tone

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: const LinearGradient(
          colors: [
            primaryNavy,
            Color(0xFF1B3A6B), // Slightly lighter bottom-right
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Subtle background pattern element 1 (Top Right)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.05),
              ),
            ),
          ),
          // Subtle background pattern element 2 (Bottom Left)
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // Main Content Layout
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Main Details (Profile, Name, ID, QR)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Member Details (Left Side)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildProfileAvatar(imageUrl),
                          const SizedBox(height: 10),

                          // Full Name
                          Text(
                            member['full_name'] ?? 'N/A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Kanisa Number (Highlight)
                          Text(
                            member['e_kanisa_number'] ?? 'N/A',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Congregation
                          Text(
                            'Congregation: ${member['congregation'] ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 15),

                    // QR Code (Right Side)
                    Container(
                      width: 200,
                      height: 210,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 75,
                        backgroundColor: Colors.white,
                        foregroundColor: primaryNavy,
                        errorStateBuilder: (cxt, err) {
                          return const Center(
                            child: Text(
                              'QR Error',
                              style: TextStyle(fontSize: 8),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),

          // Subtle Footer/Chip identifier
          Positioned(
            bottom: 8,
            right: 30,
            child: Text(
              'Property of ${member['congregation'] ?? 'PCEA Church'}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
