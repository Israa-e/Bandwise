import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../domain/speaking_devices.dart';

/// Records AAC in .m4a with the record package. Permission is checked with
/// permission_handler first, so the app can explain before the system
/// prompt appears.
class RecordSpeakingRecorder implements SpeakingRecorder {
  final _recorder = AudioRecorder();

  static MicPermission _from(PermissionStatus status) => switch (status) {
    PermissionStatus.granted ||
    PermissionStatus.limited => MicPermission.granted,
    PermissionStatus.permanentlyDenied ||
    PermissionStatus.restricted => MicPermission.permanentlyDenied,
    _ => MicPermission.canAsk,
  };

  @override
  Future<MicPermission> permission() async {
    // The web has no settings to send people to; the browser asks itself.
    if (kIsWeb) {
      return await _recorder.hasPermission(request: false)
          ? MicPermission.granted
          : MicPermission.canAsk;
    }
    return _from(await Permission.microphone.status);
  }

  @override
  Future<MicPermission> requestPermission() async {
    if (kIsWeb) {
      return await _recorder.hasPermission()
          ? MicPermission.granted
          : MicPermission.canAsk;
    }
    return _from(await Permission.microphone.request());
  }

  @override
  Future<void> openSettings() => openAppSettings();

  @override
  Future<void> start(String path) async {
    // AAC everywhere it's supported; browsers without it record Opus.
    final aac = await _recorder.isEncoderSupported(AudioEncoder.aacLc);
    await _recorder.start(
      RecordConfig(
        encoder: aac ? AudioEncoder.aacLc : AudioEncoder.opus,
        bitRate: 64000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
  }

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<void> cancel() => _recorder.cancel();

  @override
  Stream<double> get amplitude => _recorder
      .onAmplitudeChanged(const Duration(milliseconds: 200))
      .map((a) => a.current);

  @override
  Future<void> dispose() => _recorder.dispose();
}
