import 'package:flutter/services.dart';

class DtmfPlayer {
  static void playTone(String digit) {
    SystemSound.play(SystemSoundType.click);
  }
}
