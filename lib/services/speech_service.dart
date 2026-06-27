import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class SpeechService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isListening = false;
  String? _lastRecordedPath;

  bool get isListening => _isListening;

  Future<bool> initSpeech() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (e) {
      debugPrint("❌ Ошибка проверки разрешений микрофона: $e");
      return false;
    }
  }

  Future<void> startListening(Function(String) onResult) async {
    if (_isListening) return;

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        onResult("Нет доступа к микрофону");
        return;
      }

      // ЖЕСТКИЙ СБРОС: Если на уровне ОС рекордер думает, что пишет — принудительно гасим его
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }

      // АППАРАТНЫЙ ФИКС ДЛЯ СМАРТФОНА:
      // Даем Android 150 мс, чтобы отыграть вибрацию/клик кнопки и спокойно открыть микрофонный канал
      await Future.delayed(const Duration(milliseconds: 150));

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/voice_list.m4a';

      final oldFile = File(filePath);
      if (await oldFile.exists()) {
        try {
          await oldFile.delete();
        } catch (_) {}
      }

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
        numChannels: 1, // Моно режим
      );

      await _audioRecorder.start(config, path: filePath);

      _isListening = true;
      _lastRecordedPath = filePath;

      onResult("Запись...");
      debugPrint(
          "🎙️ [SpeechService] Микрофон успешно запущен на смартфоне: $filePath");
    } catch (e) {
      _isListening = false;
      debugPrint("❌ Критическая ошибка старта рекордера на смартфоне: $e");
    }
  }

  Future<String?> stopAndGetAudioFile() async {
    try {
      // Опрашиваем реальное состояние плагина в обход переменных
      final isCurrentlyRecording = await _audioRecorder.isRecording();
      debugPrint(
          "ℹ️ Вызван stopAndGetAudioFile. Статус плагина: $isCurrentlyRecording");

      if (isCurrentlyRecording) {
        final path = await _audioRecorder.stop();
        _isListening = false;

        final finalPath = path ?? _lastRecordedPath;

        if (finalPath != null) {
          final file = File(finalPath);
          if (await file.exists()) {
            final size = await file.length();
            debugPrint("📊 [РЕЗУЛЬТАТ] Размер файла на смартфоне: $size байт.");

            // Отсекаем ложные файлы-пустышки (меньше 500 байт — это точно пустой клик)
            if (size < 500) {
              debugPrint("⚠️ Файл пустой или микро-клик, сброс отправки ИИ.");
              return null;
            }
            return finalPath;
          }
        }
        return finalPath;
      }
    } catch (e) {
      debugPrint("❌ Ошибка при остановке записи: $e");
    } finally {
      _isListening = false;
    }
    return null;
  }

  Future<void> stopListening() async {
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
    } catch (_) {
    } finally {
      _isListening = false;
    }
  }
}
