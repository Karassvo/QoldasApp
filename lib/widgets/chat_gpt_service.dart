import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import '../consts.dart';

class ChatGptService {
  final OpenAI _openAI = OpenAI.instance.build(
    token: OPENAI_API_KEY,
    baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 10)),
    enableLog: true,
  );

  Future<String> sendMessage(String prompt) async {
    print("Отправляю запрос в ChatGPT: $prompt");

    final request = ChatCompleteText(
      messages: [
        {"role": "system", "content": "Ты помощник по планированию."},
        {"role": "user", "content": prompt},
      ],
      model: Gpt4ChatModel(),
      maxToken: 200,
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
    }
  }
}
