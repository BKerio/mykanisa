import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

// NOTE: These custom imports are assumed to exist in your project structure
// If you are testing this code in isolation, you might need to mock or remove these imports.
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/config/server.dart';

// --- MemberProfile Model ---

class MemberProfile {
  final String fullName;
  final String email;
  final String eKanisaNumber;
  final String role;
  final String telephone;
  final String nationalId;
  final String dateOfBirth;
  final String gender;
  final String maritalStatus;
  final String presbytery;
  final String parish;
  final String congregation;
  final String groups;
  final bool isBaptized;
  final bool takesHolyCommunion;
  final String imagePath; // local file path
  final String imageUrl; // server URL
  final String passportImageUrl; // server URL

  MemberProfile({
    required this.fullName,
    required this.email,
    required this.eKanisaNumber,
    required this.role,
    required this.telephone,
    required this.nationalId,
    required this.dateOfBirth,
    required this.gender,
    required this.maritalStatus,
    required this.presbytery,
    required this.parish,
    required this.congregation,
    required this.groups,
    required this.isBaptized,
    required this.takesHolyCommunion,
    required this.imagePath,
    required this.imageUrl,
    required this.passportImageUrl,
  });

  MemberProfile copyWith({
    String? fullName,
    String? email,
    String? eKanisaNumber,
    String? role,
    String? telephone,
    String? nationalId,
    String? dateOfBirth,
    String? gender,
    String? maritalStatus,
    String? presbytery,
    String? parish,
    String? congregation,
    String? groups,
    bool? isBaptized,
    bool? takesHolyCommunion,
    String? imagePath,
    String? imageUrl,
    String? passportImageUrl,
  }) => MemberProfile(
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    eKanisaNumber: eKanisaNumber ?? this.eKanisaNumber,
    role: role ?? this.role,
    telephone: telephone ?? this.telephone,
    nationalId: nationalId ?? this.nationalId,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    gender: gender ?? this.gender,
    maritalStatus: maritalStatus ?? this.maritalStatus,
    presbytery: presbytery ?? this.presbytery,
    parish: parish ?? this.parish,
    congregation: congregation ?? this.congregation,
    groups: groups ?? this.groups,
    isBaptized: isBaptized ?? this.isBaptized,
    takesHolyCommunion: takesHolyCommunion ?? this.takesHolyCommunion,
    imagePath: imagePath ?? this.imagePath,
    imageUrl: imageUrl ?? this.imageUrl,
    passportImageUrl: passportImageUrl ?? this.passportImageUrl,
  );

  factory MemberProfile.fromJson(Map<String, dynamic> json) => MemberProfile(
    fullName: (json['full_name'] ?? '') as String,
    email: (json['email'] ?? '') as String,
    eKanisaNumber: (json['e_kanisa_number'] ?? '') as String,
    role: (json['role'] ?? 'member') as String,
    telephone: (json['telephone'] ?? '') as String,
    nationalId: (json['national_id'] ?? '') as String,
    dateOfBirth: (json['date_of_birth'] ?? '') as String,
    gender: (json['gender'] ?? 'Male') as String,
    maritalStatus: (json['marital_status'] ?? 'Single') as String,
    presbytery: (json['presbytery'] ?? '') as String,
    parish: (json['parish'] ?? '') as String,
    congregation: (json['congregation'] ?? '') as String,
    groups: (json['groups'] ?? '') as String,
    isBaptized: (json['is_baptized'] ?? false) == true,
    takesHolyCommunion: (json['takes_holy_communion'] ?? false) == true,
    imagePath: (json['image_path'] ?? '') as String,
    imageUrl: (json['profile_image_url'] ?? '') as String,
    passportImageUrl: (json['passport_image_url'] ?? '') as String,
  );

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'email': email,
    'e_kanisa_number': eKanisaNumber,
    'role': role,
    'telephone': telephone,
    'national_id': nationalId,
    'date_of_birth': dateOfBirth,
    'gender': gender,
    'marital_status': maritalStatus,
    'presbytery': presbytery,
    'parish': parish,
    'congregation': congregation,
    'groups': groups,
    'is_baptized': isBaptized,
    'takes_holy_communion': takesHolyCommunion,
    'image_path': imagePath,
    'profile_image_url': imageUrl,
    'passport_image_url': passportImageUrl,
  };
}

