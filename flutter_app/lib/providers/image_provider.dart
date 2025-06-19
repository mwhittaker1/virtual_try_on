import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/selfie_model.dart';
import '../services/api_service.dart';

class ImageProviderService extends ChangeNotifier {
  final ApiService apiService;
  final ImagePicker _picker = ImagePicker();

  ImageProviderService({required this.apiService});

  List<SelfieModel> _testSelfies = [];
  SelfieModel? _selectedTestSelfie;
  File? _selectedImage;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _analysisResult;

  // Getters
  List<SelfieModel> get testSelfies => _testSelfies;
  SelfieModel? get selectedTestSelfie => _selectedTestSelfie;
  File? get selectedImage => _selectedImage;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get analysisResult => _analysisResult;

  // Load test selfies from API
  Future<void> loadTestSelfies() async {
    _setLoading(true);
    _clearError();

    try {
      _testSelfies = await apiService.getTestSelfies();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load test selfies: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Select a test selfie
  void selectTestSelfie(SelfieModel selfie) {
    _selectedTestSelfie = selfie;
    _selectedImage = null; // Clear any uploaded image
    _analysisResult = null;
    notifyListeners();
  }

  // Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedImage = File(image.path);
        _selectedTestSelfie = null; // Clear test selfie selection
        _analysisResult = null;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to capture image: $e');
    }
  }

  // Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedImage = File(image.path);
        _selectedTestSelfie = null; // Clear test selfie selection
        _analysisResult = null;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to pick image: $e');
    }
  }

  // Upload and analyze selected image
  Future<void> analyzeSelectedImage() async {
    if (_selectedImage == null) return;

    _setLoading(true);
    _clearError();

    try {
      _analysisResult = await apiService.analyzeImage(_selectedImage!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to analyze image: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Clear selection
  void clearSelection() {
    _selectedTestSelfie = null;
    _selectedImage = null;
    _analysisResult = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}