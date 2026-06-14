import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/arasaac_image.dart';

class ProfileSetup extends StatefulWidget {
  final Function(UserProfile) onComplete;

  const ProfileSetup({
    super.key,
    required this.onComplete,
  });

  @override
  State<ProfileSetup> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<ProfileSetup> {
  int _currentStep = 0;
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedPronoun;
  String _selectedAvatar = 'boy_1';
  final List<String> _selectedLikes = [];
  final List<String> _selectedDislikes = [];
  String? _selectedMood;

  static const List<String> pronounOptions = ['He/Him', 'She/Her', 'They/Them', 'Other'];


  static const List<Map<String, dynamic>> avatarOptions = [
    {'id': 'boy_1', 'emoji': '👦🏻', 'color': Color(0xFF3B82F6)},
    {'id': 'boy_2', 'emoji': '👦🏼', 'color': Color(0xFF3B82F6)},
    {'id': 'boy_3', 'emoji': '👦🏽', 'color': Color(0xFF3B82F6)},
    {'id': 'boy_4', 'emoji': '👦🏿', 'color': Color(0xFF3B82F6)},
    {'id': 'girl_1', 'emoji': '👧🏻', 'color': Color(0xFFEC4899)},
    {'id': 'girl_2', 'emoji': '👧🏼', 'color': Color(0xFFEC4899)},
    {'id': 'girl_3', 'emoji': '👧🏽', 'color': Color(0xFFEC4899)},
    {'id': 'girl_4', 'emoji': '👧🏿', 'color': Color(0xFFEC4899)},
  ];

  static const List<Map<String, dynamic>> interestOptions = [
    {'id': 'minecraft', 'label': 'Minecraft', 'icon': Icons.grid_view, 'color': Color(0xFF22C55E)},
    {'id': 'roblox', 'label': 'Roblox', 'icon': Icons.videogame_asset, 'color': Color(0xFFEF4444)},
    {'id': 'youtube', 'label': 'YouTube', 'icon': Icons.play_circle, 'color': Color(0xFFEF4444)},
    {'id': 'music', 'label': 'Music', 'icon': Icons.music_note, 'color': Color(0xFFA855F7)},
    {'id': 'drawing', 'label': 'Drawing', 'icon': Icons.brush, 'color': Color(0xFF3B82F6)},
    {'id': 'animals', 'label': 'Animals', 'icon': Icons.pets, 'color': Color(0xFFF97316)},
    {'id': 'legos', 'label': 'Legos', 'icon': Icons.extension, 'color': Color(0xFFFACC15)},
    {'id': 'cars', 'label': 'Cars', 'icon': Icons.directions_car, 'color': Color(0xFF3B82F6)},
    {'id': 'dinosaurs', 'label': 'Dinosaurs', 'icon': Icons.cruelty_free, 'color': Color(0xFF22C55E)},
    {'id': 'trains', 'label': 'Trains', 'icon': Icons.train, 'color': Color(0xFF6B7280)},
    {'id': 'space', 'label': 'Space', 'icon': Icons.rocket, 'color': Color(0xFF6366F1)},
    {'id': 'cooking', 'label': 'Cooking', 'icon': Icons.restaurant, 'color': Color(0xFFEC4899)},
  ];

  static const List<Map<String, dynamic>> moodOptions = [
    {'id': 'happy', 'label': 'Happy', 'icon': Icons.sentiment_very_satisfied, 'color': Color(0xFFFACC15)},
    {'id': 'calm', 'label': 'Calm', 'icon': Icons.self_improvement, 'color': Color(0xFF22C55E)},
    {'id': 'tired', 'label': 'Tired', 'icon': Icons.bedtime, 'color': Color(0xFF6B7280)},
    {'id': 'sad', 'label': 'Sad', 'icon': Icons.sentiment_dissatisfied, 'color': Color(0xFF3B82F6)},
    {'id': 'anxious', 'label': 'Anxious', 'icon': Icons.psychology, 'color': Color(0xFFA855F7)},
    {'id': 'excited', 'label': 'Excited', 'icon': Icons.celebration, 'color': Color(0xFFF97316)},
  ];

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _completeSetup() {
    final profile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.isNotEmpty ? _nameController.text : 'User',
      age: int.tryParse(_ageController.text),
      pronoun: _selectedPronoun,
      avatarId: _selectedAvatar,
      likes: _selectedLikes,
      dislikes: _selectedDislikes,
      currentMood: _selectedMood,
      createdAt: DateTime.now(),
    );
    widget.onComplete(profile);
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _nameController.text.isNotEmpty;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            _buildHeader(),
            // Step content
            Expanded(
              child: _buildStepContent(),
            ),
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.isHighContrast
                      ? AppTheme.surfaceLight
                      : AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Your Profile',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Step ${_currentStep + 1} of 5',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.home),
                color: AppTheme.textSecondary,
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Progress bar
          Row(
            children: List.generate(5, (index) {
              final isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primary : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildAvatarStep();
      case 2:
        return _buildLikesStep();
      case 3:
        return _buildDislikesStep();
      case 4:
        return _buildMoodStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's your name?",
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This is how the app will greet you",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 20),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _ageController,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 20),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Age (optional)',
              prefixIcon: Icon(Icons.cake_outlined, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Pronouns (optional)',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: pronounOptions.map((pronoun) {
              final isSelected = _selectedPronoun == pronoun;
              return GestureDetector(
                onTap: () => setState(() => _selectedPronoun = pronoun),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (AppTheme.isHighContrast
                            ? AppTheme.surfaceLight
                            : AppTheme.primary.withValues(alpha: 0.2))
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.border,
                    ),
                  ),
                  child: Text(
                    pronoun,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick your avatar',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This will represent you in the app',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              children: avatarOptions.map((avatar) {
                final isSelected = _selectedAvatar == avatar['id'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedAvatar = avatar['id'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (AppTheme.isHighContrast
                              ? AppTheme.surfaceLight
                              : (avatar['color'] as Color).withValues(alpha: 0.2))
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? avatar['color'] as Color : AppTheme.border,
                        width: isSelected ? 3 : 1,
                      ),
                      // Glow is a low-contrast cue — the solid 3px colour
                      // border carries selection in High Contrast.
                      boxShadow: isSelected && !AppTheme.isHighContrast
                          ? [
                              BoxShadow(
                                color: (avatar['color'] as Color).withValues(alpha: 0.3),
                                blurRadius: 16,
                              ),
                            ]
                          : null,
                    ),
                    child: avatar['image'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              avatar['image'] as String,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          )
                        : avatar['emoji'] != null
                            ? Center(
                                child: Text(
                                  avatar['emoji'] as String,
                                  style: const TextStyle(fontSize: 56),
                                ),
                              )
                            : Icon(
                                avatar['icon'] as IconData,
                                size: 56,
                                color: avatar['color'] as Color,
                              ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikesStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you like?',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your favorite things (we\'ll show these more often)',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: interestOptions.length,
              itemBuilder: (context, index) {
                final interest = interestOptions[index];
                final isSelected = _selectedLikes.contains(interest['id']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedLikes.remove(interest['id']);
                      } else {
                        _selectedLikes.add(interest['id'] as String);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (AppTheme.isHighContrast
                              ? AppTheme.surfaceLight
                              : (interest['color'] as Color).withValues(alpha: 0.2))
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? interest['color'] as Color : AppTheme.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ArasaacImage(
                          keyword: interest['label'] as String,
                          fallbackIcon: interest['icon'] as IconData,
                          size: 40,
                          color: interest['color'] as Color,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          interest['label'] as String,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.check_circle,
                              size: 18,
                              color: interest['color'] as Color,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDislikesStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What don't you like?",
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll avoid showing these things",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: interestOptions.length,
              itemBuilder: (context, index) {
                final interest = interestOptions[index];
                final isSelected = _selectedDislikes.contains(interest['id']);
                final isLiked = _selectedLikes.contains(interest['id']);
                return GestureDetector(
                  onTap: isLiked ? null : () {
                    setState(() {
                      if (isSelected) {
                        _selectedDislikes.remove(interest['id']);
                      } else {
                        _selectedDislikes.add(interest['id'] as String);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isLiked
                          ? (AppTheme.isHighContrast
                              ? AppTheme.surfaceLight
                              : AppTheme.surfaceLight.withValues(alpha: 0.3))
                          : isSelected
                              ? (AppTheme.isHighContrast
                                  ? AppTheme.surfaceLight
                                  : AppTheme.error.withValues(alpha: 0.2))
                              : AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLiked
                            ? (AppTheme.isHighContrast
                                ? AppTheme.border
                                : AppTheme.border.withValues(alpha: 0.3))
                            : isSelected
                                ? AppTheme.error
                                : AppTheme.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Opacity(
                      opacity: isLiked ? 0.3 : 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ArasaacImage(
                            keyword: interest['label'] as String,
                            fallbackIcon: interest['icon'] as IconData,
                            size: 40,
                            color: isSelected ? AppTheme.error : interest['color'] as Color,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            interest['label'] as String,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Icon(
                                Icons.block,
                                size: 18,
                                color: AppTheme.error,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling?',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can always change this later',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              children: moodOptions.map((mood) {
                final isSelected = _selectedMood == mood['id'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood['id'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (AppTheme.isHighContrast
                              ? AppTheme.surfaceLight
                              : (mood['color'] as Color).withValues(alpha: 0.2))
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? mood['color'] as Color : AppTheme.border,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected && !AppTheme.isHighContrast
                          ? [
                              BoxShadow(
                                color: (mood['color'] as Color).withValues(alpha: 0.3),
                                blurRadius: 16,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ArasaacImage(
                          keyword: mood['label'] as String,
                          fallbackIcon: mood['icon'] as IconData,
                          size: 56,
                          color: mood['color'] as Color,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          mood['label'] as String,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: _canProceed ? _nextStep : null,
              icon: Icon(_currentStep == 4 ? Icons.check : Icons.arrow_forward),
              label: Text(_currentStep == 4 ? 'Start Communicating' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}
