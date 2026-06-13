import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
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
import '../repositories/synced_schedule_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/tile_repository.dart';
import '../repositories/board_repository.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/kpi_logger.dart';

class AACProvider extends ChangeNotifier {
  final ScheduleRepository _scheduleRepo;
  final ProfileRepository _profileRepo;
  final TileRepository _tileRepo;
  final BoardRepository _boardRepo;

  // Settings State
  double _voicePitch = 1.0;
  double _voiceRate = 0.4;
  int? _gridColumns; // null = Auto
  bool _highContrast = false; // false = default Dark theme, true = High Contrast

  double get voicePitch => _voicePitch;
  double get voiceRate => _voiceRate;
  int? get gridColumns => _gridColumns;
  bool get highContrast => _highContrast;

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

  void setHighContrast(bool enabled) {
    _highContrast = enabled;
    notifyListeners();
  }

  AACProvider({
    ScheduleRepository? scheduleRepo,
    ProfileRepository? profileRepo,
    TileRepository? tileRepo,
    BoardRepository? boardRepo,
  }) : _scheduleRepo = scheduleRepo ?? SyncedScheduleRepository(),
       _profileRepo = profileRepo ?? ProfileRepository(),
       _tileRepo = tileRepo ?? TileRepository(),
       _boardRepo = boardRepo ?? BoardRepository() {
    _initTts();
    // Preload the bundled starter board so it's the first board ready to use,
    // without taking over the rich home view.
    loadDefaultBoardSet();
    // Decide the opening screen: if a token is already stored, load the
    // account's profiles; otherwise land on the welcome/login screen.
    refreshSession();
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

  // Boards saved remotely (raw bytes in GridFS) for the active profile.
  List<BoardMeta> _savedBoards = [];
  List<BoardMeta> get savedBoards => List.unmodifiable(_savedBoards);

  Future<void> importBoard() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['obf', 'obz'],
    );

    if (result == null) return;

