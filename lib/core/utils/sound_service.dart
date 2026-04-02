import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// Sons et vibrations — persona Kevin, conducteur de moto
/// Son PERÇANT répété, vibration FORTE 3x 500ms
class SoundService {
  SoundService._();

  static final _player = AudioPlayer();

  /// Alerte nouvelle course : son perçant répété 3 fois + vibration
  static Future<void> playNewCourseAlert() async {
    await vibrateStrong();
    for (int i = 0; i < 3; i++) {
      try {
        await _player.play(AssetSource('sounds/new_course.mp3'));
        await Future<void>.delayed(const Duration(milliseconds: 800));
      } catch (_) {
        // ignore: avoid_print
        assert(() { print('[Sound] new_course.mp3 not found'); return true; }());
      }
    }
  }

  /// Son de livraison confirmée
  static Future<void> playDeliveredSound() async {
    try {
      await _player.play(AssetSource('sounds/delivered.mp3'));
    } catch (_) {
      assert(() { print('[Sound] delivered.mp3 not found'); return true; }()); // ignore: avoid_print
    }
    await vibrateSuccess();
  }

  /// Vibration forte : 3 pulses de 500ms — perceptible avec gants
  static Future<void> vibrateStrong() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
    }
  }

  /// Vibration courte succès
  static Future<void> vibrateSuccess() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 300);
    }
  }
}
