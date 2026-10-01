import '../../services/dtmf_audio_service.dart';

class DtmfPlayer {
  static void playTone(String digit) {
    DtmfAudioService().playTone(digit);
  }
}

