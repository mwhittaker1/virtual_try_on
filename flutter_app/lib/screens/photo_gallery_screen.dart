import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/image_provider.dart';
import '../models/selfie_model.dart';
import 'segmentation_screen.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Ideal', 'Moderate', 'Challenging'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Photo Gallery'),
        centerTitle: true,
      ),
      body: Consumer<ImageProviderService>(
        builder: (context, imageProvider, child) {
          if (imageProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (imageProvider.error != null) {
            return _buildErrorWidget(imageProvider.error!);
          }

          final filteredSelfies = _getFilteredSelfies(imageProvider.allSelfies);

          return Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: filteredSelfies.isEmpty
                    ? _buildEmptyState()
                    : _buildPhotoGrid(filteredSelfies),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoGrid(List<SelfieModel> selfies) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: selfies.length,
      itemBuilder: (context, index) {
        final selfie = selfies[index];
        return _buildPhotoCard(selfie);
      },
    );
  }

  Widget _buildPhotoCard(SelfieModel selfie) {
    return GestureDetector(
      onTap: () => _showPhotoDetails(selfie),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Handle both asset and uploaded images
              _buildPhotoImage(selfie, context.watch<ImageProviderService>()),
              
              // Difficulty indicator
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: selfie.difficultyColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selfie.difficultyIcon,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        selfie.difficulty,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Photo info overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selfie.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selfie.poseType.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Photos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<ImageProviderService>().loadTestSelfies();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Photos Found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'No photos match the selected filter.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  List<SelfieModel> _getFilteredSelfies(List<SelfieModel> selfies) {
    if (_selectedFilter == 'All') {
      return selfies;
    }
    return selfies.where((selfie) => selfie.difficulty == _selectedFilter).toList();
  }

  Widget _buildPhotoImage(SelfieModel selfie, ImageProviderService imageProvider) {
    if (selfie.id.startsWith('uploaded_')) {
      // Handle uploaded images
      final imageFile = imageProvider.getImageFile(selfie.id);
      if (imageFile != null) {
        return Image.file(
          imageFile,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }
    
    // Handle asset images
    return Image.asset(
      'assets/test_selfies/${selfie.id}.jpg',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getGradientColor(selfie.id, 0),
                _getGradientColor(selfie.id, 1),
              ],
            ),
          ),
          child: Icon(
            Icons.person,
            size: 60,
            color: Colors.white.withOpacity(0.7),
          ),
        );
      },
    );
  }

  Color _getGradientColor(String id, int index) {
    // Generate consistent colors based on ID
    final hash = id.hashCode;
    final colors = [
      [Colors.purple[300]!, Colors.purple[600]!],
      [Colors.blue[300]!, Colors.blue[600]!],
      [Colors.teal[300]!, Colors.teal[600]!],
      [Colors.pink[300]!, Colors.pink[600]!],
      [Colors.indigo[300]!, Colors.indigo[600]!],
      [Colors.orange[300]!, Colors.orange[600]!],
      [Colors.green[300]!, Colors.green[600]!],
      [Colors.red[300]!, Colors.red[600]!],
    ];
    
    return colors[hash.abs() % colors.length][index];
  }

  void _showPhotoDetails(SelfieModel selfie) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildPhotoImage(selfie, context.read<ImageProviderService>()),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Photo details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selfie.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selfie.difficultyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: selfie.difficultyColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                selfie.difficultyIcon,
                                size: 16,
                                color: selfie.difficultyColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                selfie.difficulty,
                                style: TextStyle(
                                  color: selfie.difficultyColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      selfie.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildDetailRow('Pose Type', selfie.poseType.replaceAll('_', ' ').toUpperCase()),
                    _buildDetailRow('Lighting Quality', selfie.lightingQuality.toUpperCase()),
                    _buildDetailRow('Background', selfie.backgroundComplexity.toUpperCase()),
                    _buildDetailRow('Body Type', selfie.bodyType.replaceAll('_', ' ').toUpperCase()),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<ImageProviderService>().selectTestSelfie(selfie);
                          Navigator.pop(context);
                          Navigator.pop(context); // Go back to home
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Selected: ${selfie.name}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Select This Photo'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    // Add delete button for uploaded photos
                    if (selfie.id.startsWith('uploaded_')) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Photo'),
                                content: const Text('Are you sure you want to delete this photo?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      context.read<ImageProviderService>().removeUploadedPhoto(selfie.id);
                                      Navigator.pop(context); // Close dialog
                                      Navigator.pop(context); // Close photo details
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Photo deleted'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Delete Photo', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  File? _getImageFile(SelfieModel selfie) {
    final imageProvider = context.read<ImageProviderService>();
    if (selfie.id.startsWith('uploaded_')) {
      return imageProvider.getImageFile(selfie.id);
    }
    // For asset images, we'd need to copy them to a file first
    // For now, just return null for asset images
    return null;
  }
}