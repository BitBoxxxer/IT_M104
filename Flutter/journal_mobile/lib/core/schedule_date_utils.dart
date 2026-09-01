/// Единая утилита для работы с "неделей расписания".
///
/// Раньше getMonday/getSunday/formatDate были независимо продублированы
/// в api_service.dart и schedule_screen.dart, а data_manager.dart вообще
/// получал их "по случайности" через транзитивный импорт api_service.dart.
/// Такое дублирование — источник будущих багов: поправишь логику в одном
/// месте, а в другом она останется старой. Теперь один источник правды.

/// Понедельник недели, в которую входит [date].
DateTime getMonday(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  final diff = d.weekday - 1;
  return d.subtract(Duration(days: diff));
}

/// Воскресенье недели, в которую входит [date].
DateTime getSunday(DateTime date) {
  final monday = getMonday(date);
  return monday.add(const Duration(days: 6));
}

/// Формат даты для API и БД: YYYY-MM-DD.
String formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
