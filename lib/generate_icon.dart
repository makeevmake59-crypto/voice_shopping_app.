import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

void main() async {
  debugPrint('🎨 Старт генерации профессионального логотипа 1024x1024...');

  // Устанавливаем размер холста
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 1024, 1024));

  // 1. Рисуем фон (Фирменный темно-зеленый цвет приложения #00A884)
  final bgPaint = Paint()..color = const Color(0xFF00A884);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 1024, 1024),
      const Radius.circular(220), // Скругленные углы в стиле современных ОС
    ),
    bgPaint,
  );

  // 2. Рисуем белый круг-подложку в центре для контраста
  final circlePaint = Paint()..color = Colors.white.withValues(alpha: 0.15);
  canvas.drawCircle(const Offset(512, 512), 320, circlePaint);

  // 3. Отрисовываем иконку микрофона в центре
  final iconPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  // Капсула микрофона
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(448, 300, 128, 280),
      const Radius.circular(64),
    ),
    iconPaint,
  );

  // Подставка микрофона (дуга)
  final standPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 32
    ..strokeCap = StrokeCap.round;

  canvas.drawArc(
    const Rect.fromLTWH(384, 340, 256, 256),
    0,
    3.14159, // Полуокружность
    false,
    standPaint,
  );

  // Ножка микрофона
  canvas.drawLine(const Offset(512, 596), const Offset(512, 700), standPaint);
  // Основание подставки
  canvas.drawLine(const Offset(416, 700), const Offset(608, 700), standPaint);

  // Сохраняем холст в изображение
  final picture = recorder.endRecording();
  final img = await picture.toImage(1024, 1024);
  final byteData = await img.toByteData(format: ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();

  // Создаем директорию и записываем файл
  final directory = Directory('assets/images');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final file = File('assets/images/app_icon.png');
  await file.writeAsBytes(buffer);

  // ИСПРАВЛЕНО: Заменили print на debugPrint для идеальной чистоты линтера
  debugPrint('✅ Иконка успешно создана по пути: assets/images/app_icon.png');
  exit(0);
}
