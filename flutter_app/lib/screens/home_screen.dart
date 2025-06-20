import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/image_provider.dart';
import '../services/api_service.dart';
import 'photo_gallery_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'segmentation_screen.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isConnected = false;
  bool _isCheckingConnection = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final apiService = context.read<ApiService>();
    final isHealthy = await apiService.checkHealth();
    
    setState(() {
      _isConnected = isHealthy;
      _isCheckingConnection = false;
    });

    if (isHealthy) {
      // Load test selfies when connection is established
      if (mounted) {
        context.read<ImageProviderService>().loadTestSelfies();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Dressing Room'),
        centerTitle: true,
      ),
      body: _isCheckingConnection
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isConnected) {
      return _buildConnectionError();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          _buildSelectedPhotoPreview(),
          const SizedBox(height: 16),
          _buildFeaturesSection(),
        ],
      ),
    );
  }

  Widget _buildConnectionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to connect to the backend server.\nPlease make sure the Python server is running.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isCheckingConnection = true;
                });
                _checkConnection();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to Virtual Dressing Room',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try on clothes virtually with AI-powered fashion technology',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green[300],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Backend Connected',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final imageProvider = context.read<ImageProviderService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          icon: Icons.photo_library,
          title: 'Test Photo Gallery',
          description: 'Choose from curated test photos with different poses and lighting conditions',
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PhotoGalleryScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.camera_alt,
          title: 'Upload Your Photo',
          description: 'Take a new photo or select from your gallery for virtual try-on',
          color: Colors.green,
          onTap: () {
            _showImagePickerDialog();
          },
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.analytics,
          title: 'AI Analysis',
          description: 'Get insights about pose quality, lighting, and suitability for virtual try-on',
          color: Colors.orange,
          onTap: () {
            File? imageFile;
            if (imageProvider.selectedTestSelfie != null && 
                imageProvider.selectedTestSelfie!.id.startsWith('uploaded_')) {
              imageFile = imageProvider.getImageFile(imageProvider.selectedTestSelfie!.id);
            } else if (imageProvider.selectedImage != null) {
              imageFile = imageProvider.selectedImage;
            }
            if (imageFile != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SegmentationScreen(imageFile: imageFile!),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please upload a photo first to analyze'),
                  backgroundColor: Colors.blue,
                ),
              );
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Photo Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              subtitle: const Text('Take a new photo'),
              onTap: () async {
                Navigator.pop(context);
                await _handleImageUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _handleImageUpload(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageUpload(ImageSource source) async {
    final imageProvider = context.read<ImageProviderService>();
    
    try {
      // Pick image based on source
      if (source == ImageSource.camera) {
        await imageProvider.pickImageFromCamera();
      } else {
        await imageProvider.pickImageFromGallery();
      }

      // Check if image was selected
      if (imageProvider.selectedImage != null) {
        // Show progress dialog and handle upload
        if (mounted) {
          final success = await _showUploadProgressDialog(imageProvider);
          
          if (success && mounted) {
            _showSuccessDialog();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showUploadProgressDialog(ImageProviderService imageProvider) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UploadProgressDialog(
        imageProvider: imageProvider,
      ),
    );
    
    return result ?? false;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Photo Uploaded Successfully!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your photo has been added to the gallery',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPhotoPreview() {
    final imageProvider = context.watch<ImageProviderService>();
    final File? selectedFile = imageProvider.selectedImage;
    const double previewSize = 160;
    if (selectedFile == null) {
      return Container(
        width: previewSize,
        height: previewSize,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.image, color: Colors.grey, size: 48),
            SizedBox(height: 12),
            Text(
              'To preview, first select an image',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      );
    }
    return Container(
      width: previewSize,
      height: previewSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.file(
        selectedFile,
        fit: BoxFit.contain,
        width: previewSize,
        height: previewSize,
      ),
    );
  }
}

class UploadProgressDialog extends StatefulWidget {
  final ImageProviderService imageProvider;

  const UploadProgressDialog({
    super.key,
    required this.imageProvider,
  });

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog> {
  bool _uploadStarted = false;

  @override
  void initState() {
    super.initState();
    _startUpload();
  }

  Future<void> _startUpload() async {
    if (_uploadStarted) return;
    _uploadStarted = true;

    // Delay to prevent build-time notifications
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.imageProvider.selectedImage != null) {
        final success = await widget.imageProvider.addUploadedPhoto(
          widget.imageProvider.selectedImage!,
        );
        
        if (mounted) {
          Navigator.of(context).pop(success);
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop(false);
        }
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Consumer<ImageProviderService>(
          builder: (context, imageProvider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_upload,
                  size: 50,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Uploading Photo...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Analyzing image and adding to gallery',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                LinearProgressIndicator(
                  value: imageProvider.uploadProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(imageProvider.uploadProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                if (imageProvider.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    imageProvider.error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}