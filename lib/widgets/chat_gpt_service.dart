import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatGptService {
  late final OpenAI _openAI;

  ChatGptService() {
    _openAI = OpenAI.instance.build(
      token: dotenv.env['OPENAI_API_KEY'] ?? '', // Загружаем ключ из .env
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 20)),
      enableLog: true,
    );
  }

  Future<String> sendMessage(String prompt) async {
    print("Отправляю первый запрос в ChatGPT: $prompt");

    final firstRequest = ChatCompleteText(
      messages: [
        {
          "role": "system",
          "content":
          "Проанализируй расписание и вычисли нагрузку дня по формуле: "
              "Нагрузка = (0.5 × Время) + (0.3 × Сложность), где:\n"
              "- Время = (длительность задачи в часах) / 16,\n"
              "- Сложность определяется по ключевым словам:\n"
              "  - 0.5 — «экзамен», «курсовая», «тест», «зачёт»\n"
              "  - 0.3 — «учёба», «кодинг», «программирование», «проект»\n"
              "  - 0.1 — «отдых», «спорт», «развлечение»\n"
              "Если ключевых слов нет, оцени контекст:\n"
              "  - 0.4-0.5 — высокая умственная нагрузка\n"
              "  - 0.2-0.3 — физическая или социальная активность\n"
              "  - 0.1 — простые бытовые задачи.\n\n"
              "Выведи полный анализ, а в конце напиши **только число нагрузки** в следующем формате: 'Итог: X.XX'"
        },
        {"role": "user", "content": prompt},
      ],
      model: Gpt4ChatModel(),
      maxToken: 1000,
    );

    try {
      final firstResponse = await _openAI.onChatCompletion(request: firstRequest);
      if (firstResponse != null && firstResponse.choices?.isNotEmpty == true) {
        String fullAnalysis = firstResponse.choices!.first.message?.content?.trim() ?? "Ошибка при получении ответа.";

        print("Ответ первого запроса: $fullAnalysis");

        // Извлекаем только число из ответа
        RegExp regExp = RegExp(r'Итог:\s*([\d.]+)'); // Находим строку вида "Итог: X.XX"
        Match? match = regExp.firstMatch(fullAnalysis);

        if (match != null) {
          String numericValue = match.group(1) ?? "";
          print("Числовое значение: $numericValue");
          return numericValue; // ✅ Возвращаем только число
        } else {
          print("Не удалось извлечь число, возвращаю весь анализ.");
          return fullAnalysis;
        }
      } else {
        return "Ошибка: Пустой ответ от ChatGPT.";
      }
    } catch (e) {
      print("Ошибка при запросе к ChatGPT: $e");
      return "Ошибка: ${e.toString()}";
    }
  }
}
