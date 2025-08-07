import 'package:intl/intl.dart';

class Helpers {
  // Date formatting
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('MMM dd').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatDate(date);
    }
  }

  // Currency formatting
  static String formatCurrency(double amount, {String symbol = '\$'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }

  static String formatCurrencyCompact(double amount, {String symbol = '\$'}) {
    if (amount >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return formatCurrency(amount, symbol: symbol);
    }
  }

  // Number formatting
  static String formatNumber(num number) {
    final formatter = NumberFormat('#,##0');
    return formatter.format(number);
  }

  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  // Date range helpers
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 1).subtract(const Duration(days: 1));
  }

  static DateTime getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return date.subtract(Duration(days: daysFromMonday));
  }

  static DateTime getEndOfWeek(DateTime date) {
    final daysUntilSunday = 7 - date.weekday;
    return date.add(Duration(days: daysUntilSunday));
  }

  static DateTime getStartOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  static DateTime getEndOfYear(DateTime date) {
    return DateTime(date.year, 12, 31);
  }

  // Date range labels
  static String getDateRangeLabel(DateTime start, DateTime end) {
    if (isSameDay(start, end)) {
      return formatDate(start);
    } else if (start.year == end.year) {
      if (start.month == end.month) {
        return '${DateFormat('MMM d').format(start)} - ${DateFormat('d, y').format(end)}';
      } else {
        return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, y').format(end)}';
      }
    } else {
      return '${formatDate(start)} - ${formatDate(end)}';
    }
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final weekStart = getStartOfWeek(now);
    final weekEnd = getEndOfWeek(now);
    return date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        date.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  static bool isThisYear(DateTime date) {
    return date.year == DateTime.now().year;
  }

  // Month names
  static List<String> get monthNames => [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static List<String> get monthFullNames => [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // Text helpers
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Validation helpers
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidAmount(String amount) {
    try {
      final value = double.parse(amount);
      return value > 0;
    } catch (e) {
      return false;
    }
  }

  // Color helpers
  static String getInitials(String text) {
    if (text.isEmpty) return '';
    final words = text.split(' ');
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words.first.substring(0, 1).toUpperCase()}${words.last.substring(0, 1).toUpperCase()}';
  }

  // Statistical helpers
  static double calculateAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }

  static double calculatePercentageChange(double oldValue, double newValue) {
    if (oldValue == 0) return newValue > 0 ? 100.0 : 0.0;
    return ((newValue - oldValue) / oldValue) * 100;
  }

  // File helpers
  static String getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  static bool isImageFile(String filePath) {
    final extension = getFileExtension(filePath);
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  // Category helpers
  static String getCategoryEmoji(String category) {
    const emojiMap = {
      'Food & Dining': '🍽️',
      'Shopping': '🛍️',
      'Transportation': '🚗',
      'Healthcare': '🏥',
      'Entertainment': '🎬',
      'Bills & Utilities': '📄',
      'Education': '🎓',
      'Travel': '✈️',
      'Groceries': '🛒',
      'Other': '📝',
    };
    return emojiMap[category] ?? '📝';
  }

  // Receipt helpers
  static String generateReceiptId() {
    return 'RCP${DateTime.now().millisecondsSinceEpoch}';
  }

  static double calculateTax(double subtotal, double taxRate) {
    return subtotal * (taxRate / 100);
  }

  static double calculateTip(double amount, double tipPercentage) {
    return amount * (tipPercentage / 100);
  }
}
