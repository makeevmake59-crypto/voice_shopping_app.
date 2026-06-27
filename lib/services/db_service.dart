import 'package:flutter/foundation.dart'; // Импортируем для работы debugPrint
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';
import '../models/user_settings.dart';

class DbService {
  late Isar _isar;

  // 1. Инициализация базы данных при старте приложения
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [ProductSchema, UserSettingsSchema],
      directory: dir.path,
    );

    // Если приложение запущено впервые, создаем дефолтную запись настроек
    final existingSettings = await _isar.userSettings.get(1);
    if (existingSettings == null) {
      await _isar.writeTxn(() async {
        await _isar.userSettings.put(UserSettings());
      });
    }

    // Запускаем автоматическую очистку старых чеков при каждом старте приложения
    await deleteOldBoughtProducts();
  }

  // 2. Получить только АКТИВНЫЕ товары из базы (которые не перенесены в историю)
  Future<List<Product>> getAllProducts() async {
    return await _isar.products
        .filter()
        .isArchivedEqualTo(
            false) // Фильтруем только то, что сейчас в списке покупок
        .sortByCreatedAtDesc()
        .findAll();
  }

  // 3. Добавить новый товар в базу
  Future<void> addProduct(Product product) async {
    await _isar.writeTxn(() async {
      await _isar.products.put(product);
    });
  }

  // 4. Переключить статус товара (куплен / не куплен)
  Future<void> toggleProductStatus(Id id) async {
    final product = await _isar.products.get(id);
    if (product != null) {
      product.isBought = !product.isBought;
      await _isar.writeTxn(() async {
        await _isar.products.put(product);
      });
    }
  }

  // 5. Вместо удаления переводим текущий список покупок в историю (Архив)
  Future<void> clearAllProducts() async {
    final activeProducts =
        await _isar.products.filter().isArchivedEqualTo(false).findAll();

    await _isar.writeTxn(() async {
      for (var product in activeProducts) {
        product.isArchived = true; // Архивируем товар чека
        await _isar.products.put(product);
      }
    });
  }

  // 6. ПРОВЕРКА ЛИМИТОВ ИИ И ИНКРЕМЕНТ СЧЕТЧИКА
  Future<bool> checkAiLimitAndIncrement() async {
    final settings = await _isar.userSettings.get(1);
    if (settings == null) return false;

    // Если у пользователя куплен Premium/Lifetime — лимиты отключаются
    if (settings.isPremium) return true;

    final now = DateTime.now();
    final isSameDay = settings.lastRequestDate.year == now.year &&
        settings.lastRequestDate.month == now.month &&
        settings.lastRequestDate.day == now.day;

    if (isSameDay) {
      // Наш тарифный лимит для бесплатной версии — 15 запросов в сутки
      if (settings.aiRequestsToday < 15) {
        settings.aiRequestsToday++;
        await _isar
            .writeTxn(() async => await _isar.userSettings.put(settings));
        return true;
      }
      return false; // Запросов больше нет, нужно показать Paywall
    } else {
      // Если наступил новый день — сбрасываем счетчик в 1 (текущий запрос)
      settings.aiRequestsToday = 1;
      settings.lastRequestDate = now;
      await _isar.writeTxn(() async => await _isar.userSettings.put(settings));
      return true;
    }
  }

  // 7. Получить текущие настройки пользователя (извлекаем запись с ID = 1)
  Future<UserSettings?> getUserSettings() async {
    return await _isar.userSettings.get(1);
  }

  // 8. Переключить статус Premium (PRO) в базе данных
  Future<void> togglePremiumStatus() async {
    final settings = await _isar.userSettings.get(1);
    if (settings != null) {
      settings.isPremium = !settings.isPremium;
      await _isar.writeTxn(() async {
        await _isar.userSettings.put(settings);
      });
    }
  }

  // 9. Обновить выбранный язык в настройках
  Future<void> updateLanguage(String newLang) async {
    final settings = await _isar.userSettings.get(1);
    if (settings != null) {
      settings.selectedLanguage = newLang;
      await _isar.writeTxn(() async {
        await _isar.userSettings.put(settings);
      });
    }
  }

  // 10. Обновить выбранную валюту в настройках
  Future<void> updateCurrency(String newCurrency) async {
    final settings = await _isar.userSettings.get(1);
    if (settings != null) {
      settings.selectedCurrency = newCurrency;
      await _isar.writeTxn(() async {
        await _isar.userSettings.put(settings);
      });
    }
  }

  // 11. УМНАЯ АВТООЧИСТКА: 10 дней хранения для бесплатной версии, вечно — для PRO
  Future<void> deleteOldBoughtProducts() async {
    final settings = await _isar.userSettings.get(1);
    if (settings == null) return;

    // Если активирована PRO-версия, автоочистка полностью отключается
    if (settings.isPremium) {
      debugPrint(
          'ℹ️ Автоочистка: активен PRO-режим, история покупок сохраняется без ограничений.');
      return;
    }

    // Для бесплатной версии вычисляем порог в 10 дней от текущего момента
    final tenDaysAgo = DateTime.now().subtract(const Duration(days: 10));

    await _isar.writeTxn(() async {
      // Ищем купленные архивные или обычные товары, созданные ранее 10 дней назад
      final oldProducts = await _isar.products
          .filter()
          .isBoughtEqualTo(true)
          .createdAtLessThan(tenDaysAgo)
          .findAll();

      if (oldProducts.isNotEmpty) {
        final idsToDelete = oldProducts.map((e) => e.id).toList();
        await _isar.products.deleteAll(idsToDelete);
        debugPrint(
            '♻️ Автоочистка (Бесплатный тариф): удалено старых купленных товаров (10+ дней) — ${idsToDelete.length} шт.');
      }
    });
  }

  // 12. НОВЫЙ МЕТОД: Получить все архивные товары для экрана истории
  Future<List<Product>> getArchivedProducts() async {
    return await _isar.products
        .filter()
        .isArchivedEqualTo(true) // Тянем только то, что лежит в истории
        .sortByCreatedAtDesc()
        .findAll();
  }

  // 13. НОВЫЙ МЕТОД: Вернуть товар из архива обратно в текущий список покупок
  Future<void> restoreProductFromArchive(Id id) async {
    final product = await _isar.products.get(id);
    if (product != null) {
      product.isArchived = false;
      product.isBought = false; // Снимаем чекбокс вычеркивания
      product.createdAt =
          DateTime.now(); // Поднимаем наверх текущего списка по дате

      await _isar.writeTxn(() async {
        await _isar.products.put(product);
      });
    }
  }
}
