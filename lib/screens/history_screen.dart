import 'package:flutter/material.dart';
import 'package:voice_shopping_app/models/product.dart';
import 'package:voice_shopping_app/services/db_service.dart';

class HistoryScreen extends StatefulWidget {
  final DbService dbService;
  final String currency;

  const HistoryScreen({
    super.key,
    required this.dbService,
    required this.currency,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Product> _archivedProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final list = await widget.dbService.getArchivedProducts();
    setState(() {
      _archivedProducts = list;
      _isLoading = false;
    });
  }

  // Группировка товаров по дням (например: "7 июня 2026")
  Map<String, List<Product>> _groupProductsByDate(List<Product> products) {
    final Map<String, List<Product>> grouped = {};

    final months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];

    for (var product in products) {
      final date = product.createdAt;
      final dateKey = "${date.day} ${months[date.month - 1]} ${date.year}";

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(product);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedHistory = _groupProductsByDate(_archivedProducts);

    return Scaffold(
      appBar: AppBar(
        title: const Text('История покупок'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A884)))
          : _archivedProducts.isEmpty
              ? const Center(
                  child: Text(
                    'История пуста.\nЗдесь будут ваши прошлые чеки.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView(
                  children: groupedHistory.entries.map((entry) {
                    final dateTitle = entry.key;
                    final products = entry.value;

                    // Считаем общую сумму чека за этот день
                    double dayTotal = products.fold(
                        0, (sum, item) => sum + (item.price * item.quantity));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Шапка дня с датой и суммой
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          color: const Color(0xFF1F2C34),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateTitle,
                                style: const TextStyle(
                                  color: Color(0xFF00A884),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${dayTotal.toStringAsFixed(0)} ${widget.currency}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Список товаров за этот день
                        ...products.map((product) {
                          return ListTile(
                            title: Text(
                              product.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${product.quantity} шт. × ${product.price.toStringAsFixed(0)} ${widget.currency}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                            // Кнопка быстрого возврата товара в текущий список
                            trailing: IconButton(
                              icon: const Icon(Icons.replay,
                                  color: Color(0xFF00A884)),
                              tooltip: 'Повторить покупку',
                              onPressed: () async {
                                await widget.dbService
                                    .restoreProductFromArchive(product.id);

                                // ИСПРАВЛЕНО: Защита BuildContext через прямую проверку контекста по правилам Flutter 3.20+
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '"${product.name}" возвращен в список покупок!'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                _loadHistory(); // Обновляем экран истории
                              },
                            ),
                          );
                        }),
                        const Divider(color: Colors.white10, height: 1),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}
