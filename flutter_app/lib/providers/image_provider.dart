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
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;
  Map<String, dynamic>? _analysisResult;
  Map<String, dynamic>? _segmentationResult;

  // Getters
  List<SelfieModel> get testSelfies => _testSelfies;
  List<SelfieModel> get uploadedSelfies => _uploadedSelfies;
  List<SelfieModel> get allSelfies => [..._testSelfies, ..._uploadedSelfies];
  SelfieModel? get selectedTestSelfie => _selectedTestSelfie;
  File? get selectedImage => _selectedImage;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;
  Map<String, dynamic>? get analysisResult => _analysisResult;
  Map<String, dynamic>? get segmentationResult => _segmentationResult;

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

  // Upload and analyze selected image with progress tracking
  Future<bool> addUploadedPhoto(File imageFile) async {
    _setUploading(true);
    _setUploadProgress(0.0);
    _clearError();

    try {
      // Simulate progress steps
      _setUploadProgress(0.2);
      await Future.delayed(const Duration(milliseconds: 300));

      _setUploadProgress(0.5);
      final analysis = await apiService.analyzeImage(imageFile);
      
      _setUploadProgress(0.8);
      await Future.delayed(const Duration(milliseconds: 200));

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

      _uploadedSelfies.add(uploadedSelfie);

      // Store the image file for later retrieval
      _uploadedImages[uploadedSelfie.id] = imageFile;

      _selectedTestSelfie = uploadedSelfie;
      _selectedImage = imageFile;
      _analysisResult = analysis;

      _setUploadProgress(1.0);
      await Future.delayed(const Duration(milliseconds: 200));

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add uploaded photo: $e');
      return false;
    } finally {
      _setUploading(false);
      _setUploadProgress(0.0);
    }
  }

  // Analyze selected image
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

  // Store uploaded images properly
  Map<String, File> _uploadedImages = {};

  // Get image file for uploaded photos  
  File? getImageFile(String selfieId) {
    if (selfieId.startsWith('uploaded_')) {
      return _uploadedImages[selfieId];
    }
    return null;
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setUploading(bool uploading) {
    _isUploading = uploading;
    notifyListeners();
  }

  void _setUploadProgress(double progress) {
    _uploadProgress = progress;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
  // Segment clothing in selected image
  Future<void> segmentImageFile(File imageFile) async {
    _setLoading(true);
    _clearError();

    try {
      _segmentationResult = await apiService.segmentClothing(imageFile);
      notifyListeners();
    } catch (e) {
      _setError('Failed to segment clothing: $e');
    } finally {
      _setLoading(false);
    }
  }
}