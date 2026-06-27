import 'package:flutter/material.dart';
import 'package:voice_shopping_app/services/db_service.dart';
import 'package:voice_shopping_app/services/ai_service.dart';
import 'package:voice_shopping_app/services/speech_service.dart';
import 'package:voice_shopping_app/screens/shopping_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DbService();
  await dbService.init();

  final aiService = AiService(
      apiKey: 'AQ.Ab8RN6LVfBtKamTerR5D5ggGGBumRzoew6kwBapZ1w2XWQa6lA');

  final speechService = SpeechService();
  try {
    await speechService.initSpeech();
  } catch (e) {
    debugPrint('Предупреждение аудио-движка (нормально для Linux): $e');
  }

  runApp(VoiceShoppingApp(
    dbService: dbService,
    aiService: aiService,
    speechService: speechService,
  ));
}

class VoiceShoppingApp extends StatelessWidget {
  final DbService dbService;
  final AiService aiService;
  final SpeechService speechService;

  const VoiceShoppingApp({
    super.key,
    required this.dbService,
    required this.aiService,
    required this.speechService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Голосовые покупки',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF111E25),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111E25),
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFF00A884),
          surface: const Color(0xFF1F2C34),
        ),
      ),
      home: ShoppingScreen(
        dbService: dbService,
        aiService: aiService,
        speechService: speechService,
      ),
    );
  }
}
