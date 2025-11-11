import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pcea_church/components/settings.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/screen/add_dependents.dart';
import 'package:pcea_church/screen/login.dart';
import 'package:pcea_church/screen/payments.dart';
import 'package:pcea_church/screen/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BaseDashboard extends StatefulWidget {
  const BaseDashboard({super.key});

  @override
  State<BaseDashboard> createState() => BaseDashboardState();

  // Abstract methods to be implemented by specific role dashboards
  String getRoleTitle();
  String getRoleDescription();
  List<DashboardCard> getDashboardCards(BuildContext context);
  List<BottomNavigationBarItem> getBottomNavItems();
  Color getPrimaryColor();
  Color getSecondaryColor();
  IconData getRoleIcon();
}

class BaseDashboardState extends State<BaseDashboard> {
  SharedPreferences? preferences;
  String username = '';
  String email = '';
  int userId = 0;
  bool isEkanisaVisible = false;
  String congregationName = '';
  String role = '';
  String currentTime = '';
  bool isLoading = false;
  int _selectedIndex = 0;
  List<Map<String, dynamic>> userRoles = [];
  List<Map<String, dynamic>> userPermissions = [];
  bool _showAllActions = false;
  String? profileImageUrl;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _startClock();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    preferences = await SharedPreferences.getInstance();
    final savedImageUrl = preferences?.getString('profile_image_url');
    setState(() {
      username = preferences?.getString('name') ?? '';
      email = preferences?.getString('email') ?? '';
      userId = preferences?.getInt('user_id') ?? 0;
      role = preferences?.getString('role') ?? 'member';
      profileImageUrl = savedImageUrl;
    });
    if (savedImageUrl != null && savedImageUrl.isNotEmpty) {
      print('Loaded profile image URL from preferences: $savedImageUrl');
    }

