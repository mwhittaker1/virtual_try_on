// flutter_app/lib/screens/segmentation_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/image_provider.dart';

class SegmentationScreen extends StatefulWidget {
  final File imageFile;
  
  const SegmentationScreen({
    super.key,
    required this.imageFile,
  });

  @override
  State<SegmentationScreen> createState() => _SegmentationScreenState();
}

class _SegmentationScreenState extends State<SegmentationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImageProviderService>().segmentImageFile(widget.imageFile);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clothing Detection'),
        centerTitle: true,
      ),
      body: Consumer<ImageProviderService>(
        builder: (context, imageProvider, child) {
          if (imageProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing clothing items...'),
                ],
              ),
            );
          }

          if (imageProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${imageProvider.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => imageProvider.segmentImageFile(widget.imageFile),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return _buildResults(imageProvider.segmentationResult);
        },
      ),
    );
  }

  Widget _buildResults(Map<String, dynamic>? segmentationResult) {
    if (segmentationResult == null) {
      return const Center(child: Text('No segmentation results'));
    }

    final segmentation = segmentationResult['segmentation'];
    final detectedItems = segmentation['detected_items'] as List<dynamic>;
    final imageInfo = segmentationResult['image_info'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original Image
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Detection Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.blue, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Detection Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text('Found ${detectedItems.length} clothing items'),
                Text('Image size: ${imageInfo['width']} × ${imageInfo['height']}'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Detected Items List
          Text(
            'Detected Clothing Items',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          ...detectedItems.map<Widget>((item) => _buildClothingItemCard(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildClothingItemCard(Map<String, dynamic> item) {
    final category = item['category'] as String;
    final coverage = item['coverage'] as double;
    final pixelCount = item['pixel_count'] as int;
    
    // Get category color and icon
    final categoryInfo = _getCategoryInfo(category);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: categoryInfo['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: categoryInfo['color'].withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: categoryInfo['color'].withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              categoryInfo['icon'],
              color: categoryInfo['color'],
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCategoryName(category),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Coverage: ${(coverage * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  'Pixels: ${_formatNumber(pixelCount)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          
          // Coverage indicator
          Container(
            width: 60,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: coverage,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: categoryInfo['color'],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCategoryInfo(String category) {
    switch (category.toLowerCase()) {
      case 'upper-clothes':
        return {'color': Colors.blue, 'icon': Icons.checkroom};
      case 'pants':
        return {'color': Colors.green, 'icon': Icons.content_cut};
      case 'dress':
        return {'color': Colors.pink, 'icon': Icons.checkroom};
      case 'hat':
        return {'color': Colors.orange, 'icon': Icons.sports_baseball};
      case 'face':
        return {'color': Colors.amber, 'icon': Icons.face};
      case 'bag':
        return {'color': Colors.brown, 'icon': Icons.shopping_bag};
      case 'belt':
        return {'color': Colors.grey, 'icon': Icons.horizontal_rule};
      default:
        return {'color': Colors.purple, 'icon': Icons.category};
    }
  }

  String _formatCategoryName(String category) {
    return category
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}