// --- Profile Screen Implementation ---

class ProfileScreen extends StatefulWidget {
  final int? autoOpenPage;
  const ProfileScreen({super.key, this.autoOpenPage});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = false;
  bool saving = false;
  late SharedPreferences prefs;
  MemberProfile? profile;
  File? selectedImage;

  // Text Controllers
  final fullName = TextEditingController();
  final email = TextEditingController();
  final dob = TextEditingController();
  final nationalId = TextEditingController();
  final telephone = TextEditingController();
  final presbytery = TextEditingController();
  final parish = TextEditingController();
  final congregation = TextEditingController();

  // State variables for dropdowns/checkboxes
  String gender = 'Male';
  String maritalStatus = 'Single';
  bool isBaptized = false;
  bool takesHolyCommunion = false;

  List<Map<String, dynamic>> allGroups = [];

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }
  
  Future<void> _initializeProfile() async {
    await fetchProfile();
    loadGroups();
    
    // Auto-open edit dialog if requested, after profile is loaded
    if (widget.autoOpenPage != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showEditDialog(initialPage: widget.autoOpenPage!);
        }
      });
    }
  }

  @override
  void dispose() {
    fullName.dispose();
    email.dispose();
    dob.dispose();
    nationalId.dispose();
    telephone.dispose();
    presbytery.dispose();
    parish.dispose();
    congregation.dispose();
    super.dispose();
  }

  // --- Data Handling Methods ---

  Future<void> loadGroups() async {
    try {
      final res = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/groups'),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['status'] == 200) {
          setState(() {
            allGroups = List<Map<String, dynamic>>.from(body['groups']);
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  String getGroupNames(String groupsJson) {
    if (groupsJson.isEmpty) return 'None';
    try {
      final groupIds = List<int>.from(jsonDecode(groupsJson));
      final groupNames = groupIds.map((id) {
        final group = allGroups.firstWhere(
          (g) => g['id'] == id,
          orElse: () => {'name': 'Unknown Group'},
        );
        return group['name'] as String;
      }).toList();
      return groupNames.join(', ');
    } catch (e) {
      return 'None';
    }
  }

  Future<void> fetchProfile() async {
    setState(() => loading = true);
    prefs = await SharedPreferences.getInstance();

    try {
      final res = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/members/me'),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if ((body['status'] ?? 200) == 200) {
          final m = body['member'] as Map<String, dynamic>;

          final fetchedProfile = MemberProfile(
            fullName: (m['full_name'] ?? '') as String,
            email: (m['email'] ?? prefs.getString('email') ?? '') as String,
            eKanisaNumber:
                (m['e_kanisa_number'] ??
                        prefs.getString('e_kanisa_number') ??
                        '')
                    as String,
            role: (m['role'] ?? 'member') as String,
            telephone: (m['telephone'] ?? '') as String,
            nationalId: (m['national_id'] ?? '') as String,
            dateOfBirth: (m['date_of_birth'] ?? '') as String,
            gender: (m['gender'] ?? 'Male') as String,
            maritalStatus: (m['marital_status'] ?? 'Single') as String,
            presbytery: (m['presbytery'] ?? '') as String,
            parish: (m['parish'] ?? '') as String,
            congregation: (m['congregation'] ?? '') as String,
            groups: (m['groups'] ?? '') as String,
            isBaptized: (m['is_baptized'] ?? false) == true,
            takesHolyCommunion: (m['takes_holy_communion'] ?? false) == true,
            imagePath: prefs.getString('profile_image_path') ?? '',
            imageUrl: (m['profile_image_url'] ?? '') as String,
            passportImageUrl: (m['passport_image_url'] ?? '') as String,
          );

          profile = fetchedProfile;

          await prefs.setString(
            'member_profile',
            jsonEncode(profile!.toJson()),
          );
          if (profile!.imageUrl.isNotEmpty) {
            await prefs.setString('profile_image_url', profile!.imageUrl);
          } else {
            await prefs.remove('profile_image_url');
          }
        }
      }
    } catch (_) {
      final raw = prefs.getString('member_profile');
      if (raw != null && raw.isNotEmpty) {
        profile = MemberProfile.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    }

    profile ??= MemberProfile(
      fullName: prefs.getString('name') ?? '',
      email: prefs.getString('email') ?? '',
      eKanisaNumber: prefs.getString('e_kanisa_number') ?? '',
      role: 'member',
      telephone: '',
      nationalId: '',
      dateOfBirth: '',
      gender: 'Male',
      maritalStatus: 'Single',
      presbytery: '',
      parish: '',
      congregation: '',
      groups: '',
      isBaptized: false,
      takesHolyCommunion: false,
      imagePath: prefs.getString('profile_image_path') ?? '',
      imageUrl: '',
      passportImageUrl: '',
    );

    _fillControllersFromProfile();
    setState(() => loading = false);
  }

  void _fillControllersFromProfile() {
    if (profile == null) return;
    fullName.text = profile!.fullName;
    email.text = profile!.email;
    dob.text = profile!.dateOfBirth;
    nationalId.text = profile!.nationalId;
    telephone.text = profile!.telephone;
    presbytery.text = profile!.presbytery;
    parish.text = profile!.parish;
    congregation.text = profile!.congregation;
    gender = profile!.gender;
    maritalStatus = profile!.maritalStatus;
    isBaptized = profile!.isBaptized;
    takesHolyCommunion = profile!.takesHolyCommunion;
  }

  Future<void> saveProfile() async {
    if (saving) return;
    setState(() => saving = true);

    profile = profile!.copyWith(
      fullName: fullName.text.trim(),
      email: email.text.trim(),
      telephone: telephone.text.trim(),
      nationalId: nationalId.text.trim(),
      dateOfBirth: dob.text.trim(),
      gender: gender,
      maritalStatus: maritalStatus,
      presbytery: presbytery.text.trim(),
      parish: parish.text.trim(),
      congregation: congregation.text.trim(),
      isBaptized: isBaptized,
      takesHolyCommunion: takesHolyCommunion,
      imagePath: selectedImage?.path ?? profile!.imagePath,
    );

    try {
      // If image is selected, upload it directly to database
      if (selectedImage != null && selectedImage!.existsSync()) {
        try {
          final resp = await API().uploadMultipart(
            url: Uri.parse('${Config.baseUrl}/members/me/avatar'),
            fields: {},
            fileField: 'image',
            filePath: selectedImage!.path,
          );
          final body = await resp.stream.bytesToString();
          final data = jsonDecode(body) as Map<String, dynamic>;

          if ((data['status'] ?? 400) == 200) {
            final url = (data['profile_image_url'] ?? '') as String;
            if (url.isNotEmpty) {
              profile = profile!.copyWith(
                imageUrl: url,
                imagePath: selectedImage!.path,
              );
              await prefs.setString('profile_image_url', url);
              await prefs.setString('profile_image_path', selectedImage!.path);
            } else {
              if (mounted) {
                API.showSnack(
                  context,
                  'Image uploaded but no URL returned.',
                  success: false,
                );
              }
            }
          } else {
            if (mounted) {
              API.showSnack(
                context,
                data['message']?.toString() ?? 'Image upload failed.',
                success: false,
              );
            }
          }
        } catch (e) {
          // Show the actual error
          if (mounted) {
            API.showSnack(
              context,
              'Image upload failed: ${e.toString()}',
              success: false,
            );
          }
          // Don't continue with profile update if image upload fails
          setState(() => saving = false);
          return;
        }
      } else if (selectedImage != null && !selectedImage!.existsSync()) {
        if (mounted) {
          API.showSnack(
            context,
            'Selected image file no longer exists.',
            success: false,
          );
        }
        setState(() {
          selectedImage = null;
        });
        setState(() => saving = false);
        return;
      }

      // Update profile data
      final res = await API().postRequest(
        url: Uri.parse('${Config.baseUrl}/members/me'),
        data: {
          'full_name': profile!.fullName,
          'date_of_birth': profile!.dateOfBirth,
          'national_id': profile!.nationalId,
          'gender': profile!.gender,
          'marital_status': profile!.maritalStatus,
          'is_baptized': profile!.isBaptized,
          'takes_holy_communion': profile!.takesHolyCommunion,
          'telephone': profile!.telephone,
          'presbytery': profile!.presbytery,
          'parish': profile!.parish,
          'congregation': profile!.congregation,
        },
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if ((body['status'] ?? 400) == 200) {
          if (mounted) {
            API.showSnack(
              context,
              selectedImage != null
                  ? 'Profile and image updated successfully!'
                  : 'Account update successful!',
              success: true,
            );
          }
          // Clear selected image after successful save
          if (selectedImage != null) {
            setState(() {
              selectedImage = null;
            });
          }
        } else {
          if (mounted)
            API.showSnack(
              context,
              body['message'] ?? 'Server update failed.',
              success: false,
            );
        }
      }
    } catch (e) {
      if (mounted)
        API.showSnack(
          context,
          'Network Error: Profile updated locally.',
          success: false,
        );
    }

    await prefs.setString('member_profile', jsonEncode(profile!.toJson()));
    await prefs.setString('name', fullName.text.trim());

    setState(() => saving = false);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      selectedImage = picked != null ? File(picked.path) : null;
    });
  }

  // --- Image Viewer Functionality ---

  void _viewImage(ImageProvider? provider) {
    if (provider == null) {
      API.showSnack(context, 'No profile image available.', success: false);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Profile Picture'),
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image(image: provider, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Building Widgets ---

  Widget _buildHeaderSection(ImageProvider? avatarProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (avatarProvider != null) {
                _viewImage(avatarProvider);
              } else {
                _showEditDialog(initialPage: 2);
              }
            },
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatarProvider,
              child: avatarProvider == null
                  ? Icon(
                      Icons.person,
                      size: 60,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            profile?.fullName ?? 'N/A',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1F44),
            ),
          ),
          Text(
            profile?.role.toUpperCase() ??
                'MEMBER at ${profile?.congregation ?? 'N/A'}',
            style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade700),
          ),
          Text(
            'Kanisa Number: ${profile?.eKanisaNumber ?? 'N/A'}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A1F44),
              ),
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? 'Not Provided' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return saving
        ? SizedBox(
            width: double.infinity,
            height: 70,
            child: Center(
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
            ),
          )
        : SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => _showEditDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1F44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Edit Profile Details',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarProvider;
    if (selectedImage != null && selectedImage!.path.isNotEmpty) {
      avatarProvider = FileImage(selectedImage!);
    } else if (profile != null && profile!.imageUrl.isNotEmpty) {
      avatarProvider = NetworkImage(profile!.imageUrl);
    } else if (profile != null && profile!.imagePath.isNotEmpty) {
      avatarProvider = FileImage(File(profile!.imagePath));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 241, 242, 243),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderSection(avatarProvider),

                  _buildSectionCard(
                    title: 'Contact Information',
                    children: [
                      _infoRow(
                        Icons.email_outlined,
                        'Email Address',
                        email.text,
                      ),
                      _infoRow(Icons.phone, 'Phone Number', telephone.text),
                    ],
                  ),

                  _buildSectionCard(
                    title: 'Personal Details',
                    children: [
                      _infoRow(
                        Icons.perm_identity,
                        'National ID',
                        nationalId.text,
                      ),
                      _infoRow(Icons.calendar_today, 'Date of Birth', dob.text),
                      _infoRow(Icons.person_outline, 'Gender', gender),
                      _infoRow(
                        Icons.favorite_border,
                        'Marital Status',
                        maritalStatus,
                      ),
                    ],
                  ),

                  _buildSectionCard(
                    title: 'Church Affiliation',
                    children: [
                      _infoRow(
                        Icons.location_city,
                        'Presbytery',
                        presbytery.text,
                      ),
                      _infoRow(Icons.apartment, 'Parish', parish.text),
                      _infoRow(
                        Icons.church_outlined,
                        'Congregation',
                        congregation.text,
                      ),
                      _infoRow(
                        Icons.groups,
                        'Groups Joined',
                        getGroupNames(profile?.groups ?? ''),
                      ),
                    ],
                  ),

                  _buildSectionCard(
                    title: 'Sacramental Status',
                    children: [
                      _infoRow(
                        Icons.water_drop_outlined,
                        'Baptized',
                        isBaptized ? 'Yes' : 'No',
                      ),
                      _infoRow(
                        Icons.wine_bar_outlined,
                        'Holy Communion',
                        takesHolyCommunion ? 'Yes' : 'No',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildUpdateButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: label.contains('Phone')
            ? TextInputType.phone
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  // --- Fixed Edit Dialog Implementation ---

  void _showEditDialog({int initialPage = 0}) {
    final fullNameCtl = TextEditingController(text: fullName.text);
    final emailCtl = TextEditingController(text: email.text);
    final phoneCtl = TextEditingController(text: telephone.text);
    final nationalIdCtl = TextEditingController(text: nationalId.text);
    final dobCtl = TextEditingController(text: dob.text);
    final presbyteryCtl = TextEditingController(text: presbytery.text);
    final parishCtl = TextEditingController(text: parish.text);
    final congregationCtl = TextEditingController(text: congregation.text);

    final PageController pageController = PageController(
      initialPage: initialPage,
    );

    showDialog(
      context: context,
      builder: (context) {
        String dialogGender = gender;
        String dialogMaritalStatus = maritalStatus;
        bool dialogIsBaptized = isBaptized;
        bool dialogTakesHolyCommunion = takesHolyCommunion;

        // FIX: Track the current page index safely
        int currentPageIndex = initialPage;

        return StatefulBuilder(
          builder: (context, setStateSB) {
            // Use selectedImage directly from main state
            // This ensures we always have the latest value

            Future<void> _selectDate(BuildContext context) async {
              DateTime initialDate = DateTime.now();
              try {
                if (dobCtl.text.isNotEmpty) {
                  initialDate = DateFormat('yyyy-MM-dd').parse(dobCtl.text);
                }
              } catch (_) {}

              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setStateSB(() {
                  dobCtl.text = DateFormat('yyyy-MM-dd').format(picked);
                });
              }
            }

            void _handleSave() async {
              // Update main state with dialog values
              fullName.text = fullNameCtl.text;
              telephone.text = phoneCtl.text;
              dob.text = dobCtl.text;
              presbytery.text = presbyteryCtl.text;
              parish.text = parishCtl.text;
              congregation.text = congregationCtl.text;
              gender = dialogGender;
              maritalStatus = dialogMaritalStatus;
              isBaptized = dialogIsBaptized;
              takesHolyCommunion = dialogTakesHolyCommunion;

              Navigator.of(context).pop();
              await saveProfile();
              this.setState(() {});
            }

            return AlertDialog(
              title: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Text(
                  'Update Profile Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1F44),
                  ),
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      if (!saving)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1.5,
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      if (saving) const SizedBox(width: 0),
                      if (!saving) const SizedBox(width: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: saving
                            ? SizedBox(
                                height: 56,
                                child: Center(
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
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0A1F44).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _handleSave,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0A1F44),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.save, size: 20),
                                  label: const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) {
                          // Crucial fix: Update the index safely
                          setStateSB(() {
                            currentPageIndex = index;
                          });
                        },
                        children: [
                          // Page 1: Personal & Contact Info
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildTextField(fullNameCtl, 'Full Name'),
                                _buildTextField(
                                  emailCtl,
                                  'Email Address',
                                  readOnly: true,
                                ),
                                _buildTextField(phoneCtl, 'Phone Number'),
                                _buildTextField(
                                  nationalIdCtl,
                                  'National ID',
                                  readOnly: true,
                                ),

                                _buildTextField(
                                  dobCtl,
                                  'Date of Birth (YYYY-MM-DD)',
                                  readOnly: true,
                                  onTap: () => _selectDate(context),
                                ),

                                DropdownButtonFormField<String>(
                                  value: dialogGender,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Male',
                                      child: Text('Male'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Female',
                                      child: Text('Female'),
                                    ),
                                  ],
                                  onChanged: (v) => setStateSB(
                                    () => dialogGender = v ?? 'Male',
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Gender',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  value: dialogMaritalStatus,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Single',
                                      child: Text('Single'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Married (Customary)',
                                      child: Text('Married (Customary)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Married (Church Wedding)',
                                      child: Text('Married (Church Wedding)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Divorced',
                                      child: Text('Divorced'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Widow',
                                      child: Text('Widow'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Widower',
                                      child: Text('Widower'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Separated',
                                      child: Text('Separated'),
                                    ),
                                  ],
                                  onChanged: (v) => setStateSB(
                                    () => dialogMaritalStatus = v ?? 'Single',
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Marital Status',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Page 2: Church Info & Sacraments
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildTextField(presbyteryCtl, 'Presbytery'),
                                _buildTextField(parishCtl, 'Parish'),
                                _buildTextField(
                                  congregationCtl,
                                  'Congregation',
                                ),
                                const SizedBox(height: 10),

                                _buildSwitchTile(
                                  title: 'Is Baptized',
                                  value: dialogIsBaptized,
                                  onChanged: (v) =>
                                      setStateSB(() => dialogIsBaptized = v),
                                ),
                                _buildSwitchTile(
                                  title: 'Takes Holy Communion',
                                  value: dialogTakesHolyCommunion,
                                  onChanged: (v) => setStateSB(
                                    () => dialogTakesHolyCommunion = v,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Page 3: Image Upload
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Update Profile Picture',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF0A1F44),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Divider(),
                                const SizedBox(height: 20),

                                // Current Profile Image Preview
                                if (profile != null &&
                                    profile!.imageUrl.isNotEmpty)
                                  Column(
                                    children: [
                                      const Text(
                                        'Current Profile Picture',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: Image.network(
                                            profile!.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.person,
                                                    size: 60,
                                                    color: Colors.grey,
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),

                                // Selected Image Preview
                                if (selectedImage != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Image Selected',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          width: 150,
                                          height: 150,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.green.shade300,
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: Image.file(
                                              selectedImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          selectedImage!.path
                                              .split(Platform.pathSeparator)
                                              .last,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              selectedImage = null;
                                            });
                                            setStateSB(() {});
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                          ),
                                          label: const Text('Remove'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ] else ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.image_outlined,
                                          size: 64,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No image selected',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // Select Image Button
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await _pickImage();
                                    setStateSB(() {});
                                  },
                                  icon: const Icon(
                                    Icons.photo_library,
                                    size: 20,
                                  ),
                                  label: Text(
                                    selectedImage != null
                                        ? 'Change Image'
                                        : 'Select Profile Image',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0A1F44),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Info text
                                if (selectedImage != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 20,
                                          color: Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Image will be saved when you click "Save Changes"',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Navigation Buttons (Fixed to use currentPageIndex)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: currentPageIndex == 0
                              ? null
                              : () => pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                          child: const Text('Previous'),
                        ),
                        TextButton(
                          onPressed:
                              currentPageIndex ==
                                  2 // Total pages = 3 (0, 1, 2)
                              ? null
                              : () => pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
