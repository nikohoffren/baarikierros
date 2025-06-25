import 'dart:async';

class TimerService {
  static Future<void> delay(Duration duration) async {
    await Future.delayed(duration);
  }

  static Stream<int> countdown(Duration duration) {
    int totalSeconds = duration.inSeconds;
    return Stream.periodic(
      const Duration(seconds: 1),
      (computationCount) {
        int remainingSeconds = totalSeconds - computationCount;
        return remainingSeconds > 0 ? remainingSeconds : 0;
      },
    ).take(totalSeconds + 1);
  }

  static String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
