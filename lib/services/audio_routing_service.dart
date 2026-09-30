import 'package:flutter_webrtc/flutter_webrtc.dart';

class AudioRoutingService {
  static bool _isSpeakerOn = false;

  static bool get isSpeakerOn => _isSpeakerOn;

  static Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    try {
      await Helper.setSpeakerphoneOn(_isSpeakerOn);
    } catch (_) {}
  }

  static Future<void> setSpeaker(bool enable) async {
    _isSpeakerOn = enable;
    try {
      await Helper.setSpeakerphoneOn(_isSpeakerOn);
    } catch (_) {}
  }
}

