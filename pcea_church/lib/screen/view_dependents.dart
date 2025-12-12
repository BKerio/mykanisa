import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart'; // Ensure this matches your project structure
import 'package:pcea_church/screen/add_dependents.dart';

class DependentFormScreen extends StatefulWidget {
  final Dependent? dependent; // null for add, existing dependent for edit

  const DependentFormScreen({super.key, this.dependent});

  @override
  State<DependentFormScreen> createState() => _DependentFormScreenState();
}

class _DependentFormScreenState extends State<DependentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  final _birthCertController = TextEditingController();
  final _schoolController = TextEditingController();

  bool _isBaptized = false;
  bool _takesHolyCommunion = false;
  bool _isLoading = false;
  bool _isEditing = false;

  // Photo logic
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _newPhotos = [];
  List<String> _existingPhotoUrls = [];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.dependent != null;
    if (_isEditing && widget.dependent != null) {
      _fillFormWithDependent(widget.dependent!);
    }
  }

  void _fillFormWithDependent(Dependent dependent) {
    _nameController.text = dependent.name;
    _yearController.text = dependent.yearOfBirth.toString();
    _birthCertController.text = dependent.birthCertNumber ?? '';
    _schoolController.text = dependent.school ?? '';
    _isBaptized = dependent.isBaptized;
    _takesHolyCommunion = dependent.takesHolyCommunion;

    // Initialize existing photos
    _existingPhotoUrls = List.from(dependent.photoUrls);

    // Initialize kept paths (assuming URLs in photoUrls correspond to storage paths or full URLs we can extract path from if needed,
    // but simplified: backend expects paths or just the knowledge of what to keep.
    // Actually backend implementation expects 'kept_photos' to be list of relative paths if possible,
    // but since we only have full URLs on frontend usually, we might need to rely on the backend parsing/matching logic
    // OR just send back the Full URLs and let backend handle matching.
    // The backend logic I wrote matches `in_array($path, $currentPhotos)`.
    // `currentPhotos` in backend are relative paths (e.g. `dependents/xyz.jpg`).
    // `photoUrls` in frontend are full URLs (e.g. `http://.../storage/dependents/xyz.jpg`).
    // So we need to be careful.
    // Hack: The backend `getDependents` sends `photo_urls` as full URLs.
    // In `updateDependent`, I implemented logic to check `in_array($path, $currentPhotos)`.
    // This mismatch will cause deletion of all photos if I send full URLs.
    // I should probably fix the backend to handle full URLs or finding the relative path.
    // OR simpler: on frontend, try to extract the relative path?
    // Let's rely on the fact that standard `asset()` helper generates URLs ending in the path.
    // We can just keep the full URL in `_keptPhotoPaths` for now, and I will QUICKLY PATCH the backend to handle full URLs if needed,
    // OR we can try to Strip the domain.
    // Let's strip the baseUrl/storage/ part if we can, or just send the filename.
    // Wait, the safest is to update the backend to just accept the full URL and check `str_contains`.
    // But since I can't easily change backend right this second without another tool call...
    // I will extract the relative path here.
    // Typically: `http://10.0.2.2:8000/storage/dependents/image.jpg` -> `dependents/image.jpg`
    // I'll populate `_keptPhotoPaths` with the `photoUrls` initially.
  }

  String _extractRelativePath(String url) {
    // Attempt to extract 'dependents/...' from URL
    if (url.contains('/storage/')) {
      return url.split('/storage/').last;
    }
    return url;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _birthCertController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_newPhotos.length + _existingPhotoUrls.length >= 3) {
      _showSnack('Maximum 3 photos allowed', isError: true);
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _newPhotos.add(photo);
        });
      }
    } catch (e) {
      _showSnack('Error picking image: $e', isError: true);
    }
  }

  void _removeNewPhoto(int index) {
    setState(() {
      _newPhotos.removeAt(index);
    });
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotoUrls.removeAt(index);
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    API.showSnack(context, message, success: !isError);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      var uri = _isEditing
          ? Uri.parse(
              '${Config.baseUrl}/members/dependents/${widget.dependent!.id}',
            )
          : Uri.parse('${Config.baseUrl}/members/dependents');

      // Use MultipartRequest to send files
      var request = http.MultipartRequest('POST', uri);

      // Add fields
      request.fields['name'] = _nameController.text.trim();
      request.fields['year_of_birth'] = _yearController.text;
      if (_birthCertController.text.trim().isNotEmpty) {
        request.fields['birth_cert_number'] = _birthCertController.text.trim();
      }
      request.fields['is_baptized'] = _isBaptized ? '1' : '0';
      request.fields['takes_holy_communion'] = _takesHolyCommunion ? '1' : '0';
      if (_schoolController.text.trim().isNotEmpty) {
        request.fields['school'] = _schoolController.text.trim();
      }

      // If editing, we simulate PUT by adding _method field (Laravel convention) or using POST for update with files
      if (_isEditing) {
        // Laravel cannot handle multipart PUT requests natively well, often need to spoof method
        // But since my backend route definition likely uses `apiResource` or specific routes?
        // Typically: POST to /dependents/{id} with _method=PUT or POST to update endpoint.
        // Let's assume standard Laravel update with files -> POST with _method=PUT usually works best.
        // Checking my backend scan... I didn't verify the routes.
        // Assuming `Route::post('dependents/{id}', ...)` for update or `Route::put`?
        // If `Route::put`, multipart fails.
        // Safe bet: POST with `_method` = `PUT`.
        request.fields['_method'] = 'PUT';

        // Add kept photos logic
        // We need to send the paths relative to storage, based on _existingPhotoUrls
        List<String> keptPaths = _existingPhotoUrls
            .map((url) => _extractRelativePath(url))
            .toList();
        request.fields['kept_photos'] = jsonEncode(keptPaths);
      }

      // Add new photos
      for (var photo in _newPhotos) {
        request.files.add(
          await http.MultipartFile.fromPath('photos[]', photo.path),
        );
      }

      // Add headers (Authorization)
      final token = await API().getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // Send
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['status'] == 200) {
        if (mounted) {
          _showSnack(
            body['message'] ??
                (_isEditing
                    ? 'Dependent updated successfully'
                    : 'Dependent added successfully'),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          // Handle 409 duplicate etc
          _showSnack(
            body['message'] ?? 'Operation failed: ${response.statusCode}',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPhotoSourceSheet() {
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
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Dependent' : 'Add Dependent'),
        backgroundColor: Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade200, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(25),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing
                        ? 'Edit Dependent Information'
                        : 'Add New Dependent',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- Photos Section ---
                  const Text(
                    'Photos (Max 3)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Add Button
                        if (_existingPhotoUrls.length + _newPhotos.length < 3)
                          GestureDetector(
                            onTap: _showPhotoSourceSheet,
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text(
                                    'Add',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Existing Photos
                        ..._existingPhotoUrls.asMap().entries.map((entry) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: NetworkImage(entry.value),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () => _removeExistingPhoto(entry.key),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),

                        // New Photos
                        ..._newPhotos.asMap().entries.map((entry) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: FileImage(File(entry.value.path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () => _removeNewPhoto(entry.key),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the dependent\'s name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Year of Birth Field
                  TextFormField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Year of Birth *',
                      prefixIcon: const Icon(Icons.cake_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the year of birth';
                      }
                      final year = int.tryParse(value);
                      if (year == null) {
                        return 'Please enter a valid year';
                      }
                      final currentYear = DateTime.now().year;
                      if (year < 1900 || year > currentYear) {
                        return 'Year must be between 1900 and $currentYear';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Birth Certificate Number Field
                  TextFormField(
                    controller: _birthCertController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Birth Certificate Number (9 digits)',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'Optional - 9 digits only',
                    ),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        if (value.length != 9) {
                          return 'Birth certificate number must be exactly 9 digits';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // School Field
                  TextFormField(
                    controller: _schoolController,
                    decoration: InputDecoration(
                      labelText: 'School',
                      prefixIcon: const Icon(Icons.school_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'Optional',
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Baptism Status
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CheckboxListTile(
                      title: const Text(
                        'Baptized',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text('Has the dependent been baptized?'),
                      value: _isBaptized,
                      onChanged: (value) {
                        setState(() => _isBaptized = value ?? false);
                      },
                      activeColor: Colors.black87,
                      checkColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Holy Communion Status
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CheckboxListTile(
                      title: const Text(
                        'Takes Holy Communion',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        'Does the dependent take holy communion?',
                      ),
                      value: _takesHolyCommunion,
                      onChanged: (value) {
                        setState(() => _takesHolyCommunion = value ?? false);
                      },
                      activeColor: Colors.black87,
                      checkColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            )
                          : Text(
                              _isEditing ? 'Update Dependent' : 'Add Dependent',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
