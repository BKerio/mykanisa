import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'dart:convert';

import 'package:pcea_church/screen/dependents.dart';

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _birthCertController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'year_of_birth': int.parse(_yearController.text),
        'birth_cert_number': _birthCertController.text.trim().isEmpty
            ? null
            : _birthCertController.text.trim(),
        'is_baptized': _isBaptized,
        'takes_holy_communion': _takesHolyCommunion,
        'school': _schoolController.text.trim().isEmpty
            ? null
            : _schoolController.text.trim(),
      };

      final response = _isEditing
          ? await API().putRequest(
              url: Uri.parse('${Config.baseUrl}/members/dependents/${widget.dependent!.id}'),
              data: data,
            )
          : await API().postRequest(
              url: Uri.parse('${Config.baseUrl}/members/dependents'),
              data: data,
            );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['status'] == 200) {
        if (mounted) {
          API.showSnack(
            context,
            body['message'] ??
                (_isEditing
                    ? 'Dependent updated successfully'
                    : 'Dependent added successfully'),
            success: true,
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          API.showSnack(
            context,
            body['message'] ?? 'Operation failed',
            success: false,
          );
        }
      }
    } catch (e) {
        if (mounted) {
          API.showSnack(context, 'Error: $e', success: false);
        }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Dependent' : 'Add Dependent'),
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.black87,
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
