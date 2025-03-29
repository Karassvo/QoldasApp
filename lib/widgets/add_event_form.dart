import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../app_colors.dart';
import '../constants.dart';
import '../extension.dart';
import 'custom_button.dart';
import 'date_time_selector.dart';

class AddOrEditEventForm extends StatefulWidget {
  final void Function(CalendarEventData)? onEventAdd;
  final CalendarEventData? event;

  const AddOrEditEventForm({super.key, this.onEventAdd, this.event});

  @override
  _AddOrEditEventFormState createState() => _AddOrEditEventFormState();
}

class _AddOrEditEventFormState extends State<AddOrEditEventForm> {
  late DateTime _startDate = DateTime.now().withoutTime;
  DateTime? _startTime;
  DateTime? _endTime;
  Color _color = Colors.blue;
  final _form = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleNode = FocusNode();
  final _descriptionNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setDefaults();
  }

  @override
  void dispose() {
    _titleNode.dispose();
    _descriptionNode.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildTextField(_titleController, "Event Title", "Please enter event title."),
          SizedBox(height: 15),
          _buildDatePicker(),
          SizedBox(height: 15),
          _buildTimePickers(),
          SizedBox(height: 15),
          _buildTextField(_descriptionController, "Event Description", "Please enter event description."),
          SizedBox(height: 15),
          _buildColorPicker(),
          SizedBox(height: 15),
          CustomButton(
            onTap: _createEvent,
            title: widget.event == null ? "Add Event" : "Update Event",
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String errorMsg, {bool isMultiline = false}) {
    return TextFormField(
      controller: controller,
      decoration: AppConstants.inputDecoration.copyWith(labelText: label),
      style: TextStyle(color: AppColors.black, fontSize: 17.0),
      keyboardType: isMultiline ? TextInputType.multiline : TextInputType.text,
      textInputAction: isMultiline ? TextInputAction.newline : TextInputAction.next,
      maxLines: isMultiline ? 10 : 1,
      validator: (value) => value?.trim().isEmpty == true ? errorMsg : null,
    );
  }

  Widget _buildDatePicker() {
    return DateTimeSelectorFormField(
      decoration: AppConstants.inputDecoration.copyWith(labelText: "Date"),
      initialDateTime: _startDate,
      onSelect: (date) => setState(() => _startDate = date.withoutTime),
      validator: (value) => value == null ? "Please select start date." : null,
      type: DateTimeSelectionType.date,
    );
  }

  Widget _buildTimePickers() {
    return Row(
      children: [
        Expanded(
          child: DateTimeSelectorFormField(
            decoration: AppConstants.inputDecoration.copyWith(labelText: "Start Time"),
            initialDateTime: _startTime,
            onSelect: (date) {
              setState(() {
                _startTime = date;
                if (_endTime != null && _endTime!.isBefore(date)) {
                  _endTime = date.add(Duration(minutes: 1));
                }
              });
            },
            type: DateTimeSelectionType.time,
          ),
        ),
        SizedBox(width: 20.0),
        Expanded(
          child: DateTimeSelectorFormField(
            decoration: AppConstants.inputDecoration.copyWith(labelText: "End Time"),
            initialDateTime: _endTime,
            onSelect: (date) {
              setState(() {
                if (_startTime != null && date.isBefore(_startTime!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('End time cannot be before start time.')),
                  );
                } else {
                  _endTime = date;
                }
              });
            },
            type: DateTimeSelectionType.time,
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Row(
      children: [
        Text("Event Color: ", style: TextStyle(color: AppColors.black, fontSize: 17)),
        GestureDetector(
          onTap: _displayColorPicker,
          child: CircleAvatar(radius: 15, backgroundColor: _color),
        ),
      ],
    );
  }

  void _createEvent() {
    if (!(_form.currentState?.validate() ?? false)) return;

    _form.currentState?.save();
    final event = CalendarEventData(
      date: _startDate,
      startTime: _startTime,
      endTime: _endTime,
      color: _color,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
    );
    widget.onEventAdd?.call(event);
    _resetForm();
  }

  void _setDefaults() {
    if (widget.event != null) {
      final event = widget.event!;
      _startDate = event.date;
      _startTime = event.startTime;
      _endTime = event.endTime;
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      _color = event.color;
    }
  }

  void _resetForm() {
    _form.currentState?.reset();
    _startDate = DateTime.now().withoutTime;
    _startTime = null;
    _endTime = null;
    _color = Colors.blue;
    setState(() {});
  }

  void _displayColorPicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Select event color"),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _color,
            onColorChanged: (color) => setState(() => _color = color),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Done"))],
      ),
    );
  }
}
