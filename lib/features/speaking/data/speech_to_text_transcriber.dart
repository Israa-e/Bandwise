import 'package:speech_to_text/speech_to_text.dart';

import '../domain/speaking_devices.dart';

/// The phone's speech recognition, through speech_to_text. Some phones
/// can't recognise speech while another recording is running; then the
/// transcript stays empty.
class SpeechToTextTranscriber implements SpeechTranscriber {
  final _speech = SpeechToText();
  var _text = '';

  @override
  Future<bool> start() async {
    _text = '';
    try {
      if (!await _speech.initialize()) return false;
      await _speech.listen(
        onResult: (r) => _text = r.recognizedWords,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          listenFor: const Duration(minutes: 3),
          pauseFor: const Duration(seconds: 30),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> stop() async {
    try {
      await _speech.stop();
    } catch (_) {
      // The transcript is optional; a failure leaves it empty.
    }
    return _text.trim().isEmpty ? null : _text.trim();
  }
}
