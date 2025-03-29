import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../extension.dart';
import '../widgets/add_event_form.dart';
import '../widgets/chat_gpt_service.dart';

class CreateEventPage extends StatelessWidget {
  const CreateEventPage({super.key, this.event});

  final CalendarEventData? event;

  @override
  Widget build(BuildContext context) {
    final ChatGptService chatGptService = ChatGptService();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: false,
        leading: IconButton(
          onPressed: context.pop,
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.black,
          ),
        ),
        title: Text(
          event == null ? "Create New Event" : "Update Event",
          style: TextStyle(
            color: AppColors.black,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: AddOrEditEventForm(
            onEventAdd: (newEvent) async {
              if (event != null) {
                CalendarControllerProvider.of(context)
                    .controller
                    .update(event!, newEvent);
              } else {
                CalendarControllerProvider.of(context).controller.add(newEvent);
              }

              print(" Создано событие: ${newEvent.title}");

              String prompt =
                  "Я только что создал событие '${newEvent.title}'. Дай мне совет или напоминание.";

              try {
                String chatGptResponse =
                    await chatGptService.sendMessage(prompt);
                print(" Ответ от ChatGPT: $chatGptResponse");

                _showChatGptResponse(context, chatGptResponse);
              } catch (e) {
                print(" Ошибка ChatGPT: $e");
                _showChatGptResponse(context, "Ошибка: ${e.toString()}");
              }

              context.pop(true);
            },
            event: event,
          ),
        ),
      ),
    );
  }

  void _showChatGptResponse(BuildContext context, String response) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Ответ от ChatGPT"),
          content: Text(response),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
