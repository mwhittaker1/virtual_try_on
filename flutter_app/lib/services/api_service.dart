import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/selfie_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000'; // Android emulator
  // Use 'http://localhost:8000' for iOS simulator
  // Use your actual IP for physical devices

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  Future<List<SelfieModel>> getTestSelfies() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test-selfies'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> selfiesJson = data['selfies'];
        
        return selfiesJson
            .map((json) => SelfieModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load test selfies');
      }
    } catch (e) {
      print('Error fetching test selfies: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-image'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to upload image: ${response.body}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/analyze-image'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to analyze image: ${response.body}');
      }
    } catch (e) {
      print('Error analyzing image: $e');
      rethrow;
    }
  }
    Future<Map<String, dynamic>> segmentClothing(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/segment-clothing'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to segment clothing: ${response.body}');
      }
    } catch (e) {
      print('Error segmenting clothing: $e');
      rethrow;
    }
  }
}