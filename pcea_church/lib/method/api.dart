import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class API {
  // Unified snackbar helper
  static void showSnack(BuildContext context, String message,
      {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<http.Response> postRequest({
    required Uri url,
    required Map<String, dynamic> data,
  }) async {
    try {
      final headers = await _header();
      return await http.post(url, body: jsonEncode(data), headers: headers);
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  Future<http.Response> getRequest({required Uri url}) async {
    try {
      final headers = await _header();
      return await http.get(url, headers: headers);
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  Future<http.Response> putRequest({
    required Uri url,
    required Map<String, dynamic> data,
  }) async {
    try {
      final headers = await _header();
      return await http.put(url, body: jsonEncode(data), headers: headers);
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  Future<http.Response> deleteRequest({required Uri url}) async {
    try {
      final headers = await _header();
      return await http.delete(url, headers: headers);
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  Future<Map<String, String>> _header() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = <String, String>{
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.StreamedResponse> uploadMultipart({
    required Uri url,
    required Map<String, String> fields,
    required String fileField,
    required String filePath,
    bool requireAuth = true,
  }) async {
    final request = http.MultipartRequest('POST', url);
    request.fields.addAll(fields);
    
    // Add Accept header to ensure JSON response
    request.headers['Accept'] = 'application/json';
    
    if (requireAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    return request.send();
  }

  Future<http.StreamedResponse> uploadMultipartWithFiles({
    required Uri url,
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
    bool requireAuth = true,
  }) async {
    final request = http.MultipartRequest('POST', url);
    request.fields.addAll(fields);
    
    // Add Accept header to ensure JSON response
    request.headers['Accept'] = 'application/json';
    
    if (requireAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    
    // Add all files to the request
    request.files.addAll(files);
    
    return request.send();
  }
}
