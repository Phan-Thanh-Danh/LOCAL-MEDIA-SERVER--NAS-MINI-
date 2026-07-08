import 'package:intl/intl.dart';

class FormatHelper {
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB"];
    var i = 0;
    double size = bytes.toDouble();
    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
