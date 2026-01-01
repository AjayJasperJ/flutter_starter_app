class CalendarHelper {
  static String twoDigits(int n) => n.toString().padLeft(2, '0');

  static String formatDate(DateTime d) => '${d.year}-${twoDigits(d.month)}-${twoDigits(d.day)}';

  static String formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';
    final dateTime = DateTime.tryParse(time);
    if (dateTime == null) return '--:--';
    return '${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
  }

  static DateTime startDate(String year, String month) =>
      DateTime(int.parse(year), int.parse(month), 1);

  static DateTime nextDay(DateTime date) => date.add(const Duration(days: 1));

  static DateTime previousDay(DateTime date) => date.subtract(const Duration(days: 1));

  static DateTime endDate(String year, String month) =>
      DateTime(int.parse(year), int.parse(month) + 1, 0);

  static DateTime nextMonth(DateTime selectedDate) {
    return DateTime(selectedDate.year, selectedDate.month + 1, selectedDate.day);
  }

  static DateTime previousMonth(DateTime selectedDate) {
    return DateTime(selectedDate.year, selectedDate.month - 1, selectedDate.day);
  }

  static DateTime nextWeek(DateTime selectedDate) {
    return DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 7);
  }

  static DateTime previousWeek(DateTime selectedDate) {
    return DateTime(selectedDate.year, selectedDate.month, selectedDate.day - 7);
  }

  static DateTime getWeekStart(DateTime target) {
    return target.subtract(Duration(days: target.weekday % 7));
  }

  static DateTime getWeekEnd(DateTime target) {
    return getWeekStart(target).add(const Duration(days: 6));
  }

  static DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  static DateTime currentDate = dateOnly(DateTime.now());
  static DateTime currentMonth = DateTime(currentDate.year, currentDate.month, 1);

  static bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  static bool isNextweekNewMonth(DateTime currentweek) {
    return currentweek.month != nextWeek(currentweek).month;
  }

  static bool isPreviousweekNewMonth(DateTime currentweek) {
    return currentweek.month != previousWeek(currentweek).month;
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isPast(DateTime date) {
    return date.isBefore(currentDate);
  }

  static bool isToday(DateTime date) {
    return date.year == currentDate.year &&
        date.month == currentDate.month &&
        date.day == currentDate.day;
  }

  static bool isFuture(DateTime date) {
    return !isPast(date) && !isToday(date);
  }

  static const List<String> monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> weekdayLabels = <String>[
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static List<String> weekdayLabel2() {
    return List<String>.generate(
      weekdayLabels.length,
      (i) => weekdayLabels[(i + 1) % weekdayLabels.length],
    );
  }
}
