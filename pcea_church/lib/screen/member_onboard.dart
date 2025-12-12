import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:pcea_church/components/responsive_layout.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/screen/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final primaryColor = const Color(0xFF0A1F44);
  final darkBlue = const Color(0xFF0A1F44);

  // Step management
  int currentStep = 0;
  final PageController _pageController = PageController();
  final int totalSteps = 4;

  // Controllers
  final fullName = TextEditingController();
  final dob = TextEditingController();
  final nationalId = TextEditingController();
  final email = TextEditingController();
  final telephone = TextEditingController();
  final district = TextEditingController();
  final congregation = TextEditingController();
  final regionController = TextEditingController();
  final presbyteryController = TextEditingController();
  final password = TextEditingController();
  final passwordConfirm = TextEditingController();

  // State variables
  int? age;
  String gender = 'Male';
  String maritalStatus = 'Single';
  bool isBaptized = false;
  bool takesHolyCommunion = false;
  bool hasDependents = false;
  bool isLoading = false;
  bool _obscurePassword = true;

  // Location data
  String selectedRegionId = '';
  String selectedRegionName = '';
  String selectedPresbyteryId = '';
  String selectedPresbyteryName = '';
  String selectedParishId = '';
  String selectedParishName = '';

  List<Map<String, dynamic>> regions = [];
  List<Map<String, dynamic>> parishes = [];
  List<Map<String, dynamic>> groups = [];
  final Set<int> selectedGroupIds = {};
  bool isLoadingRegions = true;
  bool isLoadingParishes = false;

  // Dependents
  final List<Map<String, dynamic>> dependents = [];
  static const int _minYear = 1900;
  int get _currentYear => DateTime.now().year;

  // Profile image
  XFile? profileImage;
  final ImagePicker _imagePicker = ImagePicker();

  // Section save states (Kept for compatibility with original validation logic if needed elsewhere, but unused in UI)
  Map<String, bool> sectionSaved = {
    'personal': false,
    'church': false,
    'dependents': false,
    'security': false,
  };

  @override
  void initState() {
    super.initState();
    _initLocationData();
    loadGroups();
  }

  Future<void> _initLocationData() async {
    await loadRegions();
    if (!mounted) return;
    await loadAllParishes();
  }

  @override
  void dispose() {
    regionController.dispose();
    presbyteryController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> loadRegions() async {
    if (!mounted) return;
    setState(() {
      isLoadingRegions = true;
    });
    try {
      final res = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/regions'),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['status'] == 200) {
          setState(() {
            regions = List<Map<String, dynamic>>.from(body['regions']);
            isLoadingRegions = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingRegions = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load regions. Please check your connection.',
            ),
          ),
        );
      }
    }
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
            groups = List<Map<String, dynamic>>.from(body['groups']);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> loadAllParishes() async {
    if (!mounted) return;
    regionController.clear();
    presbyteryController.clear();
    setState(() {
      isLoadingParishes = true;
      parishes = [];
    });

    final List<Map<String, dynamic>> aggregatedParishes = [];
    final regionsSnapshot = List<Map<String, dynamic>>.from(regions);

    for (final region in regionsSnapshot) {
      final regionId = region['id']?.toString() ?? '';
      if (regionId.isEmpty) continue;
      try {
        final presbyteriesResponse = await API().getRequest(
          url: Uri.parse('${Config.baseUrl}/presbyteries?region_id=$regionId'),
        );

        if (presbyteriesResponse.statusCode != 200) continue;
        final presbyteriesBody = jsonDecode(presbyteriesResponse.body);
        final presbyteriesData = presbyteriesBody['presbyteries'];
        if (presbyteriesBody['status'] != 200 || presbyteriesData == null) {
          continue;
        }

        final presbyteriesList = List<Map<String, dynamic>>.from(
          presbyteriesData,
        );

        for (final presbytery in presbyteriesList) {
          final presbyteryId = presbytery['id']?.toString() ?? '';
          if (presbyteryId.isEmpty) continue;

          try {
            final parishesResponse = await API().getRequest(
              url: Uri.parse(
                '${Config.baseUrl}/parishes?presbytery_id=$presbyteryId',
              ),
            );

            if (parishesResponse.statusCode != 200) continue;
            final parishesBody = jsonDecode(parishesResponse.body);
            final parishesData = parishesBody['parishes'];
            if (parishesBody['status'] != 200 || parishesData == null) {
              continue;
            }

            final parishList = List<Map<String, dynamic>>.from(parishesData);
            for (final parish in parishList) {
              final enriched = Map<String, dynamic>.from(parish);
              enriched['region_id'] = regionId;
              enriched['region_name'] = region['name']?.toString() ?? '';
              enriched['presbytery_id'] = presbyteryId;
              enriched['presbytery_name'] =
                  presbytery['name']?.toString() ?? '';
              aggregatedParishes.add(enriched);
            }
          } catch (e) {
            print('Error loading parishes for presbytery $presbyteryId: $e');
          }
        }
      } catch (e) {
        print('Error loading presbyteries for region $regionId: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      parishes = aggregatedParishes;
      isLoadingParishes = false;
    });
  }

  void addDependent() {
    if (dependents.length >= 10) {
      _toast('Maximum 10 dependents allowed');
      return;
    }
    setState(() {
      dependents.add({
        'name': TextEditingController(),
        'year_of_birth': TextEditingController(text: _currentYear.toString()),
        'birth_cert': TextEditingController(),
        'is_baptized': false,
        'takes_holy_communion': false,
        'school': TextEditingController(),
        'photos': <XFile>[],
      });
    });
  }

  void removeDependent(int index) {
    setState(() {
      dependents.removeAt(index);
      if (dependents.isEmpty) {
        hasDependents = false;
      }
    });
  }

  Future<void> _pickDependentPhotos(int index, ImageSource source) async {
    try {
      final List<XFile> currentPhotos =
          dependents[index]['photos'] as List<XFile>;
      if (currentPhotos.length >= 3) {
        _toast("Maximum 3 photos allowed per dependent");
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          currentPhotos.add(image);
        });
      }
    } catch (e) {
      _toast('Error picking image: $e');
    }
  }

  void _removeDependentPhoto(int depIndex, int photoIndex) {
    setState(() {
      (dependents[depIndex]['photos'] as List<XFile>).removeAt(photoIndex);
    });
  }

  void _showDependentPhotoOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickDependentPhotos(index, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickDependentPhotos(index, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void pickDependentDob(int index) async {
    if (index < 0 || index >= dependents.length) return;
    final now = DateTime.now();
    final first = DateTime(now.year - 100, 1, 1);
    final last = now;
    final controller =
        dependents[index]['year_of_birth'] as TextEditingController;
    final initial = () {
      final existing = DateTime.tryParse(controller.text.trim());
      if (existing != null) return existing;
      return DateTime(now.year - 5, now.month, now.day);
    }();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      final dobStr =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => controller.text = dobStr);
    }
  }

  void pickDob() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 100, 1, 1);
    final last = now;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      dob.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      final calculatedAge = _calculateAge(picked);
      setState(() => age = calculatedAge);
    }
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int years = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      years--;
    }
    return years;
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          profileImage = pickedFile;
        });
      }
    } catch (e) {
      _toast('Failed to pick image: $e');
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  bool validateCurrentStep() {
    // This validation is now used for the final submission check, ensuring critical fields are present.
    switch (currentStep) {
      case 0: // Personal Info: Must have Full Name, Email, DOB, Telephone
        return fullName.text.isNotEmpty &&
            email.text.isNotEmpty &&
            dob.text.isNotEmpty &&
            telephone.text.isNotEmpty;
      case 1: // Church Details: Must select location hierarchy and enter congregation/district
        return selectedRegionId.isNotEmpty &&
            selectedPresbyteryId.isNotEmpty &&
            selectedParishId.isNotEmpty &&
            congregation.text.isNotEmpty &&
            district.text.isNotEmpty;
      case 2: // Dependents (optional)
        return true;
      case 3: // Security: Must have matching passwords of minimum length
        return password.text.isNotEmpty &&
            passwordConfirm.text.isNotEmpty &&
            password.text == passwordConfirm.text &&
            password.text.length >= 6;
      default:
        return false;
    }
  }

  void nextStep() {
    if (currentStep < totalSteps - 1) {
      // Allow navigation regardless of field completion status
      setState(() {
        currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> submit() async {
    if (isLoading) return;

    // 1. Run form validation (for field-level checks like password matching)
    if (!_formKey.currentState!.validate()) {
      _toast('Please check the highlighted required fields on this page.');
      // If validation fails on the current page, don't proceed.
      return;
    }

    // 2. Run sequential step validation (for mandatory fields across all steps)
    for (int i = 0; i < totalSteps; i++) {
      // Temporarily switch to the page to validate
      _pageController.jumpToPage(i);
      setState(() {
        currentStep = i; // Ensure state updates for visual indicators
      });
      await Future.delayed(Duration(milliseconds: 50)); // Allow UI to settle

      if (!validateCurrentStep()) {
        _toast('Please complete all mandatory fields in Step ${i + 1}');
        // Re-animate to the faulty step for user correction
        _pageController.animateToPage(
          i,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return;
      }
    }

    // Revert to the final step indicator
    setState(() {
      currentStep = totalSteps - 1;
    });

    // 3. Conditional national ID requirement check
    final parsedDob = DateTime.tryParse(dob.text);
    final computedAge = parsedDob != null ? _calculateAge(parsedDob) : null;
    if ((computedAge ?? 0) >= 18 && (nationalId.text.trim().isEmpty)) {
      _toast('National Id is required for members 18 years and above');
      return;
    }

    // 4. Process Dependents
    final deps = hasDependents
        ? dependents
              .map((d) {
                final name = (d['name'] as TextEditingController).text.trim();
                final raw = (d['year_of_birth'] as TextEditingController).text
                    .trim();
                int? y;
                final asDate = DateTime.tryParse(raw);
                if (asDate != null) {
                  y = asDate.year;
                } else {
                  y = int.tryParse(raw);
                }
                final birthCert = (d['birth_cert'] as TextEditingController?)
                    ?.text
                    .trim();
                return {
                  'name': name,
                  'year_of_birth': y ?? 0,
                  'birth_cert_number':
                      (birthCert != null && birthCert.isNotEmpty)
                      ? birthCert
                      : null,
                  'is_baptized': d['is_baptized'] as bool,
                  'takes_holy_communion': d['takes_holy_communion'] as bool,
                  'school': (d['school'] as TextEditingController).text.trim(),
                };
              })
              .where(
                (e) =>
                    e['name'] != '' &&
                    (e['year_of_birth'] as int) >= _minYear &&
                    (e['year_of_birth'] as int) <= _currentYear,
              )
              .toList()
        : <Map<String, dynamic>>[];

    // 5. API Submission
    try {
      setState(() => isLoading = true);

      // Prepare fields
      final fields = {
        'full_name': fullName.text.trim(),
        'date_of_birth': dob.text.trim(),
        'national_id': nationalId.text.trim(),
        'email': email.text.trim(),
        'gender': gender,
        'marital_status': maritalStatus,
        'is_baptized': isBaptized ? '1' : '0',
        'takes_holy_communion': takesHolyCommunion ? '1' : '0',
        'telephone': telephone.text.trim(),
        'region': selectedRegionName,
        'presbytery': selectedPresbyteryName,
        'parish': selectedParishName,
        'district': district.text.trim(),
        'congregation': congregation.text.trim(),
        'dependencies': jsonEncode(deps),
        'group_ids': jsonEncode(selectedGroupIds.toList()),
        'password': password.text,
        'password_confirmation': passwordConfirm.text,
      };

      // Prepare Files
      List<http.MultipartFile> files = [];

      // Profile Image
      if (profileImage != null) {
        files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            profileImage!.path,
          ),
        );
      }

      // Dependent Photos
      if (hasDependents) {
        for (int i = 0; i < dependents.length; i++) {
          final depPhotos = dependents[i]['photos'] as List<XFile>;
          for (var photo in depPhotos) {
            files.add(
              await http.MultipartFile.fromPath(
                'dependent_photos_$i[]',
                photo.path,
              ),
            );
          }
        }
      }

      // Use uploadMultipartWithFiles for everything (it handles no files too if strictly implemented,
      // but let's check API. if no files, we can use postRequest, but using multipart is safer for consistency if backend expects it)
      // Actually my backend handles JSON input specifically if content-type is json.
      // If I use multipart without files, it's still multipart/form-data.
      // Backend `register` checks `$request->input('dependencies')`.
      // Multipart sends fields as strings.
      // My backend logic `if (is_string($dependenciesInput))` handles the JSON string from multipart.
      // So using multipart always is fine and simpler.

      http.StreamedResponse streamedResponse = await API()
          .uploadMultipartWithFiles(
            url: Uri.parse('${Config.baseUrl}/members/register'),
            fields: fields,
            files: files,
            requireAuth: false,
          );

      final res = await http.Response.fromStream(streamedResponse);
      final resp = jsonDecode(res.body);

      if (resp['status'] == 200) {
        // Save e-kanisa number and profile image to SharedPreferences
        if (resp['member'] != null) {
          SharedPreferences preferences = await SharedPreferences.getInstance();
          if (resp['member']['e_kanisa_number'] != null) {
            await preferences.setString(
              'e_kanisa_number',
              resp['member']['e_kanisa_number'],
            );
          }
          // Save profile image URL if available
          if (resp['member']['profile_image_url'] != null) {
            await preferences.setString(
              'profile_image_url',
              resp['member']['profile_image_url'],
            );
          }
        }
        API.showSnack(
          context,
          'Member Registered Successfully! Welcome to Our Church Community.',
          success: true,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
      } else {
        API.showSnack(
          context,
          resp['message']?.toString() ?? 'Registration failed',
          success: false,
        );
      }
    } catch (e) {
      API.showSnack(context, 'Something went wrong: $e', success: false);
    }
    setState(() => isLoading = false);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Helper method to create input fields with login styling
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        // Switched to TextFormField for inherent validation handling on submit
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onTap: onTap,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey, size: 20),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index <= currentStep ? primaryColor : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  Widget _buildStepHeader({
    required String title,
    required String subtitle,
    bool showLogo = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLogo) ...[
          // Circular logo with shadow
          Center(
            child: Container(
              width: 160,
              height: 160,
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
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "Member Registration",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
          ),
          const SizedBox(height: 24), // Extra space after header
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: "Personal Information",
          subtitle: "Tell us about yourself",
          showLogo: true, // Show logo only on the first step
        ),

        // Profile Image Upload
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                    border: Border.all(color: primaryColor, width: 2),
                  ),
                  child: profileImage != null
                      ? ClipOval(
                          child: Image.file(
                            File(profileImage!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: primaryColor,
                              size: 30,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                profileImage != null
                    ? 'Tap to change photo'
                    : 'Upload your profile photo (Optional)',
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildInputField(
          controller: fullName,
          hintText: "Enter full member name *",
          icon: Icons.person,
          validator: (value) => (value == null || value.isEmpty)
              ? 'Full name is mandatory'
              : null,
        ),
        const SizedBox(height: 16),

        _buildInputField(
          controller: dob,
          hintText: dob.text.isEmpty ? 'Date of Birth *' : dob.text,
          icon: Icons.calendar_month_outlined,
          onTap: pickDob,
          suffixIcon: age != null
              ? Text('Age: $age', style: const TextStyle(color: Colors.grey))
              : null,
          validator: (value) => (value == null || value.isEmpty)
              ? 'Date of Birth is mandatory'
              : null,
        ),
        const SizedBox(height: 16),

        _buildInputField(
          controller: nationalId,
          hintText: "National ID Number (Required for 18+)",
          icon: Icons.card_membership_rounded,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),

        _buildInputField(
          controller: email,
          hintText: "Enter your email address *",
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Email is mandatory' : null,
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _openGenderPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(_genderIcon(gender), color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gender',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              gender,
                              style: const TextStyle(fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _openMaritalStatusPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_outline, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Marital Status',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  _maritalIcon(maritalStatus),
                                  size: 18,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    maritalStatus.isEmpty
                                        ? 'Select status'
                                        : maritalStatus,
                                    style: const TextStyle(fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.search, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                value: isBaptized,
                onChanged: (v) => setState(() => isBaptized = v ?? false),
                title: const Text('Baptized', style: TextStyle(fontSize: 14)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                value: takesHolyCommunion,
                onChanged: (v) =>
                    setState(() => takesHolyCommunion = v ?? false),
                title: const Text(
                  'Holy Communion',
                  style: TextStyle(fontSize: 14),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildInputField(
          controller: telephone,
          hintText: "Enter phone number (0712345678) *",
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
          validator: (value) => (value == null || value.isEmpty)
              ? 'Phone number is mandatory'
              : null,
        ),
        const SizedBox(height: 16),

        // Groups Selection (moved from Church Details)
        if (groups.isNotEmpty)
          InkWell(
            onTap: _openGroupsDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.group,
                    color: selectedGroupIds.isEmpty
                        ? Colors.black
                        : Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Select church groups (optional)",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            if (selectedGroupIds.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${selectedGroupIds.length} selected',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (selectedGroupIds.isEmpty)
                          const Text(
                            'None selected',
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          )
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: groups
                                .where(
                                  (g) => selectedGroupIds.contains(
                                    (g['id'] as num).toInt(),
                                  ),
                                )
                                .map(
                                  (g) => Chip(
                                    label: Text(
                                      g['name']?.toString() ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.08),
                                    shape: StadiumBorder(
                                      side: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.35),
                                      ),
                                    ),
                                    labelStyle: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChurchDetailsStep() {
    // Helper function to determine the color for location fields (no red when empty)
    Color locationTextColor(String value) {
      return value.isEmpty ? Colors.black54 : Colors.black;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: "Church Location",
          subtitle: "Select your church details",
        ),

        // Parish (Searchable Picker)
        GestureDetector(
          onTap: (isLoadingParishes || parishes.isEmpty)
              ? null
              : _openParishPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.church_outlined, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoadingParishes
                            ? 'Loading parishes...'
                            : parishes.isEmpty
                            ? 'No parishes available'
                            : 'Parish *',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedParishName.isEmpty
                            ? (isLoadingParishes
                                  ? 'Please wait'
                                  : parishes.isEmpty
                                  ? 'No parishes found'
                                  : 'Select Parish (searchable)')
                            : selectedParishName,
                        style: TextStyle(
                          fontSize: 16,
                          color: locationTextColor(selectedParishName),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isLoadingParishes)
                  SpinKitFadingCircle(
                    size: 25,
                    duration: const Duration(milliseconds: 1800),
                    itemBuilder: (context, index) {
                      final palette = [
                        const Color(0xFF0A1F44),
                        Colors.red,
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
                  )
                else
                  const Icon(Icons.search, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildInputField(
          controller: congregation,
          hintText: "Congregation (Church) Name *",
          icon: Icons.church,
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 16),

        _buildInputField(
          controller: district,
          hintText: "District *",
          icon: Icons.location_on,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'District is required' : null,
        ),
      ],
    );
  }

  Widget _buildDependentCard(int i, Map<String, dynamic> d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (d['name'] as TextEditingController).text.isEmpty
                        ? 'Dependent ${i + 1}'
                        : (d['name'] as TextEditingController).text,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: darkBlue,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove Dependent',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => removeDependent(i),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: d['name'],
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => pickDependentDob(i),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (d['year_of_birth'] as TextEditingController)
                                  .text
                                  .isEmpty
                              ? 'Select Date of Birth'
                              : (d['year_of_birth'] as TextEditingController)
                                    .text,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: (d['birth_cert'] as TextEditingController),
                keyboardType: TextInputType.number,
                maxLength: 9,
                decoration: const InputDecoration(
                  labelText: 'Birth Certificate No (9 digits)',
                  border: OutlineInputBorder(),
                  counterText: '',
                  isDense: true,
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null; // optional
                  if (t.length != 9 || int.tryParse(t) == null) {
                    return 'Enter exactly 9 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      value: d['is_baptized'],
                      onChanged: (v) =>
                          setState(() => d['is_baptized'] = v ?? false),
                      title: const Text(
                        'Baptized',
                        style: TextStyle(fontSize: 14),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      value: d['takes_holy_communion'],
                      onChanged: (v) => setState(
                        () => d['takes_holy_communion'] = v ?? false,
                      ),
                      title: const Text(
                        'Holy Communion',
                        style: TextStyle(fontSize: 14),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: d['school'],
                decoration: const InputDecoration(
                  labelText: "School (optional)",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),

              // PHOTOS SECTION
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Photos (Max 3)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Add Button
                      if ((d['photos'] as List).length < 3)
                        GestureDetector(
                          onTap: () => _showDependentPhotoOptions(i),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: Colors.grey),
                                SizedBox(height: 4),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Display Added Photos
                      ...((d['photos'] as List<XFile>).asMap().entries.map((
                        entry,
                      ) {
                        final idx = entry.key;
                        final file = entry.value;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                                image: DecorationImage(
                                  image: FileImage(File(file.path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: GestureDetector(
                                onTap: () => _removeDependentPhoto(i, idx),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      })),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDependentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: "Add your dependents (Optional)",
          subtitle: "Add information about your children or dependents",
        ),

        CheckboxListTile(
          value: hasDependents,
          onChanged: (v) {
            setState(() {
              hasDependents = v ?? false;
              // If checked and list is empty, auto-add the first dependent.
              if (hasDependents && dependents.isEmpty) {
                addDependent();
              } else if (!hasDependents) {
                // If unchecked, clear list.
                dependents.clear();
              }
            });
          },
          title: const Text(
            'Do you have dependents to add?',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),

        if (hasDependents) ...[
          const SizedBox(height: 16),
          ...List.generate(dependents.length, (i) {
            return _buildDependentCard(i, dependents[i]);
          }),
          Center(
            child: ElevatedButton.icon(
              onPressed: addDependent,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                backgroundColor: Color(0xFF0A1F44),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),

              label: const Text('Add Another Dependent'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSecurityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          title: "Account Security",
          subtitle: "Create a secure password for your account",
        ),

        _buildInputField(
          controller: password,
          hintText: "Create a strong password *",
          icon: Icons.lock_outlined,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.black,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is mandatory';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        _buildInputField(
          controller: passwordConfirm,
          hintText: "Confirm your password *",
          icon: Icons.lock_outlined,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.black,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != password.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  void _openGroupsDialog() {
    final temp = Set<int>.from(selectedGroupIds);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text("Select church groups you're in"),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: groups.map((group) {
                    final groupId = (group['id'] as num).toInt();
                    final isSelected = temp.contains(groupId);
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Theme.of(context).colorScheme.primary,
                        checkColor: Colors.white,
                        title: Text(
                          group['name']?.toString() ?? '',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : null,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade400,
                          width: 1.4,
                        ),
                        onChanged: (checked) {
                          setLocal(() {
                            if (checked == true) {
                              temp.add(groupId);
                            } else {
                              temp.remove(groupId);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedGroupIds
                        ..clear()
                        ..addAll(temp);
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _maritalIcon(String value) {
    switch (value) {
      case 'Single':
        return Icons.person_outline;
      case 'Married (Customary)':
      case 'Married (Church Wedding)':
        return Icons.favorite_outline;
      case 'Divorced':
        return Icons.heart_broken_outlined;
      case 'Widow':
        return Icons.woman_outlined;
      case 'Widower':
        return Icons.man_outlined;
      case 'Separated':
        return Icons.remove_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  void _openMaritalStatusPicker() {
    final options = <String>[
      'Single',
      'Married (Customary)',
      'Married (Church Wedding)',
      'Divorced',
      'Widow',
      'Widower',
      'Separated',
    ];
    List<String> filtered = List<String>.from(options);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setLocal) {
                void applyFilter(String q) {
                  final ql = q.toLowerCase();
                  setLocal(() {
                    filtered = options
                        .where((s) => s.toLowerCase().contains(ql))
                        .toList();
                  });
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search marital status...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: applyFilter,
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final v = filtered[index];
                          return ListTile(
                            leading: Icon(_maritalIcon(v)),
                            title: Text(v),
                            trailing: v == maritalStatus
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () {
                              setState(() => maritalStatus = v);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  IconData _genderIcon(String v) {
    switch (v) {
      case 'Male':
        return Icons.male;
      case 'Female':
        return Icons.female;
      default:
        return Icons.person_outline;
    }
  }

  void _openGenderPicker() {
    final options = <String>['Male', 'Female'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Select gender',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...options.map(
                (v) => ListTile(
                  leading: Icon(_genderIcon(v)),
                  title: Text(v),
                  trailing: v == gender
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() => gender = v);
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // Region and presbytery pickers are no longer required now that parish selection auto-fills them.

  void _openParishPicker() {
    List<Map<String, dynamic>> filtered = List<Map<String, dynamic>>.from(
      parishes,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setLocal) {
                void applyFilter(String q) {
                  final ql = q.toLowerCase();
                  setLocal(() {
                    filtered = parishes.where((p) {
                      final parishName = (p['name']?.toString() ?? '')
                          .toLowerCase();
                      final presbyteryName =
                          (p['presbytery_name']?.toString() ?? '')
                              .toLowerCase();
                      final regionName = (p['region_name']?.toString() ?? '')
                          .toLowerCase();

                      return parishName.contains(ql) ||
                          presbyteryName.contains(ql) ||
                          regionName.contains(ql);
                    }).toList();
                  });
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search parish...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: applyFilter,
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          final parishId = p['id']?.toString() ?? '';
                          final parishName = p['name']?.toString() ?? '';
                          final presbyteryName =
                              p['presbytery_name']?.toString() ?? '';
                          final regionName = p['region_name']?.toString() ?? '';
                          final subtitleParts = <String>[];
                          if (presbyteryName.isNotEmpty) {
                            subtitleParts.add(presbyteryName);
                          }
                          if (regionName.isNotEmpty) {
                            subtitleParts.add(regionName);
                          }
                          final isSelected =
                              parishId.isNotEmpty &&
                              parishId == selectedParishId;
                          return ListTile(
                            leading: const Icon(Icons.church),
                            title: Text(parishName),
                            subtitle: subtitleParts.isEmpty
                                ? null
                                : Text(subtitleParts.join(' • ')),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () {
                              setState(() {
                                selectedParishId = parishId;
                                selectedParishName = parishName;
                                selectedPresbyteryId =
                                    p['presbytery_id']?.toString() ?? '';
                                selectedPresbyteryName = presbyteryName;
                                selectedRegionId =
                                    p['region_id']?.toString() ?? '';
                                selectedRegionName = regionName;
                                regionController.text = regionName;
                                presbyteryController.text = presbyteryName;
                              });
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _CreativeArrowButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isForward,
  }) {
    final color = onPressed != null ? primaryColor : Colors.grey.shade400;

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isForward) ...[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
        if (isForward) ...[
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Icon(icon, color: color, size: 20),
        ],
      ],
    );

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: buttonContent,
      ),
    );
  }

  Widget _buildOnboardingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentStep = index;
                  });
                },
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 24,
                      bottom: 40,
                    ),
                    child: _buildPersonalInfoStep(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 24,
                      bottom: 40,
                    ),
                    child: _buildChurchDetailsStep(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 24,
                      bottom: 40,
                    ),
                    child: _buildDependentsStep(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 24,
                      bottom: 40,
                    ),
                    child: _buildSecurityStep(),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CreativeArrowButton(
                        label: 'Previous',
                        icon: Icons.arrow_back_ios_new_rounded,
                        isForward: false,
                        onPressed: currentStep > 0 ? previousStep : null,
                      ),
                      _buildStepIndicator(),
                      currentStep == totalSteps - 1
                          ? _CreativeArrowButton(
                              label: isLoading ? 'Registering...' : 'Finish',
                              icon: isLoading
                                  ? Icons.hourglass_top
                                  : Icons.check_circle_outline,
                              isForward: true,
                              onPressed: isLoading ? null : submit,
                            )
                          : _CreativeArrowButton(
                              label: 'Next',
                              icon: Icons.arrow_forward_ios_rounded,
                              isForward: true,
                              onPressed: nextStep,
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const Login()),
                        ),
                        child: Text(
                          "Login",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileOnboarding() {
    return SafeArea(
      child: Column(children: [Expanded(child: _buildOnboardingCard())]),
    );
  }

  Widget _buildDesktopOnboarding() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SafeArea(
          child: Center(
            child: SizedBox(
              width: 520,
              height: constraints.maxHeight,
              child: _buildOnboardingCard(),
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
      body: ResponsiveLayout(
        mobile: _buildMobileOnboarding(),
        desktop: DesktopScaffoldFrame(
          backgroundColor: const Color(0xFFE8F4FD),
          title: '',
          primaryColor: const Color(0xFF35C2C1),
          child: _buildDesktopOnboarding(),
        ),
      ),
    );
  }
}
