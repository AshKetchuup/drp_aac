import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class AACProvider extends ChangeNotifier {
  UserProfile? _currentProfile = UserProfile(
    id: 'mock_may',
    name: 'Bob',
    avatarId: 'girl_1',
    likes: ['legos'],
    dislikes: ['trains'],
    createdAt: DateTime.now(),
  );
  List<Symbol> _sentenceBuilder = [];
  bool _isCalmingMode = false;
  String? _currentEmotion;
  bool _isProfileSetupComplete = true;

  // Smart Suggestions State
  bool _isListeningContext = false;
  bool _isLoadingSuggestions = false;
  String? _teacherPrompt;
  List<String> _contextSuggestions = [];

  UserProfile? get currentProfile => _currentProfile;
  List<Symbol> get sentenceBuilder => _sentenceBuilder;
  bool get isCalmingMode => _isCalmingMode;
  String? get currentEmotion => _currentEmotion;
  bool get isProfileSetupComplete => _isProfileSetupComplete;

  bool get isListeningContext => _isListeningContext;
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  String? get teacherPrompt => _teacherPrompt;
  List<String> get contextSuggestions => _contextSuggestions;

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

  void toggleCalmingMode() {
    _isCalmingMode = !_isCalmingMode;
    notifyListeners();
  }

  void setCalmingMode(bool value) {
    _isCalmingMode = value;
    notifyListeners();
  }

  void setCurrentEmotion(String? emotion) {
    _currentEmotion = emotion;
    if (_currentProfile != null) {
      _currentProfile = _currentProfile!.copyWith(currentMood: emotion);
    }
    notifyListeners();
  }

  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<void> startContextListening() async {
    PermissionStatus micStatus = await Permission.microphone.status;

    if (micStatus.isDenied) {
      micStatus = await Permission.microphone.request();
    }

    if (micStatus.isPermanentlyDenied) {
      print("Microphone permission permanently denied. Opening settings...");
      openAppSettings();
      return;
    }

    if (!micStatus.isGranted) {
      print("Microphone permission denied.");
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech Status: $status'),
      onError: (error) => print('Speech Error: $error'),
    );

    if (!available) {
      print("Speech recognition engine failed to initialize.");
      return;
    }

    _isListeningContext = true;
    _teacherPrompt = null;
    notifyListeners();

    await _speech.listen(
      onResult: (result) async {
        _teacherPrompt = result.recognizedWords;

        if (result.finalResult) {
          _isListeningContext = false;
          notifyListeners();
          await fetchSuggestions();
        } else {
          notifyListeners();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> fetchSuggestions() async {
    _isLoadingSuggestions = true;
    notifyListeners();

    try {
      // Use kIsWeb and defaultTargetPlatform to dynamically set the correct backend URL
      String apiUrl = 'https://drp-aac.onrender.com/api/context/predict'; // Default for Web/Desktop
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        apiUrl = 'http://10.0.2.2:8000/api/context/predict'; // Special IP for Android Emulator host
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'audio_base64': 'bW9jayBhdWRpbyBkYXRh',
          'text': _teacherPrompt,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _contextSuggestions = List<String>.from(data['predictions'] ?? []);
      } else {
        _contextSuggestions = ["Pizza", "Apple", "Sandwich", "Pear"]; // Fallback
      }
    } catch (e) {
      debugPrint('Error fetching predictions: $e');
      _contextSuggestions = ["Pizza", "Apple", "Sandwich", "Pasta"]; // Fallback
    } finally {
      _isLoadingSuggestions = false;
      notifyListeners();
    }
  }

  void resetContextSuggestions() {
    _contextSuggestions = [];
    _teacherPrompt = null;
    notifyListeners();
  }

  void resetSetup() {
    _currentProfile = null;
    _isProfileSetupComplete = false;
    _sentenceBuilder.clear();
    _isCalmingMode = false;
    _currentEmotion = null;
    resetContextSuggestions();
  }
}
