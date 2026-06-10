import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
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

  // Settings State
  double _voicePitch = 1.0;
  double _voiceRate = 0.4;
  int? _gridColumns; // null = Auto
  ThemeMode _themeMode = ThemeMode.dark;

  double get voicePitch => _voicePitch;
  double get voiceRate => _voiceRate;
  int? get gridColumns => _gridColumns;
  ThemeMode get themeMode => _themeMode;

  void updateVoiceSettings(double pitch, double rate) {
    _voicePitch = pitch;
    _voiceRate = rate;
    _flutterTts.setPitch(_voicePitch);
    _flutterTts.setSpeechRate(_voiceRate);
    notifyListeners();
  }

  void updateGridColumns(int? columns) {
    _gridColumns = columns;
    notifyListeners();
  }

  void updateThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  AACProvider({ScheduleRepository? scheduleRepo})
    : _scheduleRepo = scheduleRepo ?? LocalScheduleRepository() {
    _initTts();
    // Preload the bundled starter board so it's the first board ready to use,
    // without taking over the rich home view.
    loadDefaultBoardSet();
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
    if (schedule[key] == null) {
      schedule[key] = [];
    }
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

  /// The bundled starter board (`assets/boards/default_board.obz`), preloaded at
  /// startup so it is the first board available to switch to. It is intentionally
  /// NOT auto-activated: the rich hardcoded home board stays the default view so
  /// no features (profile, smart suggestions, Now/Next) are lost. Call
  /// [activateDefaultBoard] to make it the active imported board.
  ImportedBoardSet? _defaultBoardSet;
  ImportedBoardSet? get defaultBoardSet => _defaultBoardSet;
  static const String _defaultBoardAsset = 'assets/boards/default_board.obz';

  /// Loads and parses the bundled default board into [defaultBoardSet] without
  /// activating it. Safe to call more than once; the asset is only parsed once.
  Future<void> loadDefaultBoardSet() async {
    if (_defaultBoardSet != null) return;
    try {
      final data = await rootBundle.load(_defaultBoardAsset);
      _defaultBoardSet = ObzParser().parseObzBytes(data.buffer.asUint8List());
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load bundled default board: $e');
    }
  }

  /// Switches the grid to the bundled default board, loading it first if needed.
  Future<void> activateDefaultBoard() async {
    await loadDefaultBoardSet();
    final boardSet = _defaultBoardSet;
    if (boardSet == null) return;
    _importedBoardSet = boardSet;
    _activeImportedBoardPath = boardSet.rootPath;
    notifyListeners();
  }



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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['obf', 'obz'],
      withData: true,
    );

    if (result == null) return;

    final file = result.files.single;

    if (file.extension?.toLowerCase() == 'obz') {
      final boardSet = ObzParser().parseObzBytes(file.bytes!);
      _importedBoardSet = boardSet;
      _activeImportedBoardPath = boardSet.rootPath;
    } else {
      final jsonText = utf8.decode(file.bytes!);
      final board = ObfParser().parseObfString(jsonText);

      _importedBoardSet = ImportedBoardSet(
        rootPath: 'board.obf',
        boardsByPath: {'board.obf': board},
        filesByPath: {},
      );
      _activeImportedBoardPath = 'board.obf';
    }

    notifyListeners();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-GN');
    await _flutterTts.setSpeechRate(_voiceRate);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(_voicePitch);
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
  final List<Symbol> _customSymbols = [];
  String? _currentEmotion;
  bool _isProfileSetupComplete = true;

  // Smart Suggestions State
  bool _isListeningContext = false;
  bool _isLoadingSuggestions = false;
  String? _teacherPrompt;
  List<String> _contextSuggestions = [];

  UserProfile? get currentProfile => _currentProfile;
  List<Symbol> get sentenceBuilder => _sentenceBuilder;
  List<Symbol> get customSymbols => _customSymbols;
  String? get currentEmotion => _currentEmotion;
  bool get isProfileSetupComplete => _isProfileSetupComplete;

  bool get isListeningContext => _isListeningContext;
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  String? get teacherPrompt => _teacherPrompt;
  List<String> get contextSuggestions => _contextSuggestions;

  String get currentSentence => _sentenceBuilder.map((s) => s.label).join(' ');

  void addCustomSymbol(Symbol symbol) {
    // Avoid duplicates by checking label
    if (!_customSymbols.any((s) => s.label.toLowerCase() == symbol.label.toLowerCase())) {
      _customSymbols.add(symbol);
      notifyListeners();
    }
  }

  void removeCustomSymbol(String id) {
    _customSymbols.removeWhere((s) => s.id == id);
    notifyListeners();
  }

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
