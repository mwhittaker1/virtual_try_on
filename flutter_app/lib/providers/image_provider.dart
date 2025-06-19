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
  List<SelfieModel> _uploadedSelfies = []; 
  SelfieModel? _selectedTestSelfie;
  File? _selectedImage;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _analysisResult;

  // Getters
  List<SelfieModel> get testSelfies => _testSelfies;
  List<SelfieModel> get uploadedSelfies => _uploadedSelfies;
  List<SelfieModel> get allSelfies => [..._testSelfies, ..._uploadedSelfies];
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

  Future<void> addUploadedPhoto(File imageFile) async {
    _setLoading(true);
    _clearError();

    try {
      // Analyze the image first
      final analysis = await apiService.analyzeImage(imageFile);
      
      // Create a new selfie model for the uploaded photo
      final uploadedSelfie = SelfieModel(
        id: 'uploaded_${DateTime.now().millisecondsSinceEpoch}',
        name: 'My Upload - ${_getDifficultyFromAnalysis(analysis)}',
        difficulty: _getDifficultyFromAnalysis(analysis),
        poseType: analysis['analysis']['pose_type'] ?? 'unknown',
        lightingQuality: analysis['analysis']['lighting_quality'] ?? 'unknown',
        backgroundComplexity: analysis['analysis']['background_complexity'] ?? 'unknown',
        bodyType: 'user_upload',
        description: 'User uploaded photo - ${analysis['analysis']['image_quality'] ?? 'good'} quality',
      );

      // Copy image to a permanent location (in a real app, you'd save to documents)
      _uploadedSelfies.add(uploadedSelfie);
      
      // Select the newly uploaded photo
      _selectedTestSelfie = uploadedSelfie;
      _selectedImage = imageFile;
      _analysisResult = analysis;
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to add uploaded photo: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Remove uploaded photo
  void removeUploadedPhoto(String photoId) {
    _uploadedSelfies.removeWhere((selfie) => selfie.id == photoId);
    
    // Clear selection if the removed photo was selected
    if (_selectedTestSelfie?.id == photoId) {
      _selectedTestSelfie = null;
      _selectedImage = null;
      _analysisResult = null;
    }
    
    notifyListeners();
  }

  // Helper method to determine difficulty from analysis
  String _getDifficultyFromAnalysis(Map<String, dynamic> analysis) {
    final imageQuality = analysis['analysis']['image_quality'] ?? 'good';
    final lightingQuality = analysis['analysis']['lighting_quality'] ?? 'good';
    final backgroundComplexity = analysis['analysis']['background_complexity'] ?? 'simple';
    
    if (imageQuality == 'excellent' && lightingQuality == 'good' && backgroundComplexity == 'simple') {
      return 'Ideal';
    } else if (imageQuality == 'poor' || lightingQuality == 'poor' || backgroundComplexity == 'complex') {
      return 'Challenging';
    } else {
      return 'Moderate';
    }
  }

  // Get image file for uploaded photos
  File? getImageFile(String selfieId) {
    if (selfieId.startsWith('uploaded_') && _selectedImage != null && _selectedTestSelfie?.id == selfieId) {
      return _selectedImage;
    }
    return null;
  }
}