import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

import '../pages/event_details_page.dart';

class WeekViewWidget extends StatelessWidget {
  final GlobalKey<WeekViewState>? state;
  final double? width;

  const WeekViewWidget({super.key, this.state, this.width});

  @override
  Widget build(BuildContext context) {
    return WeekView(
      key: state,
      width: width,
      showWeekends: true,
      showLiveTimeLineInAllDays: true,
      eventArranger: SideEventArranger(
        maxWidth: MediaQuery.of(context).size.width * 0.3,
      ),
      timeLineWidth: 65,
      scrollPhysics: const BouncingScrollPhysics(),
      liveTimeIndicatorSettings: LiveTimeIndicatorSettings(
        color: Colors.redAccent,
        showTime: true,
      ),
      onTimestampTap: (date) {
        SnackBar snackBar = SnackBar(
          content: Text(
            "On tap: ${date.hour} Hr : ${date.minute} Min",
            style: TextStyle(fontSize: 12),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
      onEventTap: (events, date) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetailsPage(
              event: events.first,
              date: date,
            ),
          ),
        );
      },
      onEventLongTap: (events, date) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetailsPage(
              event: events.first,
              date: date,
            ),
          ),
        );
      },
      eventTileBuilder: (date, events, boundary, start, end) {
        final event = events.first;
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DetailsPage(event: event, date: date),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              event.title, // Показываем только заголовок
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}
