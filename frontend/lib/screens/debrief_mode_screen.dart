import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../providers/aac_provider.dart';
import '../models/models.dart';
import '../widgets/debrief_mode.dart';

class DebriefModeScreen extends StatefulWidget {
  const DebriefModeScreen({super.key});

  @override
  State<DebriefModeScreen> createState() => _DebriefModeScreenState();
}

class _DebriefModeScreenState extends State<DebriefModeScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.4);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
  }

  void _speak(String text) => _tts.speak(text);

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _handleSymbolTap(Symbol symbol) {
    final provider = Provider.of<AACProvider>(context, listen: false);
    provider.addToSentence(symbol);
  }

  void _handleSpeak() {
    final provider = Provider.of<AACProvider>(context, listen: false);
    _speak(provider.currentSentence);
  }

  void _handleClear() {
    Provider.of<AACProvider>(context, listen: false).clearSentence();
  }

  @override
  Widget build(BuildContext context) {
    return DebriefMode(
      onSymbolTap: _handleSymbolTap,
      onEmotionTap: _speak,
      onSpeak: _handleSpeak,
      onClear: _handleClear,
    );
  }
}
