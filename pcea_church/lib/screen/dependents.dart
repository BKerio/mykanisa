import 'package:flutter/material.dart';
import 'package:pcea_church/config/server.dart';
import 'dart:convert';

import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/screen/my_dependents.dart';

class DependentsScreen extends StatefulWidget {
  const DependentsScreen({super.key});

  @override
  State<DependentsScreen> createState() => _DependentsScreenState();
}

class Dependent {
  final int id;
  final String name;
  final int yearOfBirth;
  final String? birthCertNumber;
  final bool isBaptized;
  final bool takesHolyCommunion;
  final String? school;

  Dependent({
    required this.id,
    required this.name,
    required this.yearOfBirth,
    this.birthCertNumber,
    required this.isBaptized,
    required this.takesHolyCommunion,
    this.school,
  });

  factory Dependent.fromJson(Map<String, dynamic> json) {
    return Dependent(
      id: json['id'],
      name: json['name'],
      yearOfBirth: json['year_of_birth'],
      birthCertNumber: json['birth_cert_number'],
      isBaptized: json['is_baptized'] ?? false,
      takesHolyCommunion: json['takes_holy_communion'] ?? false,
      school: json['school'],
    );
  }

  int get age => DateTime.now().year - yearOfBirth;
}

class _DependentsScreenState extends State<DependentsScreen> {
  List<Dependent> dependents = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchDependents();
  }

  Future<void> fetchDependents() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/members/dependents'),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        if (body['status'] == 200) {
          final dependentsData = body['dependents'] as List;
          setState(() {
            dependents = dependentsData
                .map((json) => Dependent.fromJson(json as Map<String, dynamic>))
                .toList();
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = body['message'] ?? 'Failed to fetch dependents';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to fetch dependents. Please try again.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _navigateToAddDependent() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DependentFormScreen()));

    if (result == true) {
      fetchDependents(); // Refresh the list
    }
  }

  Future<void> _navigateToEditDependent(Dependent dependent) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DependentFormScreen(dependent: dependent),
      ),
    );

    if (result == true) {
      fetchDependents(); // Refresh the list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dependents'),
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddDependent,
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.black87,
        icon: const Icon(Icons.add),
        label: const Text("Add Dependent"),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade200, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                ),
              )
            : errorMessage != null
            ? _buildErrorWidget()
            : dependents.isEmpty
            ? _buildEmptyWidget()
            : _buildDependentsList(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
          const SizedBox(height: 20),
          const Text(
            'Error Loading Dependents',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: fetchDependents,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.family_restroom, size: 100, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            const Text(
              'No Dependents Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You haven\'t registered any dependents yet.\nTap the button below to add one.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _navigateToAddDependent,
              icon: const Icon(Icons.add),
              label: const Text('Add Dependent'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDependentsList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(
                Icons.family_restroom,
                color: Colors.black87,
                size: 30,
              ),
              const SizedBox(width: 10),
              Text(
                'Your Dependents (${dependents.length})',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dependents.length,
            itemBuilder: (context, index) {
              final dependent = dependents[index];
              return _buildDependentCard(dependent);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDependentCard(Dependent dependent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade300,
                  child: Text(
                    dependent.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dependent.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Age: ${dependent.age} years',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text('Born ${dependent.yearOfBirth}'),
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (dependent.birthCertNumber != null)
              _buildInfoRow(
                Icons.badge,
                'Birth Certificate',
                dependent.birthCertNumber!,
              ),
            if (dependent.school != null && dependent.school!.isNotEmpty)
              _buildInfoRow(Icons.school, 'School', dependent.school!),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatusChip(
                    'Baptized',
                    dependent.isBaptized,
                    Icons.water_drop,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatusChip(
                    'Holy Communion',
                    dependent.takesHolyCommunion,
                    Icons.local_drink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToEditDependent(dependent),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Dependent'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade50,
                  foregroundColor: Colors.teal.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, bool status, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: status ? Colors.grey.shade200 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: status ? Colors.black45 : Colors.black26,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: status ? Colors.black87 : Colors.black54),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: status ? Colors.black87 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
