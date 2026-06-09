import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:frontend/services/obf/obf_parser.dart';
import 'package:frontend/services/obf/obz_parser.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import '../models/models.dart';
import '../widgets/scheduler.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/local_schedule_repository.dart';

class AACProvider extends ChangeNotifier {
  final ScheduleRepository _scheduleRepo;

  AACProvider({ScheduleRepository? scheduleRepo})
    : _scheduleRepo = scheduleRepo ?? LocalScheduleRepository() {
    _initTts();
  }

  ({Symbol? now, Symbol? next}) calculateNowNext() {
    final hour = DateTime.now().hour;
    
    // Determine current slot
    TimeSlot currentSlot = TimeSlot.evening;
    if (hour >= 5 && hour < 12) currentSlot = TimeSlot.morning;
    if (hour >= 12 && hour < 18) currentSlot = TimeSlot.afternoon;

    // Get current weekday index (0 = Monday, 6 = Sunday)
    final dayIndex = DateTime.now().weekday - 1;
    final currentList = schedule[(dayIndex, currentSlot)] ?? [];

    Symbol? nowSymbol;
    Symbol? nextSymbol;

    if (currentList.isNotEmpty) {
      nowSymbol = currentList[0];
      nextSymbol = currentList.length > 1 
          ? currentList[1] 
          : _getNextSlotFirstSymbol(dayIndex, currentSlot);
    } else {
      nowSymbol = _getNextSlotFirstSymbol(dayIndex, currentSlot);
      if (nowSymbol != null && currentSlot == TimeSlot.morning) {
        nextSymbol = schedule[(dayIndex, TimeSlot.afternoon)]?.firstOrNull; 
      }
    }
    return (now: nowSymbol, next: nextSymbol);
  }

  // Private helper used internally by the provider calculator
  Symbol? _getNextSlotFirstSymbol(int day, TimeSlot current) {
    if (current == TimeSlot.morning) return schedule[(day, TimeSlot.afternoon)]?.firstOrNull;
    if (current == TimeSlot.afternoon) return schedule[(day, TimeSlot.evening)]?.firstOrNull;
    return null;
  }

  Map<SlotKey, List<Symbol>> schedule = {};
  bool _scheduleLoaded = false;

  Future<void> loadSchedule() async {
    if (_scheduleLoaded) return;
    schedule = await _scheduleRepo.load();
    _scheduleLoaded = true;
    notifyListeners();
  }

  Future<void> addToSchedule(SlotKey key, Symbol symbol) async {
    schedule[key]!.add(symbol);
    notifyListeners();
    await _scheduleRepo.save(schedule);
  }

  Future<void> removeFromSchedule(SlotKey key, int index) async {
    schedule[key]!.removeAt(index);
    notifyListeners();
    await _scheduleRepo.save(schedule);
  }

  Future<void> clearSchedule() async {
    for (final key in schedule.keys) {
      schedule[key]!.clear();
    }
    notifyListeners();
    await _scheduleRepo.clear();
  }

  final FlutterTts _flutterTts = FlutterTts();
  ImportedBoardSet? _importedBoardSet;
  String? _activeImportedBoardPath;

  ImportedBoardSet? get importedBoardSet => _importedBoardSet;
  String? get activeImportedBoardPath => _activeImportedBoardPath;

  void setImportedBoardSet(ImportedBoardSet boardSet) {
    _importedBoardSet = boardSet;
    _activeImportedBoardPath = boardSet.rootPath;
    notifyListeners();
  }

  void setActiveImportedBoard(String path) {
    _activeImportedBoardPath = path;
    notifyListeners();
  }

  void clearImportedBoardSet() {
    _importedBoardSet = null;
    _activeImportedBoardPath = null;
    notifyListeners();
  }

