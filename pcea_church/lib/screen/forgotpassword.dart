// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:pcea_church/config/server.dart';
// import 'package:pcea_church/method/api.dart';
// import 'package:pcea_church/screen/verifycode.dart';

// class ForgotPasswordScreen extends StatefulWidget {
//   const ForgotPasswordScreen({super.key});

//   @override
//   State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
// }

// class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
//   final identifierController = TextEditingController();
//   bool isLoading = false;
//   String channel = 'email';
//   int resendSeconds = 0;
//   Timer? _timer;

//   void startResendTimer() {
//     setState(() => resendSeconds = 30);
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (resendSeconds > 0) {
//         setState(() => resendSeconds--);
//       } else {
//         timer.cancel();
//       }
//     });
//   }

//   Future<void> sendResetCode() async {
//     final identifier = identifierController.text.trim();
//     if (identifier.isEmpty) {
//       API.showSnack(context, "Please enter email or E-Kanisa number");
//       return;
//     }

//     setState(() => isLoading = true);

//     try {
//       final response = await API().postRequest(
//         url: Uri.parse("${Config.baseUrl}/forgot-password"),
//         data: {"identifier": identifier, "channel": channel},
//       );

//       final result = jsonDecode(response.body);

//       if (result["status"] == 200) {
//         API.showSnack(
//           context,
//           channel == "sms"
//               ? "Reset code sent via SMS"
//               : "Reset code sent to your email",
//           success: true,
//         );
//         startResendTimer();
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => VerifyResetCodeScreen(identifier: identifier),
//           ),
//         );
//       } else {
//         API.showSnack(context, result["message"], success: false);
//       }
//     } catch (e) {
//       API.showSnack(context, "Something went wrong", success: false);
//     }

//     setState(() => isLoading = false);
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final primaryColor = const Color(0xFF0A1F44);

//     return Scaffold(
//       backgroundColor: const Color(0xFFE8F4FD),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 20,
//                     offset: const Offset(0, 10),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Circular logo with shadow
//                   Container(
//                     width: 120,
//                     height: 120,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.white,
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.25),
//                           blurRadius: 10,
//                           offset: const Offset(0, 5),
//                         ),
//                       ],
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(10),
//                       child: ClipOval(
//                         child: Image.asset(
//                           "assets/icon.png",
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   const Text(
//                     "Forgot Password",
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF2E3A59),
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // Toggle chips
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       ChoiceChip(
//                         label: const Text("Send via E-mail or e-Kanisa No."),
//                         selected: channel == "email",
//                         selectedColor: const Color(0xFF0A1F44),
//                         labelStyle: TextStyle(
//                           color: channel == "email"
//                               ? Colors.white
//                               : Colors.black,
//                           fontWeight: FontWeight.w600,
//                         ),
//                         backgroundColor: Colors.grey.shade200,
//                         onSelected: (v) => setState(() => channel = "email"),
//                       ),
//                       const SizedBox(width: 12),
//                       ChoiceChip(
//                         label: const Text("Send via SMS"),
//                         selected: channel == "sms",
//                         selectedColor: const Color(0xFF0A1F44),
//                         labelStyle: TextStyle(
//                           color: channel == "sms" ? Colors.white : Colors.black,
//                           fontWeight: FontWeight.w600,
//                         ),
//                         backgroundColor: Colors.grey.shade200,
//                         onSelected: (v) => setState(() => channel = "sms"),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // Identifier input
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 12,
//                     ),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey.shade300),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: TextField(
//                       controller: identifierController,
//                       decoration: InputDecoration(
//                         hintText: channel == 'sms'
//                             ? 'Enter phone number (0712345678)'
//                             : 'Enter e-mail or e-Kanisa number',
//                         border: InputBorder.none,
//                         prefixIcon: Icon(
//                           channel == 'sms'
//                               ? Icons.sms_outlined
//                               : Icons.email_outlined,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   // Send button
//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryColor,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 0,
//                       ),
//                       onPressed: isLoading ? null : sendResetCode,
//                       child: isLoading
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : const Text(
//                               "Send Reset Code",
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.white,
//                               ),
//                             ),
//                     ),
//                   ),

//                   const SizedBox(height: 12),

//                   // Resend
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         resendSeconds > 0
//                             ? "Resend in ${resendSeconds}s"
//                             : "Didn't receive the code?",
//                         style: const TextStyle(color: Colors.grey),
//                       ),
//                       if (resendSeconds == 0)
//                         TextButton(
//                           onPressed: () {
//                             if (!isLoading) sendResetCode();
//                           },
//                           child: const Text(
//                             "Resend",
//                             style: TextStyle(
//                               color: Color(0xFF0A1F44),
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pcea_church/components/responsive_layout.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/screen/verifycode.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final identifierController = TextEditingController();
  bool isLoading = false;
  String channel = 'email';
  int resendSeconds = 0;
  Timer? _timer;

  void startResendTimer() {
    setState(() => resendSeconds = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSeconds > 0) {
        setState(() => resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> sendResetCode() async {
    final identifier = identifierController.text.trim();
    if (identifier.isEmpty) {
      API.showSnack(
        context,
        "Please enter your email, My Kanisa number, or phone number",
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await API().postRequest(
        url: Uri.parse("${Config.baseUrl}/forgot-password"),
        data: {"identifier": identifier, "channel": channel},
      );

      final result = jsonDecode(response.body);

      if (result["status"] == 200) {
        startResendTimer();
        // Navigate immediately to verify code screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VerifyResetCodeScreen(identifier: identifier, channel: channel),
          ),
        );
      } else {
        API.showSnack(context, result["message"], success: false);
      }
    } catch (e) {
      API.showSnack(context, "Something went wrong", success: false);
    }

    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildForgotCard() {
    const primaryColor = Color(0xFF0A1F44);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ClipOval(
                child: Image.asset("assets/icon.png", fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Forgot Password",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3A59),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Enter your email, My Kanisa number, or phone number to receive a reset code.",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              ChoiceChip(
                label: const Text("Send via Email"),
                selected: channel == "email",
                selectedColor: primaryColor,
                labelStyle: TextStyle(
                  color: channel == "email" ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: Colors.grey.shade200,
                onSelected: (_) => setState(() => channel = "email"),
              ),
              ChoiceChip(
                label: const Text("Send via SMS"),
                selected: channel == "sms",
                selectedColor: primaryColor,
                labelStyle: TextStyle(
                  color: channel == "sms" ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: Colors.grey.shade200,
                onSelected: (_) => setState(() => channel = "sms"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: identifierController,
              decoration: const InputDecoration(
                hintText: 'Enter your email, My Kanisa number, or phone number',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.person_outline, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: isLoading ? null : sendResetCode,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Send Reset Code",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                resendSeconds > 0
                    ? "Resend in ${resendSeconds}s"
                    : "Didn't receive the code?",
                style: const TextStyle(color: Colors.grey),
              ),
              if (resendSeconds == 0)
                TextButton(
                  onPressed: () {
                    if (!isLoading) sendResetCode();
                  },
                  child: const Text(
                    "Resend",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildForgotCard(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return DesktopScaffoldFrame(
      backgroundColor: const Color(0xFFE8F4FD),
      title: '',
      primaryColor: const Color(0xFF35C2C1),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: _buildForgotCard(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }
}
