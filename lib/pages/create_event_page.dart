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
                String fullResponse = await _chatGptService.sendMessage(chatPrompt);
                RegExp regex = RegExp(r"\d+(\.\d+)?");
                Match? match = regex.firstMatch(fullResponse);
                String numericValue = match?.group(0) ?? "Ошибка при извлечении числа";


                if (!mounted) return;
                Navigator.of(context).pop();
                _showChatGptResponse(numericValue);
              } catch (e) {
                print("Ошибка ChatGPT: $e");
                if (!mounted) return;
                Navigator.of(context).pop();
                _showChatGptResponse("Ошибка: ${e.toString()}");
              }
            },
            event: widget.event,
          ),
        ),
      ),
    );
  }

  void _showChatGptResponse(String response) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Нагрузка дня"),
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