import 'package:intl/intl.dart';

DateTime? parseHearingDate(String? raw) {
  if (raw == null) return null;
  final text = raw.trim();
  if (text.isEmpty || text.toUpperCase() == 'N/A' || text.toUpperCase() == 'NA' || text == '-') {
    return null;
  }
  final formats = [
    'dd-MM-yyyy',
    'dd/MM/yyyy',
    'yyyy-MM-dd',
    'dd-MM-yyyy HH:mm:ss',
    'dd/MM/yyyy HH:mm:ss',
    'MM/dd/yyyy',
  ];
  for (final pattern in formats) {
    try {
      return DateFormat(pattern).parseLoose(text);
    } catch (_) {}
  }
  return DateTime.tryParse(text);
}

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
