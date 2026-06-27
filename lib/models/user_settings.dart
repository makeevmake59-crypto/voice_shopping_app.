import 'package:isar_community/isar.dart';

// Файл автогенерации
part 'user_settings.g.dart';

@Collection()
class UserSettings {
  Id id = 1; // У настроек всегда ID = 1, так как запись в таблице всего одна

  bool isPremium = false; // Флаг покупки PRO или Lifetime
  int aiRequestsToday = 0; // Счетчик ИИ-запросов за сегодня
  DateTime lastRequestDate =
      DateTime.now(); // Дата последнего запроса для сброса счетчика

  // Новые поля для локализации и мультивалютности
  String selectedLanguage = 'ru'; // По умолчанию русский ('ru', 'kk', 'en')
  String selectedCurrency = '₸'; // По умолчанию тенге ('₸', '₽', '\$', '€')
}
