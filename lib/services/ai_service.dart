import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class AiService {
  final GenerativeModel _model;

  AiService({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
          systemInstruction: Content.system(
              'Вы — специализированный модуль распознавания списков покупок для мобильного приложения.\n'
              'Ваша главная задача: извлечь список товаров из переданного текста или аудиозаписи.\n\n'
              'Правила формирования данных:\n'
              '1. Выделять название товара (name), цену за единицу (price), количество (quantity) и категорию (category).\n'
              '2. Если количество не названо, возвращать 1.\n'
              '3. Если цена для товара не названо, возвращать 0.0.\n'
              '4. Категории строго из списка: Продукты, Молочка, Выпечка, Мясо/Рыба, Овощи/Фрукты, Бытовая химия, Разное.\n'
              '5. КРИТИЧЕСКОЕ ПРАВИЛО: Игнорируйте любые случайные вздохи, фоновые шумы, обрывки слов-паразитов (типа "так", "ну все", "давай", "стоп"), которые не относятся к покупкам. Не создавайте для них карточки с ценой 0.\n'
              '6. Ответ должен быть СТРОГО в формате JSON (массив объектов) без кавычек markdown (```json), без пояснений.\n'
              'Шаблон ответа: [{"name": "Строка", "price": 0.0, "quantity": 1, "category": "Строка"}]'),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

  /// Парсинг обычного текста (для ручного ввода клавиатурой)
  Future<List<Product>> parseShoppingList(String voiceText) async {
    if (voiceText.trim().isEmpty) return [];

    try {
      final response = await _model.generateContent([Content.text(voiceText)]);
      if (response.text != null && response.text!.isNotEmpty) {
        return await _mapJsonToProducts(response.text!);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Ошибка парсинга текста через Gemini: $e');
      return [];
    }
  }

  /// Парсинг аудиофайла напрямую через бинарный поток (для микрофона)
  Future<List<Product>> parseAudioFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return [];

    try {
      debugPrint("🚀 [Gemini ИИ] Отправка аудиофайла напрямую в нейросеть...");
      final audioBytes = await file.readAsBytes();

      // Возвращаем правильный mimeType для .m4a
      final audioPart = DataPart('audio/mp4', audioBytes);

      final response = await _model.generateContent([
        Content.multi([
          audioPart,
          TextPart(
              'Прослушай эту аудиозапись и составь JSON список покупок по правилам инструкции.'),
        ])
      ]);

      if (response.text != null && response.text!.isNotEmpty) {
        return await _mapJsonToProducts(response.text!);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Ошибка распознавания аудио через Gemini: $e');
      return [];
    }
  }

  /// Внутренний метод маппинга JSON в объекты класса Product
  Future<List<Product>> _mapJsonToProducts(String jsonString) async {
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      final List<Product> resultProducts = [];

      final prefs = await SharedPreferences.getInstance();
      bool isProEnabled = prefs.getBool('is_pro_version_enabled') ?? false;

      final int maxItemsLimit = isProEnabled ? 100 : 5;

      for (var item in decoded) {
        if (resultProducts.length >= maxItemsLimit) {
          debugPrint(
              "⚠️ Достигнут лимит позиций в списке ($maxItemsLimit шт.) для текущего тарифа.");
          break;
        }

        final String name = (item['name'] ?? 'Без названия').toString().trim();
        final double price = (item['price'] as num?)?.toDouble() ?? 0.0;

        if (price == 0.0) {
          if (name.length <= 3 ||
              name.toLowerCase() == 'все' ||
              name.toLowerCase() == 'давай') {
            continue;
          }
        }

        final product = Product()
          ..name = name
          ..price = price
          ..quantity = item['quantity'] ?? 1
          ..category = item['category'] ?? 'Разное'
          ..isBought = false
          ..createdAt = DateTime.now();

        resultProducts.add(product);
      }
      return resultProducts;
    } catch (e) {
      debugPrint('❌ Ошибка декодирования JSON структуры ИИ: $e');
      return [];
    }
  }
}
