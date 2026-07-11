import 'package:flutter_tts/flutter_tts.dart';

/// Wraps text-to-speech for MediAssist. Reads content aloud for users with
/// weak eyesight — a key elderly-accessibility feature. Used manually (a speak
/// button) in both modes, and automatically by the adaptive engine when it
/// detects the user is struggling (strong adaptation level).
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45); // slow & clear, suited to elderly users
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _ready = true;
  }

  /// Speak the given text (stops any current speech first).
  Future<void> speak(String text) async {
    if (!_ready) await init();
    if (text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async => _tts.stop();
}
