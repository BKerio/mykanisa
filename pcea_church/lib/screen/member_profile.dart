import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/config/server.dart';

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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = false;
  bool saving = false;
  late SharedPreferences prefs;
  MemberProfile? profile;
  File? selectedImage;

  final fullName = TextEditingController();
  final email = TextEditingController();
  final dob = TextEditingController();
  final nationalId = TextEditingController();
  final telephone = TextEditingController();
  final presbytery = TextEditingController();
  final parish = TextEditingController();
  final congregation = TextEditingController();
  String gender = 'Male';
  String maritalStatus = 'Single';
  bool isBaptized = false;
  bool takesHolyCommunion = false;
  List<Map<String, dynamic>> allGroups = [];

  @override
  void initState() {
    super.initState();
    fetchProfile();
    loadGroups();
  }

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
          profile = MemberProfile(
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
          await prefs.setString(
            'member_profile',
            jsonEncode(profile!.toJson()),
          );
        }
      }
    } catch (_) {
      // fallback to local
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
    try {
      profile = MemberProfile(
        fullName: fullName.text.trim(),
        email: email.text.trim(),
        eKanisaNumber:
            profile?.eKanisaNumber ??
            (prefs.getString('e_kanisa_number') ?? ''),
        role: profile?.role ?? 'member',
        telephone: telephone.text.trim(),
        nationalId: nationalId.text.trim(),
        dateOfBirth: dob.text.trim(),
        gender: gender,
        groups: profile?.groups ?? '',
        maritalStatus: maritalStatus,
        presbytery: presbytery.text.trim(),
        parish: parish.text.trim(),
        congregation: congregation.text.trim(),
        isBaptized: isBaptized,
        takesHolyCommunion: takesHolyCommunion,
        imagePath: selectedImage?.path ?? (profile?.imagePath ?? ''),
        imageUrl: profile?.imageUrl ?? '',
        passportImageUrl: profile?.passportImageUrl ?? '',
      );
      // Save to backend
      try {
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
          if ((body['status'] ?? 200) == 200) {
            // sync local cache
            await prefs.setString(
              'member_profile',
              jsonEncode(profile!.toJson()),
            );
          }
        }
      } catch (_) {
        // even if backend fails, keep local
        await prefs.setString('member_profile', jsonEncode(profile!.toJson()));
      }
      await prefs.setString('name', fullName.text.trim());
      if (profile!.imagePath.isNotEmpty) {
        await prefs.setString('profile_image_path', profile!.imagePath);
      }
      if (!mounted) return;
      API.showSnack(context, 'Account update successful!', success: true);
    } catch (_) {}
    setState(() => saving = false);
  }

  void _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      selectedImage = picked != null ? File(picked.path) : null;
    });
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
          'Manage Profile',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundImage: avatarProvider,
                      child: avatarProvider == null
                          ? const Icon(Icons.person, size: 80)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    if (profile != null && profile!.passportImageUrl.isNotEmpty)
                      Column(
                        children: [
                          const Text('Passport Photo'),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image(
                              image: NetworkImage(profile!.passportImageUrl),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),

                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        children: const [
                          Expanded(
                            child: Divider(
                              color: Color(0xFF35C2C1),
                              thickness: 3,
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Color(0xFF35C2C1),
                              thickness: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _infoCard(
                      Icons.badge_outlined,
                      'e-Kanisa Number',
                      profile?.eKanisaNumber ?? '',
                    ),
                    _infoCard(
                      Icons.workspace_premium_outlined,
                      'My Role',
                      (profile?.role ?? 'member'),
                    ),
                    _infoCard(Icons.person, 'Full Name', fullName.text),
                    const SizedBox(height: 10),
                    _infoCard(Icons.email_outlined, 'Email', email.text),
                    const SizedBox(height: 10),
                    _infoCard(Icons.phone, 'Phone', telephone.text),
                    const SizedBox(height: 10),
                    _infoCard(
                      Icons.badge_outlined,
                      'National ID',
                      nationalId.text,
                    ),
                    const SizedBox(height: 10),
                    _infoCard(Icons.cake_outlined, 'DOB', dob.text),
                    const SizedBox(height: 10),
                    _infoCard(
                      Icons.church_outlined,
                      'Presbytery',
                      presbytery.text,
                    ),
                    const SizedBox(height: 10),
                    _infoCard(Icons.church_outlined, 'Parish', parish.text),
                    const SizedBox(height: 10),
                    _infoCard(
                      Icons.church_outlined,
                      'Congregation',
                      congregation.text,
                    ),
                    const SizedBox(height: 10),
                    _infoCard(
                      Icons.group_outlined,
                      'Groups',
                      getGroupNames(profile?.groups ?? ''),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showEditDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF35C2C1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Update Profile',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value.isEmpty ? '-' : value),
      ),
    );
  }

  void _showEditDialog() {
    final fullNameCtl = TextEditingController(text: fullName.text);
    final emailCtl = TextEditingController(text: email.text);
    final phoneCtl = TextEditingController(text: telephone.text);
    final nationalIdCtl = TextEditingController(text: nationalId.text);
    final dobCtl = TextEditingController(text: dob.text);
    final presbyteryCtl = TextEditingController(text: presbytery.text);
    final parishCtl = TextEditingController(text: parish.text);
    final congregationCtl = TextEditingController(text: congregation.text);
    String genderVal = gender;
    String maritalVal = maritalStatus;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Profile'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: fullNameCtl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nationalIdCtl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'National ID Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dobCtl,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: genderVal,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                onChanged: (v) => genderVal = v ?? 'Male',
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: maritalVal,
                items: const [
                  DropdownMenuItem(value: 'Single', child: Text('Single')),
                  DropdownMenuItem(
                    value: 'Married (Customary)',
                    child: Text('Married (Customary)'),
                  ),
                  DropdownMenuItem(
                    value: 'Married (Church Wedding)',
                    child: Text('Married (Church Wedding)'),
                  ),
                DropdownMenuItem(value: 'Divorced', child: Text('Divorced')),
                DropdownMenuItem(value: 'Widow', child: Text('Widow')),
                DropdownMenuItem(value: 'Widower', child: Text('Widower')),
                DropdownMenuItem(value: 'Separated', child: Text('Separated')),
                ],
                onChanged: (v) => maritalVal = v ?? 'Single',
                decoration: const InputDecoration(
                  labelText: 'Marital Status',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: presbyteryCtl,
                decoration: const InputDecoration(
                  labelText: 'Presbytery',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: parishCtl,
                decoration: const InputDecoration(
                  labelText: 'Parish',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: congregationCtl,
                decoration: const InputDecoration(
                  labelText: 'Congregation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Select Profile/Passport Image'),
              ),
              const SizedBox(height: 6),
              selectedImage != null
                  ? Text(selectedImage!.path.split(Platform.pathSeparator).last)
                  : const Text('No image selected'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: selectedImage == null
                    ? null
                    : () async {
                        try {
                          final resp = await API().uploadMultipart(
                            url: Uri.parse(
                              '${Config.baseUrl}/members/me/avatar',
                            ),
                            fields: {},
                            fileField: 'image',
                            filePath: selectedImage!.path,
                          );
                          final body = await resp.stream.bytesToString();
                          final data = jsonDecode(body) as Map<String, dynamic>;
                          if ((data['status'] ?? 400) == 200) {
                            await prefs.setString(
                              'profile_image_path',
                              selectedImage!.path,
                            );
                            final url =
                                (data['profile_image_url'] ?? '') as String;
                            if (url.isNotEmpty) {
                              profile =
                                  profile?.copyWith(imageUrl: url) ?? profile;
                              await prefs.setString(
                                'member_profile',
                                jsonEncode(profile!.toJson()),
                              );
                              if (mounted) setState(() {});
                            }
                            if (!mounted) return;
                            API.showSnack(
                              context,
                              'Profile image updated',
                              success: true,
                            );
                          } else {
                            if (!mounted) return;
                            API.showSnack(
                              context,
                              data['message']?.toString() ?? 'Upload failed',
                              success: false,
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          API.showSnack(
                            context,
                            'Upload failed',
                            success: false,
                          );
                        }
                      },
                child: const Text('Upload Image'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: selectedImage == null
                    ? null
                    : () async {
                        try {
                          final resp = await API().uploadMultipart(
                            url: Uri.parse(
                              '${Config.baseUrl}/members/me/passport',
                            ),
                            fields: {},
                            fileField: 'image',
                            filePath: selectedImage!.path,
                          );
                          final body = await resp.stream.bytesToString();
                          final data = jsonDecode(body) as Map<String, dynamic>;
                          if ((data['status'] ?? 400) == 200) {
                            final url =
                                (data['passport_image_url'] ?? '') as String;
                            if (url.isNotEmpty) {
                              profile =
                                  profile?.copyWith(passportImageUrl: url) ??
                                  profile;
                              await prefs.setString(
                                'member_profile',
                                jsonEncode(profile!.toJson()),
                              );
                              if (mounted) setState(() {});
                            }
                            if (!mounted) return;
                            API.showSnack(
                              context,
                              'Passport photo uploaded',
                              success: true,
                            );
                          } else {
                            if (!mounted) return;
                            API.showSnack(
                              context,
                              data['message']?.toString() ?? 'Upload failed',
                              success: false,
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          API.showSnack(
                            context,
                            'Upload failed',
                            success: false,
                          );
                        }
                      },
                child: const Text('Upload Passport Photo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              fullName.text = fullNameCtl.text;
              telephone.text = phoneCtl.text;
              nationalId.text = nationalIdCtl.text;
              dob.text = dobCtl.text;
              presbytery.text = presbyteryCtl.text;
              parish.text = parishCtl.text;
              congregation.text = congregationCtl.text;
              gender = genderVal;
              maritalStatus = maritalVal;
              await saveProfile();
              if (!mounted) return;
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text('Update Profile'),
          ),
        ],
      ),
    );
  }
}
