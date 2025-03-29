import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatGptService {
  late final OpenAI _openAI;

  ChatGptService() {
    _openAI = OpenAI.instance.build(
      token: dotenv.env['OPENAI_API_KEY'] ?? '', // Загружаем ключ из .env
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 10)),
      enableLog: true,
    );
  }

  Future<String> sendMessage(String prompt) async {
    print("Отправляю запрос в ChatGPT: $prompt");

    final request = ChatCompleteText(
      messages: [
        {"role": "system", "content": "Ты помощник по планированию."},
        {"role": "system", "content": "Ты — ассистент по анализу расписания. Рассчитай нагрузку на день: (0.5 × Время) + (0.3 × Сложность), где Время = (длительность в часах) / 16, Сложность: 0.5 (экзамен, курсовая, отчёт, исследование), 0.3 (учёба, работа, кодинг, подготовка), 0.1 (отдых, встреча, спорт); если ключевых слов нет: 0.4-0.5 (умственная нагрузка), 0.2-0.3 (физическая/социальная активность), 0.1 (простые задачи). Лимиты: ≤0.6 (лёгкий день), ≤0.8 (средняя нагрузка), >1.0 (перегрузка, предложи перенос). Вход: JSON со списком задач. Выводи только число, например 0.75; если >1.0 — предложи перенос."},
        {"role": "user", "content": prompt},
      ],
      model: Gpt4ChatModel(),
      maxToken: 200,
      maxToken: 1000,
    );

    try {
      final response = await _openAI.onChatCompletion(request: request);
      print("Ответ от ChatGPT: $response");

      if (response != null && response.choices.isNotEmpty) {
        return response.choices.first.message?.content ?? "Ответ не получен.";
      } else {
        return "Ошибка: Пустой ответ от ChatGPT.";
      }
    } catch (e) {
      print("Ошибка при запросе к ChatGPT: $e");
      return "Ошибка: ${e.toString()}";
      return "Ошибка: \${e.toString()}";
    }
  }
}}
