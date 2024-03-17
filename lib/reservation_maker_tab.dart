import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:reservation_manager/model/app_state_model.dart';
import 'reservation_hour.dart';

final today = DateUtils.dateOnly(DateTime.now());

class ReservationMakerState extends State<ReservationMakerTab> {
  final List<DateTime?> _singleDatePickerValueWithDefaultValue = [];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(builder: (context, appState, child) {
      return CupertinoPageScaffold(
          child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
              pinned: true,
              backgroundColor: Colors.blue[200],
              centerTitle: true,
              expandedHeight: 48,
              toolbarHeight: 40,
              collapsedHeight: 40,
              title: const Text("Aggiungi Prenotazione"))
        ],
        body: Scaffold(body: 
          Center(child: SizedBox(
            width: 375,
            child: _buildDefaultSingleDatePickerWithValue(appState))))
      ));
    });
  }

  Widget _buildDefaultSingleDatePickerWithValue(AppStateModel appState) {
    final config = CalendarDatePicker2Config(
      selectedDayHighlightColor: Colors.blue,
      weekdayLabels: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      weekdayLabelTextStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      firstDayOfWeek: 1,
      controlsHeight: 50,
      controlsTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      dayTextStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
      disabledDayTextStyle: const TextStyle(
        color: Colors.grey,
      ),
      selectableDayPredicate: (day) =>
          !day
              .difference(DateTime.now().subtract(const Duration(days: 1)))
              .isNegative &&
          day.weekday != DateTime.saturday &&
          day.weekday != DateTime.sunday &&
          day.difference(DateTime.now()).inDays < 14 - DateTime.now().weekday,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        CalendarDatePicker2(
          config: config,
          value: _singleDatePickerValueWithDefaultValue,
          onValueChanged: (dates) => setState(() {
            Navigator.push(
                context,
                CupertinoPageRoute(
                    title: "Selezione Orario Appuntamento",
                    builder: (context) => ReservationHourPage(
                        selectedDay: dates.first as DateTime)));
          }),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class ReservationMakerTab extends StatefulWidget {
  const ReservationMakerTab({super.key});
  @override
  State<ReservationMakerTab> createState() {
    return ReservationMakerState();
  }
}
