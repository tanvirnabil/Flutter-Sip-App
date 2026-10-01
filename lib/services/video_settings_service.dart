import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoSettingsService {
  static final VideoSettingsService _instance = VideoSettingsService._internal();
  factory VideoSettingsService() => _instance;

  bool _isVideoEnabled = true;
  String _preferredCodec = 'VP8 (WebRTC Standard)';
  String _resolution = '720p HD (1280x720)';
  String _defaultCamera = 'Front Camera';

  static const String _prefEnabled = 'video_call_enabled';
  static const String _prefCodec = 'video_codec_preferred';
  static const String _prefRes = 'video_resolution';
  static const String _prefCam = 'video_default_camera';

  static const List<String> availableCodecs = [
    'VP8 (WebRTC Standard)',
    'H.264 (Hardware Accelerated)',
    'VP9 (High Efficiency)',
    'AV1 (Next-Gen Open)',
  ];

  static const List<String> availableResolutions = [
    '720p HD (1280x720)',
    '480p SD (640x480 - Data Saver)',
    '1080p FHD (1920x1080)',
  ];

  static const List<String> availableCameras = [
    'Front Camera',
    'Back Camera',
  ];

  VideoSettingsService._internal();

  bool get isVideoEnabled => _isVideoEnabled;
  String get preferredCodec => _preferredCodec;
  String get resolution => _resolution;
  String get defaultCamera => _defaultCamera;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVideoEnabled = prefs.getBool(_prefEnabled) ?? true;
      _preferredCodec = prefs.getString(_prefCodec) ?? 'VP8 (WebRTC Standard)';
      _resolution = prefs.getString(_prefRes) ?? '720p HD (1280x720)';
      _defaultCamera = prefs.getString(_prefCam) ?? 'Front Camera';
    } catch (e) {
      debugPrint('VideoSettingsService init error: $e');
    }
  }

  Future<void> setVideoEnabled(bool enabled) async {
    _isVideoEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, enabled);
  }

  Future<void> setPreferredCodec(String codec) async {
    _preferredCodec = codec;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefCodec, codec);
  }

  Future<void> setResolution(String res) async {
    _resolution = res;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefRes, res);
  }

  Future<void> setDefaultCamera(String cam) async {
    _defaultCamera = cam;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefCam, cam);
  }
}
