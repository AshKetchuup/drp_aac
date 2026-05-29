import 'package:flutter/material.dart';
import '../models/models.dart';

class AACProvider extends ChangeNotifier {
  UserProfile? _currentProfile;
  List<Symbol> _sentenceBuilder = [];
  bool _isOverloadMode = false;
  String? _currentEmotion;
  bool _isProfileSetupComplete = false;

  UserProfile? get currentProfile => _currentProfile;
  List<Symbol> get sentenceBuilder => _sentenceBuilder;
  bool get isOverloadMode => _isOverloadMode;
  String? get currentEmotion => _currentEmotion;
  bool get isProfileSetupComplete => _isProfileSetupComplete;

  String get currentSentence => _sentenceBuilder.map((s) => s.label).join(' ');

  void setProfile(UserProfile profile) {
    _currentProfile = profile;
    _isProfileSetupComplete = true;
    notifyListeners();
  }

  void updateProfile(UserProfile profile) {
    _currentProfile = profile;
    notifyListeners();
  }

  void addToSentence(Symbol symbol) {
    _sentenceBuilder.add(symbol);
    notifyListeners();
  }

  void removeFromSentence(int index) {
    if (index >= 0 && index < _sentenceBuilder.length) {
      _sentenceBuilder.removeAt(index);
      notifyListeners();
    }
  }

  void removeLastFromSentence() {
    if (_sentenceBuilder.isNotEmpty) {
      _sentenceBuilder.removeLast();
      notifyListeners();
    }
  }

  void clearSentence() {
    _sentenceBuilder.clear();
    notifyListeners();
  }

  void toggleOverloadMode() {
    _isOverloadMode = !_isOverloadMode;
    notifyListeners();
  }

  void setOverloadMode(bool value) {
    _isOverloadMode = value;
    notifyListeners();
  }

  void setCurrentEmotion(String? emotion) {
    _currentEmotion = emotion;
    if (_currentProfile != null) {
      _currentProfile = _currentProfile!.copyWith(currentMood: emotion);
    }
    notifyListeners();
  }

  void resetSetup() {
    _currentProfile = null;
    _isProfileSetupComplete = false;
    _sentenceBuilder.clear();
    _isOverloadMode = false;
    _currentEmotion = null;
    notifyListeners();
  }
}
