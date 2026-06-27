import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/user_settings.dart';
import '../services/db_service.dart';
import '../widgets/category_pie_chart.dart'; // Чистый относительный импорт виджета

class AnalyticsScreen extends StatefulWidget {
  final DbService dbService;

  const AnalyticsScreen({super.key, required this.dbService});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Product> _products = [];
  UserSettings? _settings;
  bool _isLoading = true;

  // Палитра цветов для категорий расходов
  final List<Color> _chartColors = [
    const Color(0xFF00A884), // Наш фирменный зеленый
    Colors.amber,
    Colors.orangeAccent,
    Colors.lightBlueAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    final list = await widget.dbService.getAllProducts();
    final settings = await widget.dbService.getUserSettings();
    setState(() {
      _products = list;
      _settings = settings;
      _isLoading = false;
    });
  }

  String _getTranslation(String key) {
    final lang = _settings?.selectedLanguage ?? 'ru';
    final Map<String, Map<String, String>> values = {
      'ru': {
        'title': 'Аналитика расходов',
        'empty': 'Нет данных для анализа. Добавьте товары с ценами.',
        'total_spent': 'Всего потрачено',
        'by_category': 'По категориям',
        'items_count': 'товаров: ',
        'misc': 'Разное',
      },
      'kk': {
        'title': 'Шығындар аналитикасы',
        'empty': 'Талдау үшін деректер жоқ. Бағасы бар тауарларды қосыңыз.',
        'total_spent': 'Барлығы жұмсалды',
        'by_category': 'Санаттар бойынша',
        'items_count': 'тауар саны: ',
        'misc': 'Әртүрлі',
      },
      'en': {
        'title': 'Expense Analytics',
        'empty': 'No data to analyze. Add products with prices.',
        'total_spent': 'Total spent',
        'by_category': 'By categories',
        'items_count': 'items: ',
        'misc': 'Miscellaneous',
      }
    };
    return values[lang]?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final currency = _settings?.selectedCurrency ?? '₸';

    // Считаем общую сумму введенных товаров с ценами
    double totalSpent = 0;
    final Map<String, double> categorySums = {};
    final Map<String, int> categoryCounts = {};

    for (var p in _products) {
      final cost = p.price * p.quantity;
      if (cost <= 0) continue;

      totalSpent += cost;

      final category =
          p.category.trim().isEmpty ? _getTranslation('misc') : p.category;
      categorySums[category] = (categorySums[category] ?? 0) + cost;
      categoryCounts[category] = (categoryCounts[category] ?? 0) + p.quantity;
    }

    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTranslation('title')),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A884)))
          : totalSpent == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _getTranslation('empty'),
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Card(
                      color: const Color(0xFF1F2C34),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              _getTranslation('total_spent'),
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${totalSpent.toStringAsFixed(0)} $currency',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            CategoryPieChart(
                                data: categorySums, colors: _chartColors),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Text(
                        _getTranslation('by_category').toUpperCase(),
                        style: const TextStyle(
                            color: Color(0xFF00A884),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.1),
                      ),
                    ),
                    ...sortedCategories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final categoryName = entry.value.key;
                      final categoryCost = entry.value.value;
                      final percent = categoryCost / totalSpent;
                      final itemsCount = categoryCounts[categoryName] ?? 0;
                      final color = _chartColors[index % _chartColors.length];

                      return Card(
                        color: const Color(0xFF1F2C34),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    categoryName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  Text(
                                    '${categoryCost.toStringAsFixed(0)} $currency',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_getTranslation('items_count')}$itemsCount | ${(percent * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                              const SizedBox(height: 10),
                              Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(4)),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: percent,
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                          color: color,
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}
