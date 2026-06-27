import 'package:isar_community/isar.dart';

// Этот файл сгенерируется автоматически чуть позже, не пугайся ошибки
part 'product.g.dart';

@Collection()
class Product {
  Id id = Isar.autoIncrement; // Автоматический ID (1, 2, 3...)

  late String name; // Название товара
  late double price; // Цена за единицу
  late int quantity; // Количество
  late String category; // Категория (для PRO-версии)
  late bool isBought; // Флаг: куплен/вычеркнут ли товар
  late DateTime createdAt; // Дата создания для сортировки

  // Флаг архивного товара для работы экрана истории покупок
  bool isArchived = false;
}
