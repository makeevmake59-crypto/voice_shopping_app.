import 'package:flutter_test/flutter_test.dart';
import 'package:voice_shopping_app/main.dart';
import 'package:voice_shopping_app/services/db_service.dart';
import 'package:voice_shopping_app/services/ai_service.dart';
import 'package:voice_shopping_app/services/speech_service.dart';

void main() {
  testWidgets('Проверка загрузки главного экрана приложения',
      (WidgetTester tester) async {
    // Создаем пустые экземпляры сервисов для базового теста виджетов
    final dbService = DbService();
    final aiService = AiService(apiKey: 'test_key');
    final speechService = SpeechService();

    // Запускаем наше приложение в тестовом окружении
    await tester.pumpWidget(VoiceShoppingApp(
      dbService: dbService,
      aiService: aiService,
      speechService: speechService,
    ));

    // Проверяем, что на экране отображается заголовок нашего AppBar
    expect(find.text('Голосовые покупки'), findsOneWidget);
  });
}
