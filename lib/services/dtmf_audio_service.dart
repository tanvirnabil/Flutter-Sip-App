import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service providing authentic dual-tone multi-frequency (DTMF) acoustic audio feedback
/// and softphone sound generation without needing external audio asset dependencies.
class DtmfAudioService {
  static final DtmfAudioService _instance = DtmfAudioService._internal();
  factory DtmfAudioService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  final Map<String, Uint8List> _toneCache = {};
  bool _isEnabled = true;
  bool _isInitialized = false;

  static const String _prefKey = 'dtmf_tones_enabled';

  DtmfAudioService._internal();

  bool get isEnabled => _isEnabled;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_prefKey) ?? true;
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(0.4);

      // Pre-synthesize all standard DTMF tones
      const digits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '#'];
      for (final d in digits) {
        _toneCache[d] = _generateDtmfWav(d);
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('DtmfAudioService init error: $e');
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }

  Future<void> playTone(String digit) async {
    if (!_isEnabled) return;
    try {
      if (!_isInitialized) {
        await init();
      }
      final wavBytes = _toneCache[digit] ?? _generateDtmfWav(digit);
      await _player.stop();
      await _player.play(BytesSource(wavBytes));
    } catch (e) {
      debugPrint('Error playing DTMF tone: $e');
    }
  }

  /// Synthesizes ITU-T Q.23 standard dual frequency audio into standard 16-bit PCM WAV bytes
  static Uint8List _generateDtmfWav(String digit) {
    int fLow;
    int fHigh;

    switch (digit) {
      case '1':
        fLow = 697;
        fHigh = 1209;
        break;
      case '2':
        fLow = 697;
        fHigh = 1336;
        break;
      case '3':
        fLow = 697;
        fHigh = 1477;
        break;
      case '4':
        fLow = 770;
        fHigh = 1209;
        break;
      case '5':
        fLow = 770;
        fHigh = 1336;
        break;
      case '6':
        fLow = 770;
        fHigh = 1477;
        break;
      case '7':
        fLow = 852;
        fHigh = 1209;
        break;
      case '8':
        fLow = 852;
        fHigh = 1336;
        break;
      case '9':
        fLow = 852;
        fHigh = 1477;
        break;
      case '*':
        fLow = 941;
        fHigh = 1209;
        break;
      case '0':
        fLow = 941;
        fHigh = 1336;
        break;
      case '#':
        fLow = 941;
        fHigh = 1477;
        break;
      default:
        fLow = 800;
        fHigh = 1200;
        break;
    }

    const sampleRate = 8000;
    const durationMs = 120; // 120ms standard dialpad tap duration
    final totalSamples = (sampleRate * durationMs) ~/ 1000;
    final byteData = ByteData(44 + totalSamples * 2);

    // RIFF header
    _writeString(byteData, 0, 'RIFF');
    byteData.setUint32(4, 36 + totalSamples * 2, Endian.little);
    _writeString(byteData, 8, 'WAVE');

    // fmt subchunk
    _writeString(byteData, 12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little); // SubChunk1Size (16 for PCM)
    byteData.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    byteData.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
    byteData.setUint32(24, sampleRate, Endian.little); // SampleRate
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    byteData.setUint16(32, 2, Endian.little); // BlockAlign
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample

    // data subchunk
    _writeString(byteData, 36, 'data');
    byteData.setUint32(40, totalSamples * 2, Endian.little);

    // PCM Samples with gentle cosine fade in/out to eliminate click artifacts
    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final wave1 = sin(2 * pi * fLow * t);
      final wave2 = sin(2 * pi * fHigh * t);
      var sample = (wave1 + wave2) / 2.0;

      // Envelope ramp
      if (i < 40) {
        sample *= (i / 40.0);
      } else if (i > totalSamples - 40) {
        sample *= ((totalSamples - i) / 40.0);
      }

      final intSample = (sample * 24000).clamp(-32767, 32767).toInt();
      byteData.setInt16(44 + i * 2, intSample, Endian.little);
    }

    return byteData.buffer.asUint8List();
  }

  static void _writeString(ByteData byteData, int offset, String string) {
    for (int i = 0; i < string.length; i++) {
      byteData.setUint8(offset + i, string.codeUnitAt(i));
    }
  }
}
