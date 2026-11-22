import 'package:intl/intl.dart';

String formatDateTime(String iso) {
  final parsed = DateTime.tryParse(iso)?.toLocal();
  if (parsed == null) return '—';
  return DateFormat('d MMM yyyy, h:mm a').format(parsed);
}

String formatDurationMs(int milliseconds) {
  final totalSeconds = (milliseconds / 1000).round().clamp(0, 1 << 31);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) return '${hours}h ${minutes}m';
  if (minutes == 0) return '${seconds}s';
  return '${minutes}m ${seconds}s';
}

String formatClock(Duration duration) {
  final totalSeconds = duration.inSeconds.clamp(0, 1 << 31);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  String two(int value) => value.toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:${two(minutes)}:${two(seconds)}'
      : '${two(minutes)}:${two(seconds)}';
}

int percentage(int score, int maxScore) =>
    maxScore == 0 ? 0 : (score / maxScore * 100).round();