    await _fetchMemberData();
    await _fetchUserRoles();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchMemberData() async {
    try {
      final result = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/members/me'),
      );

      if (result.statusCode == 200) {
        final response = jsonDecode(result.body);

        if (response['status'] == 200 && response['member'] != null) {
          final member = response['member'];
          role = member['role'] ?? 'member';
          final imageUrl = member['profile_image_url'];
          //print('Received profile_image_url from API: $imageUrl');
          //print('Profile image URL type: ${imageUrl.runtimeType}');

          setState(() {
            congregationName = member['congregation'] ?? '';
            profileImageUrl = imageUrl?.toString();
          });

          if (preferences != null) {
            await preferences!.setString('congregation_name', congregationName);
            if (imageUrl != null && imageUrl.toString().isNotEmpty) {
              final urlString = imageUrl.toString();
              await preferences!.setString('profile_image_url', urlString);
              print('Profile image URL saved to preferences: $urlString');
            } else {
              print(
                'No profile image URL in response - clearing from preferences',
              );
              await preferences!.remove('profile_image_url');
            }
          }
        } else {
          setState(() {
            congregationName =
                preferences?.getString('congregation_name') ?? '';
          });
        }
      } else {
        setState(() {
          congregationName = preferences?.getString('congregation_name') ?? '';
        });
      }
    } catch (e) {
      setState(() {
        congregationName = preferences?.getString('congregation_name') ?? '';
        profileImageUrl = preferences?.getString('profile_image_url');
      });
      // print('Error fetching member data: $e');
    }
  }

  Widget _buildProfileImage() {
    const double imageSize = 240;

    if (profileImageUrl == null || profileImageUrl!.isEmpty) {
      return Container(
        height: imageSize,
        width: imageSize,
        decoration: BoxDecoration(
          color: const Color(0xFFB2EBF2),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/icon.png',
            fit: BoxFit.cover,
            width: imageSize,
            height: imageSize,
          ),
        ),
      );
    }

    String imageUrl = profileImageUrl!.trim();

    // Build full URL if necessary
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      final baseUrl = Config.baseUrl.replaceAll('/api', '');
      imageUrl = baseUrl + (imageUrl.startsWith('/') ? imageUrl : '/$imageUrl');
    }

    print('Building profile image with URL: $imageUrl');

    return Container(
      height: imageSize,
      width: imageSize,
      decoration: BoxDecoration(
        color: const Color(0xFFB2EBF2),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          key: ValueKey(imageUrl),
          fit: BoxFit.cover,
          width: imageSize,
          height: imageSize,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading profile image: $error');
            print('Failed URL: $imageUrl');
            return Image.asset(
              'assets/icon.png',
              fit: BoxFit.cover,
              width: imageSize,
              height: imageSize,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              print('Profile image loaded successfully');
              return child;
            }
            return SizedBox(
              width: imageSize,
              height: imageSize,
              child: Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              return child;
            }
            return Container(
              width: imageSize,
              height: imageSize,
              color: Colors.grey[200],
              child: const Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _fetchUserRoles() async {
    try {
      final result = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/leadership/dashboard'),
      );

      if (result.statusCode == 200) {
        final response = jsonDecode(result.body);
        if (response['status'] == 200) {
          setState(() {
            userRoles = List<Map<String, dynamic>>.from(
              response['roles'] ?? [],
            );
            userPermissions = List<Map<String, dynamic>>.from(
              response['permissions'] ?? [],
            );
          });
        }
      }
    } catch (e) {
      // If leadership endpoint fails, user might not have leadership roles
      print('Error fetching user roles: $e');
    }
  }

  void _startClock() {
    currentTime =
        "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}";
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        final now = DateTime.now();
        currentTime =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      });
    });
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String getEkanisaNumber() {
    return preferences?.getString('e_kanisa_number') ?? 'E-000000';
  }

  String maskEkanisaNumber() {
    final ekanisa = getEkanisaNumber();
    if (ekanisa.length <= 4) return ekanisa;
    return '${ekanisa.substring(0, 2)}${'*' * (ekanisa.length - 4)}${ekanisa.substring(ekanisa.length - 2)}';
  }

  void _logout() {
    preferences?.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        elevation: 10,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),

        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.orange,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Logout of the app',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        content: Text(
          '$username, are you sure you want to log out?',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
            height: 1.4,
          ),
        ),

        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(
              Icons.check_circle_outline,
              size: 18,
              color: Colors.white,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
            ),
            onPressed: () {
              Navigator.pop(ctx, true);
              _logout();
            },
            label: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            elevation: 12,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.orange,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Exit the app',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Are you sure you want to exit the app?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout, size: 18, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                label: const Text(
                  'Exit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const ProfileScreen();
      case 2:
        return const DependentsScreen();
      case 3:
        return const PaymentsPage();
      case 4:
        return const SettingsPage();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTopBar(),
          _buildUserInfoCard(),
          _buildDashboardGrid(),
          const SizedBox(height: 96),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFB2EBF2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _buildProfileImage(),
            ),

            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${getGreeting()} 👋🏾,',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$username.',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 30,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              ),
              icon: const Icon(
                Icons.notifications,
                color: Colors.black54,
                size: 36,
              ),
            ),

            IconButton(
              icon: const Icon(
                Icons.logout_outlined,
                color: Colors.black54,
                size: 36,
              ),
              onPressed: _confirmLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Card(
            elevation: 12,
            shadowColor: Colors.teal.withOpacity(0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Stack(
                children: [
                  // ✅ Watermark Logo
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: Center(
                        child: Image.asset(
                          'assets/icon.png', // <-- Add your logo in assets
                          height: 200,
                          width: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  // ✅ Foreground content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting
                        Text(
                          'Karibu, ${congregationName.isEmpty ? 'Imani' : congregationName}',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Email Row
                        Row(
                          children: [
                            const Icon(
                              Icons.email_rounded,
                              size: 18,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Role Row
                        Row(
                          children: [
                            const Icon(
                              Icons.volunteer_activism_rounded,
                              size: 18,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Role: ${widget.getRoleTitle()} at ${congregationName.isEmpty ? 'Imani' : congregationName}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Kanisa Card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFF1F2F3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.teal.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_box_rounded,
                                color: Color(0xFFF1F2F3),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'My Kanisa No:',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(opacity: anim, child: child),
                                child: Text(
                                  isEkanisaVisible
                                      ? getEkanisaNumber()
                                      : maskEkanisaNumber(),
                                  key: ValueKey<bool>(isEkanisaVisible),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isEkanisaVisible = !isEkanisaVisible;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.teal.withOpacity(0.15),
                                  ),
                                  child: Icon(
                                    isEkanisaVisible
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 20,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid() {
    final cards = widget.getDashboardCards(context);
    final visibleCards = _showAllActions ? cards : cards.take(4).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: const [
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: Colors.black45),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAllActions = !_showAllActions;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: widget.getPrimaryColor(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 0),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: Text(_showAllActions ? 'Show less' : 'View all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: visibleCards,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            Positioned.fill(child: _buildBody()),
            _buildFloatingNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    final items = widget.getBottomNavItems();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F2F3),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                _iconForItem(items[0]),
                items[0].label ?? 'Home',
                0,
              ),
              _buildNavItem(
                _iconForItem(items[1]),
                items[1].label ?? 'Profile',
                1,
              ),
              _buildCenterActionButton(),
              _buildNavItem(
                _iconForItem(items[2]),
                items[2].label ?? 'Dependents',
                2,
              ),
              _buildNavItem(
                _iconForItem(items.last),
                items.last.label ?? 'Settings',
                4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForItem(BottomNavigationBarItem item) {
    final widgetIcon = item.icon;
    if (widgetIcon is Icon) {
      return widgetIcon.icon ?? Icons.circle;
    }
    return Icons.circle;
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.black87 : Colors.black45,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.black87 : Colors.black54,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterActionButton() {
    return GestureDetector(
      onTap: () => _onItemTapped(3),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 4),
        ),
        child: const Center(
          child: Icon(Icons.wallet_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF4F6F8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
