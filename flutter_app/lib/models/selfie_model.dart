class SelfieModel {
  final String id;
  final String name;
  final String difficulty;
  final String poseType;
  final String lightingQuality;
  final String backgroundComplexity;
  final String bodyType;
  final String description;

  SelfieModel({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.poseType,
    required this.lightingQuality,
    required this.backgroundComplexity,
    required this.bodyType,
    required this.description,
  });

  factory SelfieModel.fromJson(Map<String, dynamic> json) {
    return SelfieModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      difficulty: json['difficulty'] ?? '',
      poseType: json['pose_type'] ?? '',
      lightingQuality: json['lighting_quality'] ?? '',
      backgroundComplexity: json['background_complexity'] ?? '',
      bodyType: json['body_type'] ?? '',
      description: json['description'] ?? '',
    );
  }

  bool get isIdeal => difficulty.toLowerCase() == 'ideal';
  bool get isChallenging => difficulty.toLowerCase() == 'challenging';

  Color get difficultyColor {
    switch (difficulty.toLowerCase()) {
      case 'ideal':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'challenging':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get difficultyIcon {
    switch (difficulty.toLowerCase()) {
      case 'ideal':
        return Icons.check_circle;
      case 'moderate':
        return Icons.warning;
      case 'challenging':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}