    final file = result.files.single;
    // Stream the picked file's bytes rather than calling readAsBytes(): the
    // latter throws when the data isn't already in memory (e.g. on web, where
    // there is no fetchable file path), whereas the stream reads the bytes on
    // every platform.
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.readAsByteStream()) {
      builder.add(chunk);
    }
    final bytes = builder.toBytes();
    final ext = file.extension?.toLowerCase();

    _applyBoardBytes(bytes, ext);
    notifyListeners();

    // Save the imported board to the active child profile (best-effort).
    final pid = _currentProfile?.id;
    if (pid != null) {
      try {
        await _boardRepo.upload(
          pid,
          filename: file.name,
          bytes: bytes,
          name: file.name,
          contentType: ext == 'obz' ? 'application/zip' : 'application/json',
        );
        await loadSavedBoards();
      } catch (e) {
        debugPrint('Failed to upload board: $e');
      }
    }
  }

  /// Parse raw board bytes (.obz or .obf) into the active imported board set.
  void _applyBoardBytes(Uint8List bytes, String? ext) {
    if (ext == 'obz') {
      final boardSet = ObzParser().parseObzBytes(bytes);
      _importedBoardSet = boardSet;
      _activeImportedBoardPath = boardSet.rootPath;
    } else {
      final jsonText = utf8.decode(bytes);
      final board = ObfParser().parseObfString(jsonText);

      _importedBoardSet = ImportedBoardSet(
        rootPath: 'board.obf',
        boardsByPath: {'board.obf': board},
        filesByPath: {},
      );
      _activeImportedBoardPath = 'board.obf';
    }
  }

  /// Refresh the list of boards saved remotely for the active profile.
  Future<void> loadSavedBoards() async {
    final pid = _currentProfile?.id;
    if (pid == null) {
      _savedBoards = [];
      return;
    }
    try {
      _savedBoards = await _boardRepo.list(pid);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to list saved boards: $e');
    }
  }

  /// Download a saved board's bytes from the backend and make it the active board.
  Future<void> openSavedBoard(String boardId) async {
    final pid = _currentProfile?.id;
    if (pid == null) return;
    final idx = _savedBoards.indexWhere((b) => b.boardId == boardId);
    if (idx < 0) return;
    final meta = _savedBoards[idx];
    final bytes = await _boardRepo.download(pid, boardId);
    final ext = meta.filename.toLowerCase().endsWith('.obz') ? 'obz' : 'obf';
    _applyBoardBytes(bytes, ext);
    notifyListeners();
  }

  /// Delete a saved board (metadata + GridFS bytes) for the active profile.
  Future<void> deleteSavedBoard(String boardId) async {
    final pid = _currentProfile?.id;
    if (pid == null) return;
    try {
      await _boardRepo.deleteBoard(pid, boardId);
    } catch (e) {
      debugPrint('Failed to delete saved board: $e');
    }
    _savedBoards.removeWhere((b) => b.boardId == boardId);
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

  // Child profiles for the signed-in teacher account. The active profile owns
  // the tiles, schedule and saved boards currently shown.
  List<UserProfile> _profiles = [];
  UserProfile? _currentProfile;
  bool _bootstrapping = true;
  bool _loggedIn = false;
  bool _demoMode = false;
  final List<Symbol> _sentenceBuilder = [];
  final List<Symbol> _customSymbols = [];
  String? _currentEmotion;
  bool _isProfileSetupComplete = false;

  // Smart Suggestions State
  bool _isListeningContext = false;
  bool _isLoadingSuggestions = false;
  String? _teacherPrompt;
  List<String> _contextSuggestions = [];
  bool _authRequired = false;

  UserProfile? get currentProfile => _currentProfile;
  List<UserProfile> get profiles => List.unmodifiable(_profiles);
  String? get activeProfileId => _currentProfile?.id;
  bool get bootstrapping => _bootstrapping;
  bool get loggedIn => _loggedIn;
  bool get demoMode => _demoMode;
  List<Symbol> get sentenceBuilder => _sentenceBuilder;
  List<Symbol> get customSymbols => _customSymbols;
  String? get currentEmotion => _currentEmotion;
  bool get isProfileSetupComplete => _isProfileSetupComplete;

  bool get isListeningContext => _isListeningContext;
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  String? get teacherPrompt => _teacherPrompt;
  List<String> get contextSuggestions => _contextSuggestions;
  bool get authRequired => _authRequired;

  String get currentSentence => _sentenceBuilder.map((s) => s.label).join(' ');

  Future<void> addCustomSymbol(Symbol symbol) async {
    // Avoid duplicates by checking label
    if (!_customSymbols.any((s) => s.label.toLowerCase() == symbol.label.toLowerCase())) {
      _customSymbols.add(symbol);
      notifyListeners();
      // Persist to the active child profile (best-effort; cached locally too).
      final pid = _currentProfile?.id;
      if (pid != null) {
        try {
          await _tileRepo.save(pid, symbol);
        } catch (e) {
          debugPrint('Failed to save custom tile: $e');
        }
      }
    }
  }

  // ── Session (welcome / login / demo) ───────────────────────────────────
  /// Determine the opening screen. If a token is stored, pull the account's
  /// profiles from the backend; otherwise leave the app signed-out so the
  /// welcome/login screen is shown. Call again after a login completes.
  Future<void> refreshSession() async {
    _bootstrapping = true;
    notifyListeners();
    _loggedIn = await AuthService().isLoggedIn();
    if (_loggedIn) {
      _demoMode = false;
      await bootstrapProfiles();
    } else {
      _bootstrapping = false;
      notifyListeners();
    }
  }

  /// Sign out: clear the token and all profile-scoped state so the app returns
  /// to the welcome/login screen.
  Future<void> logoutSession() async {
    await AuthService().logout();
    _loggedIn = false;
    _demoMode = false;
    _profiles = [];
    _currentProfile = null;
    _isProfileSetupComplete = false;
    _customSymbols.clear();
    _savedBoards = [];
    schedule = {};
    _scheduleLoaded = false;
    notifyListeners();
  }

  /// Explore the app without signing in, using a built-in default child profile.
  /// Its tiles/schedule/boards are kept in the local cache (remote sync is
  /// unavailable while signed out, so those writes simply stay local).
  Future<void> useDemoProfile() async {
    _demoMode = true;
    final demo = UserProfile(
      id: 'demo_profile',
      name: 'Demo',
      avatarId: 'boy_1',
      likes: const ['legos', 'dinosaurs'],
      dislikes: const ['loud noises'],
      createdAt: DateTime.now(),
    );
    if (!_profiles.any((p) => p.id == demo.id)) {
      _profiles = [..._profiles, demo];
    }
    await _activateProfile(demo);
  }

  // ── Profiles (remote-backed, per teacher account) ──────────────────────
  /// Load the teacher's child profiles and activate the first one. Called at
  /// startup and again after login so a freshly-authenticated session pulls the
  /// account's profiles from the backend.
  Future<void> bootstrapProfiles() async {
    _bootstrapping = true;
    notifyListeners();
    try {
      _profiles = await _profileRepo.load();
    } on ApiException catch (e) {
      if (e.authRequired) {
        // We had a token but the backend rejected it (expired/revoked). Clear
        // it and return to the welcome/login screen rather than pretending the
        // account simply has no profiles.
        debugPrint('Stored token rejected ($e); signing out.');
        _bootstrapping = false;
        await logoutSession();
        return;
      }
      debugPrint('Failed to load profiles: $e');
      _profiles = [];
    } catch (e) {
      debugPrint('Failed to load profiles: $e');
      _profiles = [];
    }
    if (_profiles.isNotEmpty) {
      await _activateProfile(_profiles.first);
    } else {
      _currentProfile = null;
      _isProfileSetupComplete = false;
    }
    _bootstrapping = false;
    notifyListeners();
  }

  /// Make [profile] active and (re)load its tiles, schedule and saved boards.
  Future<void> _activateProfile(UserProfile profile) async {
    _currentProfile = profile;
    _isProfileSetupComplete = true;
    _currentEmotion = profile.currentMood;

    final repo = _scheduleRepo;
    if (repo is SyncedScheduleRepository) {
      repo.profileId = profile.id;
    }
    _scheduleLoaded = false;
    await loadSchedule();
    await _loadTiles();
    await loadSavedBoards();
    notifyListeners();
  }

  Future<void> _loadTiles() async {
    final pid = _currentProfile?.id;
    _customSymbols.clear();
    if (pid == null) return;
    try {
      _customSymbols.addAll(await _tileRepo.load(pid));
    } catch (e) {
      debugPrint('Failed to load custom tiles: $e');
    }
  }

  /// Create or update a child profile, persist it, and make it active. Used by
  /// the setup wizard (new child) and profile editing.
  Future<void> setProfile(UserProfile profile) async {
    final idx = _profiles.indexWhere((p) => p.id == profile.id);
    if (idx >= 0) {
      _profiles[idx] = profile;
    } else {
      _profiles.add(profile);
    }
    try {
      await _profileRepo.save(profile);
    } catch (e) {
      debugPrint('Failed to save profile: $e');
    }
    await _activateProfile(profile);
  }

  /// Switch the active child to an existing profile.
  Future<void> selectProfile(String profileId) async {
    final idx = _profiles.indexWhere((p) => p.id == profileId);
    if (idx < 0) return;
    await _activateProfile(_profiles[idx]);
  }

  /// Delete a child profile (and, on the backend, its tiles/schedule/boards).
  Future<void> deleteProfile(String profileId) async {
    _profiles.removeWhere((p) => p.id == profileId);
    try {
      await _profileRepo.delete(profileId);
    } catch (e) {
      debugPrint('Failed to delete profile: $e');
    }
    if (_currentProfile?.id == profileId) {
      if (_profiles.isNotEmpty) {
        await _activateProfile(_profiles.first);
      } else {
        _currentProfile = null;
        _isProfileSetupComplete = false;
        _customSymbols.clear();
        _savedBoards = [];
        schedule = {};
        _scheduleLoaded = false;
      }
    }
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
          debugPrint(
            "Microphone permission permanently denied. Opening settings...",
          );
          openAppSettings();
          return;
        }

        if (!micStatus.isGranted) {
          debugPrint("Microphone permission denied.");
          return;
        }
      } catch (e) {
        debugPrint("Permission check skipped: $e");
      }
    }

    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('Speech Status: $status'),
      onError: (error) => debugPrint('Speech Error: $error'),
    );

    if (!available) {
      debugPrint("Speech recognition engine failed to initialize.");
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
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(minutes: 10), // Effectively unlimited
        pauseFor: const Duration(minutes: 10), // Don't auto-stop on silence
      ),
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

  Future<void> fetchSuggestions({bool append = false}) async {
    _isLoadingSuggestions = true;
    _authRequired = false; // Reset auth flag
    notifyListeners();

    try {
      // Use kIsWeb and defaultTargetPlatform to dynamically set the correct backend URL
      // On web, the browser is on Windows but the backend is in WSL — use the WSL IP
      String apiUrl = 'https://api.ismailmehmood.co.uk/api/context/predict';

      final token = await AuthService().getAccessToken();

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final likes = _currentProfile?.likes ?? [];
      final dislikes = _currentProfile?.dislikes ?? [];

      final stopwatch = Stopwatch()..start();
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode({
          'text': _teacherPrompt ?? '',
          'likes': likes,
          'dislikes': dislikes,
          'current_suggestions': append ? _contextSuggestions : [],
        }),
      );
      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newSuggestions = List<String>.from(data['predictions'] ?? []);
        if (append) {
          // Build a new list (rather than mutating in place) so the
          // suggestions widget sees a changed reference and re-runs its
          // ARASAAC icon fetch for the newly appended words.
          _contextSuggestions = [..._contextSuggestions, ...newSuggestions];
        } else {
          _contextSuggestions = newSuggestions;
        }
        // Measure KPIs from this real fetch (no token harness needed).
        unawaited(KpiLogger.instance.logFetch(
          prompt: _teacherPrompt ?? '',
          suggestions: newSuggestions,
          likes: List<String>.from(likes),
          dislikes: List<String>.from(dislikes),
          latencyMs: stopwatch.elapsedMilliseconds,
        ));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // User is not authenticated — signal to the UI
        _authRequired = true;
        _contextSuggestions = [];
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
