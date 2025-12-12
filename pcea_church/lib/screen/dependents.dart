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

    if (result == true) fetchDependents();
  }

  Future<void> _navigateToEditDependent(Dependent dependent) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DependentFormScreen(dependent: dependent),
      ),
    );

    if (result == true) fetchDependents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F44),
      appBar: AppBar(
        title: const Text(
          'My Dependentsl',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFF0A1F44),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddDependent,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Dependent"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildErrorWidget()
          : dependents.isEmpty
          ? _buildEmptyWidget()
          : _buildDependentsList(),
    );
  }

  Widget _buildErrorWidget() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 80),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Dependents',
            style: TextStyle(
              fontSize: 20,
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
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: fetchDependents,
          ),
        ],
      ),
    ),
  );

  Widget _buildEmptyWidget() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.family_restroom, size: 90, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No Dependents Found',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'You have not registered any dependents yet.\nTap below to add one.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddDependent,
            icon: const Icon(Icons.add),
            label: const Text('Add Dependent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildDependentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dependents.length,
      itemBuilder: (context, index) {
        final dependent = dependents[index];
        return _buildDependentCard(dependent);
      },
    );
  }

  Widget _buildDependentCard(Dependent dependent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        leading: CircleAvatar(
          radius: 40,
          backgroundColor: Colors.teal.shade100,
          child: Text(
            dependent.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        title: Text(
          dependent.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Age: ${dependent.age} years',
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
              if (dependent.school != null && dependent.school!.isNotEmpty)
                Text(
                  'School: ${dependent.school}',
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Color(0xFF0A1F44)),
          onPressed: () => _navigateToEditDependent(dependent),
          tooltip: 'Update Dependent Details',
        ),
        onTap: () => _showDependentDetails(dependent),
      ),
    );
  }

  void _showDependentDetails(Dependent dependent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.teal.shade100,
                child: Text(
                  dependent.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                dependent.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Age: ${dependent.age} years',
                style: const TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const Divider(height: 30),
              _buildInfoTile(
                Icons.badge,
                "Birth Certificate",
                dependent.birthCertNumber ?? 'Not provided',
              ),
              _buildInfoTile(
                Icons.school,
                "School",
                dependent.school ?? 'Not specified',
              ),
              _buildInfoTile(
                Icons.water_drop,
                "Baptized",
                dependent.isBaptized ? "Yes" : "No",
              ),
              _buildInfoTile(
                Icons.local_drink,
                "Holy Communion",
                dependent.takesHolyCommunion ? "Yes" : "No",
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _navigateToEditDependent(dependent),
                icon: const Icon(Icons.edit),
                label: const Text("Edit Dependent"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.teal.shade600),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
      ),
    );
  }
}
