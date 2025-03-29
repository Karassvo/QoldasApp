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

    final request = ChatCompleteText(
      messages: [
        {
          "role": "system",
          "content":
          "Проанализируй расписание и вычисли нагрузку дня строго по формуле: Нагрузка = (0.5 × Время) + (0.3 × Сложность), где:\n"
              "- Время = (длительность задачи в часах) / 16,\n"
              "- Сложность определяется по ключевым словам в title и description:\n"
              "  - 0.5 — «экзамен», «курсовая», «тест», «зачёт»\n"
              "  - 0.3 — «учёба», «кодинг», «программирование», «проект»\n"
              "  - 0.1 — «отдых», «спорт», «развлечение»\n"
              "  - Если ключевых слов нет, оцени контекст:\n"
              "    - 0.4-0.5 — высокая умственная нагрузка\n"
              "    - 0.2-0.3 — физическая или социальная активность\n"
              "    - 0.1 — простые бытовые задачи."
        },
        {"role": "user", "content": prompt},
      ],
      model: Gpt4ChatModel(),
      maxToken: 1000,
    );

    try {
      final response = await _openAI.onChatCompletion(request: request);
      if (response != null && response.choices?.isNotEmpty == true) {
        String firstResponse = response.choices!.first.message?.content ?? "Ответ не получен.";

        print("Ответ первого запроса: $firstResponse");

        // Формируем второй запрос, передавая весь ответ первого запроса
        final secondRequest = ChatCompleteText(
          messages: [
            {"role": "system", "content": "Извлеки только числовое значение нагрузки из ответа пользователя. Ответ должен содержать только число, без пояснений."},
            {"role": "user", "content": firstResponse},
          ],
          model: Gpt4ChatModel(),
          maxToken: 50,
        );

        print("Отправляю второй запрос для числового показателя...");

        final secondResponse = await _openAI.onChatCompletion(request: secondRequest);
        if (secondResponse != null && secondResponse.choices?.isNotEmpty == true) {
          String numericValue = secondResponse.choices!.first.message?.content?.trim() ?? "Число не найдено.";
          return numericValue; // ✅ Теперь возвращается только число
        } else {
          return "Ошибка: Не удалось получить числовой показатель.";
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
