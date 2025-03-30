import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatGptService {
  late final OpenAI _openAI;

  // Глобальный список для хранения данных о нагрузке
  static final List<Map<String, dynamic>> _history = [];

  ChatGptService() {
    _openAI = OpenAI.instance.build(
      token: dotenv.env['OPENAI_API_KEY'] ?? '',
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 20)),
      enableLog: true,
    );
  }

  Future<String> sendMessage(String prompt, DateTime date) async {
    print("Отправляю запрос в ChatGPT: $prompt");

    final firstRequest = ChatCompleteText(
      messages: [
        {
          "role": "system",
          "content":
          "Проанализируй расписание и вычисли нагрузку дня по формуле : "
              "Нагрузка задачи= (0.5 × Время) + (0.4 × Сложность), где:\n"
              "- Время = (длительность задачи в часах) / 14,\n"
              "Нагрузка дня= сумма всех нагрузок задач\n"
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
        RegExp regExp = RegExp(r'Итог:\s*([\d.]+)');
        Match? match = regExp.firstMatch(fullAnalysis);

        String numericValue = match?.group(1) ?? "0"; // Если число не найдено, ставим 0
        double loadValue = double.tryParse(numericValue) ?? 0.0;
        print("Числовое значение: $loadValue");

        // Сохраняем в историю
        _saveToHistory(loadValue);

        // Если нагрузка больше 0.7, возвращаем рекомендацию
        if (loadValue > 0.7) {
          String suggestedDay = _findLeastLoadedDay();
          return "Внимание! Нагрузка высокая. Рекомендуется перенести часть задач на $suggestedDay.";
        }

        // Ничего не возвращаем, если нагрузка нормальная
        return "";
      } else {
        return "Ошибка: Пустой ответ от ChatGPT.";
      }
    } catch (e) {
      print("Ошибка при запросе к ChatGPT: $e");
      return "Ошибка: ${e.toString()}";
    }
  }

  // Метод для сохранения данных в историю
  void _saveToHistory(double value) {
    final now = DateTime.now();
    _history.add({
      "date": "${now.year}-${now.month}-${now.day}",
      "value": value,
    });
    print("Данные сохранены: $_history");
  }

  // Поиск дня с наименьшей нагрузкой или ближайшего дня
  String _findLeastLoadedDay() {
    if (_history.isEmpty) {
      DateTime tomorrow = DateTime.now().add(Duration(days: 1));
      return "${tomorrow.year}-${tomorrow.month}-${tomorrow.day}";
    }

    // Собираем уникальные даты
    Set<String> uniqueDates = _history.map((e) => e["date"] as String).toSet();

    if (uniqueDates.length == 1) {
      DateTime tomorrow = DateTime.now().add(Duration(days: 1));
      return "${tomorrow.year}-${tomorrow.month}-${tomorrow.day}";
    }
    Map<String, double> dailyLoad = {};
    Map<String, int> count = {};

    for (var entry in _history) {
      String date = entry["date"];
      double value = entry["value"];

      dailyLoad[date] = (dailyLoad[date] ?? 0) + value;
      count[date] = (count[date] ?? 0) + 1;
    }
    dailyLoad.forEach((key, value) {
      dailyLoad[key] = value / count[key]!;
    });
    String leastLoadedDay = dailyLoad.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    return leastLoadedDay;
  }

  static List<Map<String, dynamic>> getHistory() {
    return _history;
  }
}
