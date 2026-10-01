import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RingtoneOption {
  final String id;
  final String title;
  final String subtitle;

  const RingtoneOption({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

class RingtoneService {
  static final RingtoneService _instance = RingtoneService._internal();
  factory RingtoneService() => _instance;

  final AudioPlayer _previewPlayer = AudioPlayer();
  String _selectedRingtoneId = 'aura_chime';
  bool _isPlayingPreview = false;
  String? _currentlyPlayingId;

  static const String _prefKey = 'selected_ringtone_id';

  static const List<RingtoneOption> availableRingtones = [
    RingtoneOption(
      id: 'aura_chime',
      title: 'Aura Modern Chime',
      subtitle: 'Apple-inspired melodic soft chord (Default)',
    ),
    RingtoneOption(
      id: 'pbx_bell',
      title: 'Classic PBX Bell',
      subtitle: 'Traditional dual-tone enterprise deskphone bell',
    ),
    RingtoneOption(
      id: 'digital_radar',
      title: 'Digital Radar Pulse',
      subtitle: 'Modern high-tech ascending frequency pulse',
    ),
    RingtoneOption(
      id: 'subtle_pulse',
      title: 'Minimalist Harmonic',
      subtitle: 'Soft, ambient acoustic vibration',
    ),
    RingtoneOption(
      id: 'system_default',
      title: 'Device System Ringtone',
      subtitle: 'Standard Android / iOS default ringtone',
    ),
  ];

  RingtoneService._internal();

  String get selectedRingtoneId => _selectedRingtoneId;
  bool get isPlayingPreview => _isPlayingPreview;
  String? get currentlyPlayingId => _currentlyPlayingId;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedRingtoneId = prefs.getString(_prefKey) ?? 'aura_chime';
      await _previewPlayer.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      debugPrint('RingtoneService init error: $e');
    }
  }

  Future<void> selectRingtone(String id) async {
    _selectedRingtoneId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, id);
  }

  Future<void> previewRingtone(String id, {VoidCallback? onStateChanged}) async {
    try {
      if (_isPlayingPreview && _currentlyPlayingId == id) {
        await stopPreview();
        onStateChanged?.call();
        return;
      }

      await _previewPlayer.stop();
      _currentlyPlayingId = id;
      _isPlayingPreview = true;
      onStateChanged?.call();

      if (id == 'system_default') {
        // System tone simulation
        final bytes = _generateRingtoneWav(id);
        await _previewPlayer.play(BytesSource(bytes));
      } else {
        final bytes = _generateRingtoneWav(id);
        await _previewPlayer.play(BytesSource(bytes));
      }

      _previewPlayer.onPlayerComplete.listen((_) {
        _isPlayingPreview = false;
        _currentlyPlayingId = null;
        onStateChanged?.call();
      });
    } catch (e) {
      debugPrint('Error previewing ringtone: $e');
      _isPlayingPreview = false;
      _currentlyPlayingId = null;
      onStateChanged?.call();
    }
  }

  Future<void> stopPreview() async {
    try {
      await _previewPlayer.stop();
    } catch (_) {}
    _isPlayingPreview = false;
    _currentlyPlayingId = null;
  }

  /// Synthesizes harmonious multi-tone ringtones into PCM WAV
  Uint8List _generateRingtoneWav(String ringtoneId) {
    const sampleRate = 16000;
    const durationSeconds = 3.0; // 3 seconds sample
    final totalSamples = (sampleRate * durationSeconds).toInt();
    final byteData = ByteData(44 + totalSamples * 2);

    _writeString(byteData, 0, 'RIFF');
    byteData.setUint32(4, 36 + totalSamples * 2, Endian.little);
    _writeString(byteData, 8, 'WAVE');

    _writeString(byteData, 12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little); // PCM
    byteData.setUint16(22, 1, Endian.little); // Mono
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);

    _writeString(byteData, 36, 'data');
    byteData.setUint32(40, totalSamples * 2, Endian.little);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      double sample = 0.0;

      if (ringtoneId == 'aura_chime') {
        // Melodic arpeggio: C5 (523Hz), E5 (659Hz), G5 (784Hz), B5 (987Hz)
        final noteIndex = ((t * 4) % 4).toInt();
        final freq = [523.25, 659.25, 783.99, 987.77][noteIndex];
        final noteT = (t * 4) % 1.0;
        final env = exp(-noteT * 3.5);
        sample = (sin(2 * pi * freq * t) + 0.3 * sin(4 * pi * freq * t)) * env * 0.7;
      } else if (ringtoneId == 'pbx_bell') {
        // Dual Bell resonance: 440Hz + 480Hz modulated at 20Hz
        final tremolo = 0.5 + 0.5 * sin(2 * pi * 20 * t);
        final base = sin(2 * pi * 440 * t) + sin(2 * pi * 480 * t);
        sample = base * tremolo * 0.5;
      } else if (ringtoneId == 'digital_radar') {
        // Frequency sweep pulse
        final pulseT = t % 0.6;
        final freq = 600 + pulseT * 1200;
        final env = exp(-pulseT * 4.0);
        sample = sin(2 * pi * freq * t) * env * 0.7;
      } else {
        // Subtle harmonic
        final cycleT = t % 1.0;
        final env = sin(pi * cycleT);
        sample = (sin(2 * pi * 432 * t) + 0.5 * sin(2 * pi * 864 * t)) * env * 0.5;
      }

      final intSample = (sample * 24000).clamp(-32767, 32767).toInt();
      byteData.setInt16(44 + i * 2, intSample, Endian.little);
    }

    return byteData.buffer.asUint8List();
  }

  void _writeString(ByteData byteData, int offset, String string) {
    for (int i = 0; i < string.length; i++) {
      byteData.setUint8(offset + i, string.codeUnitAt(i));
    }
  }
}
