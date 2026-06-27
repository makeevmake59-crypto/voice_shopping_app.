import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Локальный быстрый кэш
import '../models/user_settings.dart';
import '../services/db_service.dart';

class SettingsScreen extends StatefulWidget {
  final DbService dbService;

  const SettingsScreen({super.key, required this.dbService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserSettings? _settings;
  bool _isLoading = true;

  // Локальная переменная, которая ЖЕЛЕЗНО удержит тумблер в нужном положении
  bool _localIsPro = false;

  // ИСПРАВЛЕНО: Добавлены новые языковые коды в список разрешенных
  final List<String> _allowedLanguages = [
    'ru',
    'kk',
    'en',
    'tr',
    'de',
    'es',
    'zh'
  ];
  final List<String> _allowedCurrencies = ['₸', '₽', '\$', '€'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // 1. Читаем языковые настройки из Isar
    final settings = await widget.dbService.getUserSettings();

    // 2. Читаем кэш SharedPreferences (он главный источник правды)
    final prefs = await SharedPreferences.getInstance();
    final basePro = prefs.getBool('is_pro_version_enabled') ?? false;
    final cachedLang = prefs.getString('selected_language_code');
    final cachedCurrency = prefs.getString('selected_currency_code');

    if (settings != null) {
      if (cachedLang != null) settings.selectedLanguage = cachedLang;
      if (cachedCurrency != null) settings.selectedCurrency = cachedCurrency;
    }

    if (!mounted) return;
    setState(() {
      _settings = settings;
      _localIsPro = basePro; // Запоминаем в локальный стейт
      _isLoading = false;
    });
  }

  // Метод сохранения настроек
  Future<void> _updateSettings() async {
    if (_settings == null) return;
    try {
      await (widget.dbService as dynamic).saveUserSettings(_settings!);
    } catch (_) {
      try {
        await (widget.dbService as dynamic).saveSettings(_settings!);
      } catch (e) {
        debugPrint('Не удалось保存 настройки в Isar (не критично): $e');
      }
    }
  }

  Future<void> _saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language_code', lang);

    if (_settings != null) {
      _settings!.selectedLanguage = lang;
    }

    setState(() {});
    await _updateSettings();
  }

  Future<void> _saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency_code', currency);

    if (_settings != null) {
      _settings!.selectedCurrency = currency;
    }

    setState(() {});
    await _updateSettings();
  }

  Future<void> _toggleProMode(bool isEnabled) async {
    if (!isEnabled) {
      setState(() {
        _localIsPro = false;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_pro_version_enabled', false);
      return;
    }

    final TextEditingController keyController = TextEditingController();

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2C34),
        title: const Text('Активация PRO версии',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Для отключения дневных лимитов ИИ введите лицензионный код активации.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'PRO-XXXX-XXXX',
                hintStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF00A884)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A884),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final enteredKey = keyController.text.trim();

              if (enteredKey == 'PRO-VOICE-2026' || enteredKey == 'KASPI-VIP') {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_pro_version_enabled', true);

                if (!context.mounted) return;
                setState(() {
                  _localIsPro = true;
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        '🎉 PRO версия успешно активирована! Лимиты отключены.'),
                    backgroundColor: Color(0xFF00A884),
                  ),
                );
              } else {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        '❌ Неверный лицензионный ключ. Проверьте символы.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Активировать',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getTranslation(String key) {
    final lang = _settings?.selectedLanguage ?? 'ru';
    final Map<String, Map<String, String>> values = {
      'ru': {
        'title': 'Настройки',
        'language': 'Язык приложения',
        'currency': 'Валюта',
        'pro_version': 'PRO версия',
      },
      'kk': {
        'title': 'Баптаулар',
        'language': 'Қосымша тілі',
        'currency': 'Валюта',
        'pro_version': 'PRO нұсқасы',
      },
      'en': {
        'title': 'Settings',
        'language': 'Application Language',
        'currency': 'Currency',
        'pro_version': 'PRO Version',
      },
      'tr': {
        'title': 'Ayarlar',
        'language': 'Uygulama Dili',
        'currency': 'Para Birimi',
        'pro_version': 'PRO Sürümü',
      },
      'de': {
        'title': 'Einstellungen',
        'language': 'App-Sprache',
        'currency': 'Währung',
        'pro_version': 'PRO-Version',
      },
      'es': {
        'title': 'Ajustes',
        'language': 'Idioma de la Aplicación',
        'currency': 'Moneda',
        'pro_version': 'Versión PRO',
      },
      'zh': {
        'title': '设置',
        'language': '应用语言',
        'currency': '货币',
        'pro_version': 'PRO 版本',
      }
    };
    return values[lang]?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    String currentLang = _settings?.selectedLanguage ?? 'ru';
    if (!_allowedLanguages.contains(currentLang) ||
        currentLang.trim().isEmpty) {
      currentLang = 'ru';
    }

    String currentCurrency = _settings?.selectedCurrency ?? '₸';
    if (!_allowedCurrencies.contains(currentCurrency) ||
        currentCurrency.trim().isEmpty) {
      currentCurrency = '₸';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTranslation('title')),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A884)))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  color: const Color(0xFF1F2C34),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(_getTranslation('language'),
                        style: const TextStyle(color: Colors.white)),
                    trailing: DropdownButton<String>(
                      value: currentLang,
                      dropdownColor: const Color(0xFF1F2C34),
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      items: const [
                        DropdownMenuItem(value: 'ru', child: Text('Русский')),
                        DropdownMenuItem(value: 'kk', child: Text('Қазақша')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                        DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                        DropdownMenuItem(value: 'es', child: Text('Español')),
                        DropdownMenuItem(value: 'zh', child: Text('中文')),
                      ],
                      onChanged: (String? newLang) {
                        if (newLang != null) _saveLanguage(newLang);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: const Color(0xFF1F2C34),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(_getTranslation('currency'),
                        style: const TextStyle(color: Colors.white)),
                    trailing: DropdownButton<String>(
                      value: currentCurrency,
                      dropdownColor: const Color(0xFF1F2C34),
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      items: const [
                        DropdownMenuItem(value: '₸', child: Text('Тенге (₸)')),
                        DropdownMenuItem(value: '₽', child: Text('Рубль (₽)')),
                        DropdownMenuItem(
                            value: '\$', child: Text('Доллар (\$)')),
                        DropdownMenuItem(value: '€', child: Text('Евро (€)')),
                      ],
                      onChanged: (String? newCurrency) {
                        if (newCurrency != null) _saveCurrency(newCurrency);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: const Color(0xFF1F2C34),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    title: Text(_getTranslation('pro_version'),
                        style: const TextStyle(color: Colors.white)),
                    value: _localIsPro,
                    activeThumbColor: const Color(0xFF00A884),
                    // ИСПРАВЛЕНО: Заменено с .withOpacity(0.5) для устранения предупреждения анализатора
                    activeTrackColor:
                        const Color(0xFF00A884).withValues(alpha: 0.5),
                    inactiveTrackColor: Colors.white10,
                    onChanged: (bool value) {
                      _toggleProMode(value);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
