import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallRecordingService {
  static final CallRecordingService _instance = CallRecordingService._internal();
  factory CallRecordingService() => _instance;

  final AudioRecorder _recorder = AudioRecorder();
  bool _isAutoRecordEnabled = false;
  bool _isRecording = false;
  String? _currentRecordingPath;

  static const String _prefKey = 'auto_call_recording_enabled';

  CallRecordingService._internal();

  bool get isAutoRecordEnabled => _isAutoRecordEnabled;
  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAutoRecordEnabled = prefs.getBool(_prefKey) ?? false;
    } catch (_) {}
  }

  Future<void> setAutoRecordEnabled(bool enabled) async {
    _isAutoRecordEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } catch (_) {}
  }

  Future<String?> startRecording(String callId, String remoteNumber) async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('Microphone permission not granted for recording');
        return null;
      }

      final dir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${dir.path}/recordings');
      if (!recordingsDir.existsSync()) {
        recordingsDir.createSync(recursive: true);
      }

      final cleanNumber = remoteNumber.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '_');
      final fileName = 'call_${DateTime.now().millisecondsSinceEpoch}_$cleanNumber.m4a';
      final filePath = '${recordingsDir.path}/$fileName';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      _isRecording = true;
      _currentRecordingPath = filePath;
      debugPrint('Call recording started: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error starting call recording: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (await _recorder.isRecording()) {
        final path = await _recorder.stop();
        _isRecording = false;
        final saved = path ?? _currentRecordingPath;
        _currentRecordingPath = null;
        debugPrint('Call recording stopped and saved to: $saved');
        return saved;
      }
    } catch (e) {
      debugPrint('Error stopping call recording: $e');
    }
    _isRecording = false;
    _currentRecordingPath = null;
    return null;
  }

  Future<void> deleteRecordingFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Successfully deleted recording file: $filePath');
      }
    } catch (e) {
      debugPrint('Error deleting recording file: $e');
    }
  }
}