  Future<void> importBoard() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['obf', 'obz'],
    );

    if (result == null) return;

    final file = File(result.files.single.path!);

    if (file.path.toLowerCase().endsWith('.obz')) {
      final boardSet = await ObzParser().parseObzFile(file);

      _importedBoardSet = boardSet;
      _activeImportedBoardPath = boardSet.rootPath;
    } else {
      final text = await file.readAsString();
      final board = ObfParser().parseObfString(text);

      _importedBoardSet = ImportedBoardSet(
        rootPath: 'root',
        boardsByPath: {'root': board},
        filesByPath: {},
      );

      _activeImportedBoardPath = 'root';
    }

    notifyListeners();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-GN');
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  UserProfile? _currentProfile = UserProfile(
    id: 'mock_may',
    name: 'Bob',
    avatarId: 'girl_1',
    likes: ['legos'],
    dislikes: ['trains'],
    createdAt: DateTime.now(),
  );
  final List<Symbol> _sentenceBuilder = [];
  String? _currentEmotion;
  bool _isProfileSetupComplete = true;

  // Smart Suggestions State
  bool _isListeningContext = false;
  bool _isLoadingSuggestions = false;
  String? _teacherPrompt;
  List<String> _contextSuggestions = [];

  UserProfile? get currentProfile => _currentProfile;
  List<Symbol> get sentenceBuilder => _sentenceBuilder;
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

  void setCurrentEmotion(String? emotion) {
    _currentEmotion = emotion;
    if (_currentProfile != null) {
      _currentProfile = _currentProfile!.copyWith(currentMood: emotion);
    }
    notifyListeners();
  }

  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<void> startContextListening() async {
    // If already listening, stop instead (toggle behavior)
    if (_isListeningContext) {
      await stopContextListening();
      return;
    }

    // permission_handler doesn't support web; browsers handle mic permissions natively
    if (!kIsWeb) {
      try {
        PermissionStatus micStatus = await Permission.microphone.status;

        if (micStatus.isDenied) {
          micStatus = await Permission.microphone.request();
        }

        if (micStatus.isPermanentlyDenied) {
          print(
            "Microphone permission permanently denied. Opening settings...",
          );
          openAppSettings();
          return;
        }

        if (!micStatus.isGranted) {
          print("Microphone permission denied.");
          return;
        }
      } catch (e) {
        print("Permission check skipped: $e");
      }
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
      onResult: (result) {
        _teacherPrompt = result.recognizedWords;
        notifyListeners();
      },
      listenFor: const Duration(minutes: 10), // Effectively unlimited
      pauseFor: const Duration(minutes: 10), // Don't auto-stop on silence
    );
  }

  Future<void> stopContextListening() async {
    await _speech.stop();
    _isListeningContext = false;
    notifyListeners();

    // Only fetch suggestions if we actually heard something
    if (_teacherPrompt != null && _teacherPrompt!.isNotEmpty) {
      await fetchSuggestions();
    }
  }

  Future<void> fetchSuggestions() async {
    _isLoadingSuggestions = true;
    notifyListeners();

    try {
      // Use kIsWeb and defaultTargetPlatform to dynamically set the correct backend URL
      // On web, the browser is on Windows but the backend is in WSL — use the WSL IP
      String apiUrl = 'https://api.ismailmehmood.co.uk/api/context/predict';
      // if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      //   apiUrl = 'http://10.0.2.2:8000/api/context/predict'; // Special IP for Android Emulator host
      // }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'audio_base64': 'bW9jayBhdWRpbyBkYXRh',
          'text': _teacherPrompt ?? '',
          'likes': _currentProfile?.likes ?? [],
          'dislikes': _currentProfile?.dislikes ?? [],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _contextSuggestions = List<String>.from(data['predictions'] ?? []);
      } else {
        _contextSuggestions = [
          "Pizza",
          "Apple",
          "Sandwich",
          "Pear",
        ]; // Fallback
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
    _currentEmotion = null;
    resetContextSuggestions();
  }
}
