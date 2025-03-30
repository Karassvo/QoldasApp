import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../extension.dart';
import '../widgets/add_event_form.dart';
import '../widgets/chat_gpt_service.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key, this.event});

  final CalendarEventData? event;

  @override
  _CreateEventPageState createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  late final ChatGptService _chatGptService;

  @override
  void initState() {
    super.initState();
    _chatGptService = ChatGptService();
  }

  @override
  Widget build(BuildContext context) {
    final _eventController = CalendarControllerProvider.of(context)?.controller;
    if (_eventController == null) {
      print("Ошибка: CalendarController не найден.");
      return Scaffold(
        appBar: AppBar(title: Text("Ошибка")),
        body: Center(child: Text("Ошибка загрузки контроллера календаря")),
      );
    }

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
          widget.event == null ? "Create New Event" : "Update Event",
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
              if (widget.event != null) {
                _eventController.update(widget.event!, newEvent);
              } else {
                _eventController.add(newEvent);
              }

              print("Создано событие: ${newEvent.title}");

              List<CalendarEventData> sameDateEvents = _eventController.events
                  ?.where((event) => event.date == newEvent.date)
                  .toList() ?? [];

              String chatPrompt = "Список задач на ${newEvent.date}:\n";
              for (var event in sameDateEvents) {
                chatPrompt += "- ${event.title}: ${event.description} (с ${event.startTime} до ${event.endTime})\n";
              }
              chatPrompt += "\nПроанализируй нагрузку и в конце напиши 'Итог: X.XX'.";

              _showLoadingDialog();

              try {
                String recommendation = await _chatGptService.sendMessage(chatPrompt, newEvent.date);
                Navigator.of(context).pop(); // Закрываем загрузочный диалог

                if (recommendation.isNotEmpty) {
                  _showChatGptResponse(recommendation, newEvent);
                }
              } catch (e) {
                print("Ошибка ChatGPT: $e");
                Navigator.of(context).pop();
                _showChatGptResponse("Ошибка: ${e.toString()}", newEvent);
              }
            },
            event: widget.event,
          ),
        ),
      ),
    );
  }

  void _showChatGptResponse(String response, CalendarEventData newEvent) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Нагрузка дня"),
          content: Text(response),
          actions: [
            TextButton(
              onPressed: () {
                // Закрываем диалог без изменений
                Navigator.of(context).pop();
              },
              child: Text("Не сейчас"),
            ),
            TextButton(
              onPressed: () {
                // Удаляем старое событие
                final _eventController = CalendarControllerProvider.of(context)?.controller;
                if (_eventController != null) {
                  _eventController.remove(newEvent); // Удаляем старое событие
                  print("Старое событие удалено: ${newEvent.title}");
                }

                // Создаем новый ивент с той же информацией, но новой датой
                final newEventWithNewDate = CalendarEventData(
                  title: newEvent.title,
                  description: newEvent.description,
                  startTime: newEvent.startTime,
                  endTime: newEvent.endTime,
                  date: newEvent.date.add(Duration(days: 1)), // Например, добавляем 1 день
                );

                // Добавляем новый ивент
                if (_eventController != null) {
                  _eventController.add(newEventWithNewDate);
                  print("Новый ивент добавлен с новой датой: ${newEventWithNewDate.title}");
                }

                Navigator.of(context).pop(); // Закрываем диалог
              },
              child: Text("Прислушаться"),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Обрабатываем запрос..."),
            ],
          ),
        );
      },
    );
  }
}
