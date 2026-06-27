import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_shopping_app/models/product.dart';
import 'package:voice_shopping_app/models/user_settings.dart';
import 'package:voice_shopping_app/services/db_service.dart';
import 'package:voice_shopping_app/services/ai_service.dart';
import 'package:voice_shopping_app/services/speech_service.dart';
import 'package:voice_shopping_app/screens/settings_screen.dart';
import 'package:voice_shopping_app/screens/history_screen.dart';

class ShoppingScreen extends StatefulWidget {
  final DbService dbService;
  final AiService aiService;
  final SpeechService speechService;

  const ShoppingScreen({
    super.key,
    required this.dbService,
    required this.aiService,
    required this.speechService,
  });

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _budgetController =
      TextEditingController(text: '10000');
  List<Product> _products = [];
  UserSettings? _settings;
  bool _isLoading = false;
  double _budgetLimit = 10000.0;
  bool _isTextEmpty = true;

  bool _isLongPressing = false;
  bool _isLocked = false;
  final double _lockThreshold = -60.0;
  double _startY = 0.0;
  int _recordingStartTimestamp = 0;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _textController.addListener(() {
      final isNowEmpty = _textController.text.trim().isEmpty;
      if (_isTextEmpty != isNowEmpty) {
        setState(() {
          _isTextEmpty = isNowEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final list = await widget.dbService.getAllProducts();
    var settings = await widget.dbService.getUserSettings();

    settings ??= UserSettings();

    final prefs = await SharedPreferences.getInstance();
    final cachedLang = prefs.getString('selected_language_code');
    final cachedCurrency = prefs.getString('selected_currency_code');

    if (cachedLang != null) {
      settings.selectedLanguage = cachedLang;
    }
    if (cachedCurrency != null) {
      settings.selectedCurrency = cachedCurrency;
    }

    if (!mounted) return;
    setState(() {
      _products = list;
      _settings = settings;
    });
  }

  String _getTranslatedText(String key) {
    final lang = _settings?.selectedLanguage ?? 'ru';
    final Map<String, Map<String, String>> localizedValues = {
      'ru': {
        'title': 'Голосовые покупки',
        'empty': 'Список пуст',
        'limit_error': 'Исчерпан дневной лимит бесплатных запросов ИИ',
        'clear_title': 'Очистить список?',
        'clear_content': 'Все товары будут удалены из базы данных.',
        'cancel': 'Отмена',
        'clear': 'Очистить',
        'copied':
            '📋 Список скопирован! Теперь его можно вставить в WhatsApp или Telegram.',
        'empty_share': 'Нечего отправлять, список пуст',
        'remaining': 'ОСТАЛОСЬ',
        'in_cart': 'В корзине',
        'total': 'ВСЕГО',
        'hint': 'Диктуйте список...',
        'qty': 'Количество',
        'misc': 'Разное',
        'share_title': 'МОЙ СПИСОК ПОКУПОК',
        'review_title': 'Проверьте список',
        'add_all': 'Добавить всё в список',
        'swipe_up': 'Сдвиньте вверх для фиксации',
        'recording': 'Идет запись...',
        'locked_mode': 'Запись зафиксирована',
        'budget_label': 'БЮДЖЕТ:',
      },
      'kk': {
        'title': 'Дауыстық сатып алулар',
        'empty': 'Тізім бос',
        'limit_error': 'ИИ-дің тегін тәуліктік сұраныс лимиті бітті',
        'clear_title': 'Тізімді тазалау керек пе?',
        'clear_content': 'Барлық тауарлар дерекқордан жойылады.',
        'cancel': 'Бас тарту',
        'clear': 'Тазалау',
        'copied':
            '📋 Тізім көшірілді! Енді Оны WhatsApp немесе Telegram-ға қоюға болады.',
        'empty_share': 'Жіберетін ештеңе жоқ, тізім бос',
        'remaining': 'ҚАЛДЫ',
        'in_cart': 'Себетте',
        'total': 'БАРЛЫҒЫ',
        'hint': 'Тізімді айтыңыз...',
        'qty': 'Саны',
        'misc': 'Әртүрлі',
        'share_title': 'МЕНІҢ САТЫП АЛУЛАР ТІЗІМІМ',
        'review_title': 'Тізімді тексеріңіз',
        'add_all': 'Барлығын тізімге қосу',
        'swipe_up': 'Бекіту үшін жоғары сырғытыңыз',
        'recording': 'Жазылуда...',
        'locked_mode': 'Жазу бекітілді',
        'budget_label': 'БЮДЖЕТ:',
      },
      'en': {
        'title': 'Voice Shopping',
        'empty': 'The list is empty',
        'limit_error': 'Daily limit for free AI requests has been reached',
        'clear_title': 'Clear the list?',
        'clear_content': 'All items will be deleted from the database.',
        'cancel': 'Cancel',
        'clear': 'Clear',
        'copied':
            '📋 List copied! Now you can paste it into WhatsApp or Telegram.',
        'empty_share': 'Nothing to send, the list is empty',
        'remaining': 'REMAINING',
        'in_cart': 'In cart',
        'total': 'TOTAL',
        'hint': 'Dictate list...',
        'qty': 'Quantity',
        'misc': 'Miscellaneous',
        'share_title': 'MY SHOPPING LIST',
        'review_title': 'Review your list',
        'add_all': 'Add all to list',
        'swipe_up': 'Swipe up to lock',
        'recording': 'Recording...',
        'locked_mode': 'Recording locked',
        'budget_label': 'BUDGET:',
      }
    };
    return localizedValues[lang]?[key] ?? localizedValues['en']![key] ?? key;
  }

  Future<bool> _checkLimitsAndIncrement() async {
    final prefs = await SharedPreferences.getInstance();
    bool isProEnabled = prefs.getBool('is_pro_version_enabled') ?? false;
    String todayStr = DateTime.now().toIso8601String().split('T')[0];
    int currentRequests = prefs.getInt('ai_req_$todayStr') ?? 0;

    if (isProEnabled) {
      if (currentRequests >= 100) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Превышен суточный лимит PRO (100 запросов)."),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return false;
      }
      await prefs.setInt('ai_req_$todayStr', currentRequests + 1);
      return true;
    } else {
      bool hasLimit = await widget.dbService.checkAiLimitAndIncrement();
      if (!hasLimit) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getTranslatedText('limit_error'))),
        );
        return false;
      }
      return true;
    }
  }

  Future<void> _processManualText(String text) async {
    if (text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    _textController.clear();

    try {
      bool limitsOk = await _checkLimitsAndIncrement();
      if (!limitsOk) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      List<Product> parsedProducts =
          await widget.aiService.parseShoppingList(text);
      if (parsedProducts.isNotEmpty) {
        for (var product in parsedProducts) {
          await widget.dbService.addProduct(product);
        }
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _loadProducts();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processAudioFile(String filePath) async {
    setState(() => _isLoading = true);
    _textController.clear();

    try {
      bool limitsOk = await _checkLimitsAndIncrement();
      if (!limitsOk) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      List<Product> parsedProducts =
          await widget.aiService.parseAudioFile(filePath);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (parsedProducts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Не удалось распознать товары.")),
        );
        return;
      }
      for (var product in parsedProducts) {
        await widget.dbService.addProduct(product);
      }
      await _loadProducts();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startAudioRecording() async {
    _pulseController.repeat(reverse: true);
    _recordingStartTimestamp = DateTime.now().millisecondsSinceEpoch;
    try {
      await widget.speechService.startListening((uiPlaceholderText) {
        if (mounted && (_isLongPressing || _isLocked)) {
          _textController.text = uiPlaceholderText;
        }
      });
    } catch (e) {
      if (mounted) _pulseController.stop();
    }
  }

  void _stopAndSendAudio() async {
    if (mounted) _pulseController.stop();
    final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    final int elapsed = currentTimestamp - _recordingStartTimestamp;
    if (elapsed < 500) {
      await Future.delayed(Duration(milliseconds: 500 - elapsed));
    }
    await SystemSound.play(SystemSoundType.click);
    final audioPath = await widget.speechService.stopAndGetAudioFile();

    if (!mounted) return;
    setState(() {
      _isLongPressing = false;
      _isLocked = false;
    });

    if (audioPath != null && audioPath.isNotEmpty) {
      _processAudioFile(audioPath);
    }
  }

  void _cancelAudioRecording() async {
    if (mounted) _pulseController.stop();
    await HapticFeedback.mediumImpact();
    try {
      await widget.speechService.stopListening();
    } catch (e) {
      debugPrint('Ошибка при принудительной остановке аудио-сессии: $e');
    }
    _textController.clear();
    if (!mounted) return;
    setState(() {
      _isLongPressing = false;
      _isLocked = false;
    });
  }

  void _generateShareTextAndCopy(Map<String, List<Product>> groupedProducts,
      double totalAll, String currency) async {
    final shareText = _generateShareText(groupedProducts, totalAll, currency);
    await Clipboard.setData(ClipboardData(text: shareText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(_getTranslatedText('copied')),
          backgroundColor: const Color(0xFF00A884)),
    );
  }

  String _generateShareText(Map<String, List<Product>> groupedProducts,
      double total, String currency) {
    if (_products.isEmpty) return _getTranslatedText('empty');
    final buffer = StringBuffer();
    buffer.writeln('📝 *${_getTranslatedText('share_title')}* 📝');
    for (var entry in groupedProducts.entries) {
      buffer.writeln('\n🔹 *${entry.key.toUpperCase()}*:');
      for (var product in entry.value) {
        final status = product.isBought ? '✅' : '📌';
        buffer.writeln(
            '  $status ${product.name} — ${product.quantity} шт. (${product.price.toStringAsFixed(0)} $currency)');
      }
    }
    buffer.writeln(
        '\n💰 *${_getTranslatedText('total')}: ${total.toStringAsFixed(0)} $currency*');
    return buffer.toString();
  }

  String _getProductEmoji(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('мясо') || cat.contains('meat')) return '🍗';
    if (cat.contains('молоч') || cat.contains('milk')) return '🥛';
    if (cat.contains('фрукт') ||
        cat.contains('овощ') ||
        cat.contains('fruit')) {
      return '🍎';
    }
    if (cat.contains('хлеб') || cat.contains('bakery')) return '🍞';
    if (cat.contains('напит') || cat.contains('drink')) return '🧃';
    return '📦';
  }

  @override
  Widget build(BuildContext context) {
    final currency = _settings?.selectedCurrency ?? '₸';

    double totalAll = 0;
    double totalRemaining = 0;
    for (var item in _products) {
      final itemSum = item.price * item.quantity;
      totalAll += itemSum;
      if (!item.isBought) totalRemaining += itemSum;
    }

    final Map<String, List<Product>> groupedProducts = {};
    for (var product in _products) {
      final category = product.category.trim().isEmpty
          ? _getTranslatedText('misc')
          : product.category;
      if (!groupedProducts.containsKey(category)) {
        groupedProducts[category] = [];
      }
      groupedProducts[category]!.add(product);
    }

    double percent = _budgetLimit > 0 ? (totalAll / _budgetLimit) : 0.0;
    if (percent > 1.0) percent = 1.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0C2B27), Color(0xFF051210)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildPremiumAppBar(currency, groupedProducts, totalAll),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF00A884)))
                    : _products.isEmpty
                        ? Center(
                            child: Text(_getTranslatedText('empty'),
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 16)))
                        : ListView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            children:
                                groupedProducts.entries.map((categoryEntry) {
                              return _buildPremiumCategoryGroup(
                                  categoryEntry.key,
                                  categoryEntry.value,
                                  currency);
                            }).toList(),
                          ),
              ),
              _buildPremiumBottomControlPanel(
                  currency, totalAll, totalRemaining, percent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumAppBar(String currency,
      Map<String, List<Product>> groupedProducts, double totalAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getTranslatedText('title'),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
          ),
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.history, color: Colors.white70, size: 22),
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HistoryScreen(
                              dbService: widget.dbService,
                              currency: currency)));
                  _loadProducts();
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white70, size: 22),
                onPressed: () {
                  if (_products.isEmpty) return;
                  _generateShareTextAndCopy(
                      groupedProducts, totalAll, currency);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 22),
                onPressed: () {
                  if (_products.isEmpty) return;
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: const Color(0xFF132220),
                      title: Text(_getTranslatedText('clear_title'),
                          style: const TextStyle(color: Colors.white)),
                      content: Text(_getTranslatedText('clear_content'),
                          style: const TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(_getTranslatedText('cancel'),
                                style: const TextStyle(color: Colors.grey))),
                        TextButton(
                          onPressed: () async {
                            await widget.dbService.clearAllProducts();
                            await _loadProducts();
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          },
                          child: Text(_getTranslatedText('clear'),
                              style: const TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: Color(0xFFCEB175), size: 22),
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SettingsScreen(dbService: widget.dbService)));
                  _loadProducts();
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPremiumCategoryGroup(
      String categoryName, List<Product> products, String currency) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        decoration: BoxDecoration(
          // ИСПРАВЛЕНО: .withOpacity заменен на .withValues
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.04), width: 1),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          iconColor: const Color(0xFFCEB175),
          collapsedIconColor: const Color(0xFFCEB175),
          title: Text(
            categoryName.toUpperCase(),
            style: const TextStyle(
                color: Color(0xFFCEB175),
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1.5),
          ),
          children: products
              .map((product) => _buildPremiumProductCard(product, currency))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildPremiumProductCard(Product product, String currency) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        // ИСПРАВЛЕНО: .withOpacity заменен на .withValues
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              // ИСПРАВЛЕНО: .withOpacity заменен на .withValues
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10)),
          child: Center(
              child: Text(_getProductEmoji(product.category),
                  style: const TextStyle(fontSize: 18))),
        ),
        title: Text(
          product.name,
          style: TextStyle(
            color: product.isBought ? Colors.white38 : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            decoration: product.isBought
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        subtitle: Text(
          '${_getTranslatedText('qty')}: ${product.quantity} шт.',
          style: TextStyle(
              // ИСПРАВЛЕНО: .withOpacity заменен на кастомные константные цвета для стабильности
              color: product.isBought ? Colors.white24 : Colors.white54,
              fontSize: 12),
        ),
        trailing: Text(
          '${product.price.toStringAsFixed(0)} $currency',
          style: const TextStyle(
              color: Color(0xFFCEB175),
              fontWeight: FontWeight.bold,
              fontSize: 15),
        ),
        onTap: () async {
          await widget.dbService.toggleProductStatus(product.id);
          _loadProducts();
        },
      ),
    );
  }

  Widget _buildPremiumBottomControlPanel(
      String currency, double totalAll, double totalRemaining, double percent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1B19),
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    if (!_isLongPressing)
                      TextField(
                        controller: _textController,
                        onSubmitted: _processManualText,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: _getTranslatedText('hint'),
                          hintStyle: const TextStyle(color: Colors.white30),
                          // ИСПРАВЛЕНО: .withOpacity заменен на .withValues
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          filled: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                        ),
                      ),
                    if (_isLongPressing)
                      Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                            // ИСПРАВЛЕНО: .withOpacity заменен на .withValues
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(24)),
                        child: Row(
                          children: [
                            ScaleTransition(
                              scale: Tween(begin: 1.0, end: 1.25)
                                  .animate(_pulseController),
                              child: const Icon(Icons.circle,
                                  color: Colors.redAccent, size: 12),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _isLocked
                                    ? _getTranslatedText('locked_mode')
                                    : _getTranslatedText('recording'),
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                            ),
                            if (_isLocked)
                              IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.white54, size: 20),
                                  onPressed: _cancelAudioRecording)
                            else
                              Text(_getTranslatedText('swipe_up'),
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (!_isLocked)
                Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) {
                    _startY = event.position.dy;
                    if (!_isTextEmpty) {
                      _processManualText(_textController.text);
                    } else {
                      SystemSound.play(SystemSoundType.click);
                      HapticFeedback.lightImpact();
                      setState(() {
                        _isLongPressing = true;
                        _isLocked = false;
                      });
                      _startAudioRecording();
                    }
                  },
                  onPointerMove: (event) {
                    if (_isLongPressing && !_isLocked && _isTextEmpty) {
                      double dragDistance = event.position.dy - _startY;
                      if (dragDistance < _lockThreshold) {
                        setState(() {
                          _isLocked = true;
                          _isLongPressing = false;
                        });
                        HapticFeedback.heavyImpact();
                      }
                    }
                  },
                  onPointerUp: (event) {
                    if (_isLongPressing && !_isLocked) {
                      _stopAndSendAudio();
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      if (_isLongPressing && !_isLocked && _isTextEmpty)
                        Positioned(
                            top: _lockThreshold / 1.3,
                            child: const Icon(Icons.keyboard_arrow_up,
                                color: Colors.white54, size: 18)),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _isLongPressing
                              ? Colors.redAccent
                              : const Color(0xFF00A884),
                          shape: BoxShape.circle,
                          boxShadow: _isLongPressing
                              ? [
                                  BoxShadow(
                                      color: Colors.redAccent
                                          .withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2)
                                ]
                              : [],
                        ),
                        child: Icon(!_isTextEmpty ? Icons.send : Icons.mic,
                            color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ),
              if (_isLocked)
                GestureDetector(
                  onTap: _stopAndSendAudio,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                        color: Color(0xFF00A884), shape: BoxShape.circle),
                    child:
                        const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_getTranslatedText('budget_label')} $currency',
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text('${_getTranslatedText('remaining')}: ',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12)),
                  Text('${totalRemaining.toStringAsFixed(0)} $currency',
                      style: const TextStyle(
                          color: Color(0xFFCEB175),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ],
              )
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 6,
                    // ИСПРАВЛЕНО: .withOpacity заменен на .withValues
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(percent >= 1.0
                        ? Colors.redAccent
                        : const Color(0xFFCEB175)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 75,
                height: 26,
                child: TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                  textAlign: _totalAlignPadding(),
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {
                        _budgetLimit = double.tryParse(value) ?? 0.0;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    // ИСПРАВЛЕНО: .withOpacity заменен на .withValues
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextAlign _totalAlignPadding() => TextAlign.center;
}
