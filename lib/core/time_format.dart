import 'package:intl/intl.dart';

String timeAgo(DateTime time, [DateTime? now]) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return DateFormat('d MMM').format(time);
}

String timestamp(DateTime time, [DateTime? now]) {
  final today = now ?? DateTime.now();
  final clock = DateFormat('HH:mm').format(time);
  final sameDay = time.year == today.year && time.month == today.month && time.day == today.day;
  if (sameDay) return 'Today, $clock';
  final yesterday = today.subtract(const Duration(days: 1));
  if (time.year == yesterday.year && time.month == yesterday.month && time.day == yesterday.day) {
    return 'Yesterday, $clock';
  }
  return '${DateFormat('d MMM').format(time)}, $clock';
}