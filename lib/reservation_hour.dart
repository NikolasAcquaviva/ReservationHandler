import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:reservation_manager/model/fixed_appointment.dart';
import 'model/app_state_model.dart';
import 'model/user.dart';
import 'model/reservation.dart';
import 'package:provider/provider.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EventHiddenData {
  String? username;
  Color? color;

  EventHiddenData(String this.username, Color this.color);
}

enum CalendarChangeOperation { creation, timeChange, deletion }

class ReservationHourPageState extends State<ReservationHourPage> {
  final workingHours = [8, 9, 10, 11, 12, 16, 17, 18, 19];
  final eventColors = [
    Colors.deepPurple[300] as Color,
    Colors.cyan[300] as Color,
    Colors.orange[300] as Color
  ];
  late AppStateModel appState;
  DateTime? updateDate;

  sendEmailCalendarChange(String name, String surname, DateTime? previousDate,
      DateTime newDate, CalendarChangeOperation operation) async {
    String shortDate = AppStateModel.getShortDate(newDate) as String;
    String? shortPreviousDate = AppStateModel.getShortDate(previousDate);
    String? previousDateWeekday =
        AppStateModel.getWeekdayName(previousDate?.weekday);
    String newDateWeekday =
        AppStateModel.getWeekdayName(newDate.weekday) as String;
    String calendarOperationContent = switch (operation) {
      CalendarChangeOperation.creation =>
        "$name $surname ha aggiunto una nuova prenotazione in data $newDateWeekday $shortDate alle ore ${newDate.hour}:00-${newDate.hour + 1}:00",
      CalendarChangeOperation.timeChange =>
        "$name $surname ha cambiato la prenotazione di data $previousDateWeekday $shortPreviousDate, ore ${previousDate!.hour}:00-${previousDate.hour + 1}:00 in data $newDateWeekday $shortDate, ore ${newDate.hour}:00-${newDate.hour + 1}:00",
      CalendarChangeOperation.deletion =>
        "$name $surname ha rimosso la prenotazione di data $newDateWeekday $shortDate in ore ${newDate.hour}:00-${newDate.hour + 1}:00",
    };

    String managerEmailAddress = await appState.getUserEmailAddress("erikfernando");
    final smtpServer =
        gmail(appState.handlerEmailAddress, appState.applicationPassword);

    final message = Message()
      ..from = Address(appState.handlerEmailAddress)
      ..recipients.add(managerEmailAddress)
      ..ccRecipients.add(appState.handlerEmailAddress)
      ..subject = "Aggiornamento Calendario"
      ..html =
          "<h1>C'è stato un cambio al calendario!</h1>\n<p>Ciao Erik! Il calendario è stato modificato da un utente!!</p><br><p>$calendarOperationContent</p>";

    await send(message, smtpServer);
  }

  CalendarEventData createEvent(
      DateTime date, User? user, int colorIndex, String? fixedName) {
    int numberOfEvent = appState.eventController.events
        .where((element) => element.date.hour == date.hour)
        .length;

    var event = CalendarEventData(
        titleStyle: const TextStyle(
            fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
        title: user != null
            ? user.name
            : (appState.loggedUser!.isAdmin ? fixedName! : ""),
        event: EventHiddenData(
            user != null ? user.username : "", eventColors[colorIndex]),
        date: date.add(Duration(seconds: numberOfEvent)),
        startTime: date.add(Duration(seconds: numberOfEvent)),
        endTime: date.add(Duration(hours: 1, seconds: numberOfEvent - 59)));
    return event;
  }

  int getMondayOrToday(DateTime datetime) {
    DateTime today = DateTime.now().withoutTime;
    DateTime todayWeekFriday = today.add(Duration(days: 5 - today.weekday));
    bool isNextWeek = datetime.difference(todayWeekFriday).inDays > 2;
    if (isNextWeek) {
      return datetime.weekday - 1;
    } else {
      return datetime.weekday - today.weekday;
    }
  }

  void showGeneralDialog(String message) {
    showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
              title: const Center(child: Text("Prenotazione Appuntamento")),
              content: Center(
                  child: Text(
                message,
                style: const TextStyle(color: Colors.black),
              )),
              actions: <CupertinoDialogAction>[
                CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Chiudi"))
              ]);
        });
  }

  void showDialogWorkingHours(DateTime date) {
    showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Center(child: Text("Prenotazione Appuntamento")),
            content: Container(
                margin: const EdgeInsets.only(top: 4.0),
                child: Column(
                  children: [
                    RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                            style: const TextStyle(color: Colors.black),
                            text:
                                "Non è possibile prenotare un appuntamento alle ore ${date.hour}:00!")),
                    RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                            style: TextStyle(color: Colors.black),
                            text: "Consultare la sezione ",
                            children: <InlineSpan>[
                              TextSpan(
                                text: "Regole",
                                style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                              TextSpan(
                                  style: TextStyle(color: Colors.black),
                                  text:
                                      " per maggiori informazioni sugli orari disponibili.")
                            ]))
                  ],
                )),
            actions: <CupertinoDialogAction>[
              CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Chiudi")),
            ],
          );
        });
  }

  Future<bool> populateEvents() async {
    await appState.clearPastReservations();
    DateTime viewingDay = widget.selectedDay;
    List<Reservation> dbEvents = await appState.getDateReservations(viewingDay);
    dbEvents.sort((a, b) => a.date.compareTo(b.date));
    appState.emptyEventController();
    int colorIndex = 0;
    for (var event in dbEvents) {
      User? eventUser =
          await appState.userRepository.getUserByUsername(event.username);
      if (eventUser == null) continue;
      var viewEvent = createEvent(event.date, eventUser, colorIndex % 3, null);
      colorIndex++;
      appState.eventController.add(viewEvent);
    }

    List<FixedAppointment> dayFixedAppointments =
        await appState.getWeekdayFixedAppointments(viewingDay.weekday);
    dayFixedAppointments.sort((a, b) => a.startingHour - b.startingHour);

    for (var event in dayFixedAppointments) {
      DateTime eventDate =
          viewingDay.withoutTime.add(Duration(hours: event.startingHour));
      var viewEvent = createEvent(eventDate, null, colorIndex % 3, event.name);
      colorIndex++;
      appState.eventController.add(viewEvent);
    }
    return true;
  }

  LayoutBuilder createDayViewContainer() {
    return LayoutBuilder(
        builder: (context, constraints) => Container(
            padding: const EdgeInsets.all(16.0),
            child: DayView(
              timeLineBuilder: (date) => Center(
                  child: Text("${date.hour}:00", textAlign: TextAlign.center)),
              startDuration: const Duration(hours: 7, minutes: 30),
              timeLineWidth: 50,
              liveTimeIndicatorSettings:
                  HourIndicatorSettings(color: Colors.blue[200] as Color),
              minDay: widget.selectedDay
                  .subtract(Duration(days: widget.selectedDay.weekday - 1)),
              maxDay: widget.selectedDay
                  .add(Duration(days: 5 - widget.selectedDay.weekday)),
              initialDay: widget.selectedDay,
              controller: appState.eventController,
              headerStyle: const HeaderStyle(),
              heightPerMinute: 0.8,
              hourIndicatorSettings: const HourIndicatorSettings(
                height: 1.5,
              ),
              eventArranger: const SideEventArranger(),
              eventTileBuilder:
                  (date, events, boundary, startDuration, endDuration) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: constraints.maxWidth / 3,
                          height: boundary.height - 8,
                          margin: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                          decoration: BoxDecoration(
                            color:
                                (events.first.event as EventHiddenData).color,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Center(child: Text(events[0].title)))
                    ]);
              },
              dayTitleBuilder: (date) => Container(
                  alignment: Alignment.center,
                  color: Colors.blue[100],
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(DateFormat('dd-MM-yyyy').format(date))),
              onDateTap: (date) async {
                var todayUserEvents = (await appState.reservationRepository
                        .getDayReservations(date))
                    .where((element) =>
                        element.username == appState.loggedUser!.username)
                    .toList();
                if (!workingHours.contains(date.hour)) {
                  showDialogWorkingHours(date);
                } else if (date.difference(DateTime.now()).inHours <= 1) {
                  showGeneralDialog(
                      "L'appuntamento deve essere prenotato con più di un'ora di anticipo!");
                } else if (date.weekday == DateTime.friday && date.hour >= 16) {
                  showGeneralDialog(
                      "Nella giornata di venerdì sono disponibili solo gli orari mattutini.");
                } else if (todayUserEvents.isNotEmpty) {
                  if (context.mounted) {
                    Navigator.push(context, CupertinoModalPopupRoute<void>(
                        builder: ((BuildContext context) {
                      return CupertinoActionSheet(
                          title: const Center(
                              child: Text("Prenotazione Appuntamento")),
                          message: Center(
                              child: Column(children: [
                            Text(
                                "Nella data selezionata è già presente una prenotazione in ore ${todayUserEvents.first.date.hour}:00-${todayUserEvents.first.date.hour + 1}:00"),
                            const Text(
                                "Verrà aggiornata con il nuovo orario selezionato.")
                          ])),
                          actions: <CupertinoActionSheetAction>[
                            CupertinoActionSheetAction(
                                isDefaultAction: true,
                                onPressed: () async {
                                  User loggedUser = appState.loggedUser as User;
                                  await appState.reservationRepository
                                      .removeReservation(loggedUser.username,
                                          todayUserEvents.first.date);
                                  await appState.reservationRepository
                                      .addReservation(
                                          loggedUser.username,
                                          loggedUser.name,
                                          loggedUser.surname,
                                          date,
                                          date.hour);

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    Navigator.pushReplacement(
                                        context,
                                        CupertinoPageRoute(
                                            builder: (context) =>
                                                ReservationHourPage(
                                                    selectedDay: date)));
                                  }
                                  await sendEmailCalendarChange(
                                      loggedUser.name,
                                      loggedUser.surname,
                                      todayUserEvents.first.date,
                                      date,
                                      CalendarChangeOperation.timeChange);
                                },
                                child:
                                    const Text("Aggiorna Orario Prenotazione")),
                            CupertinoActionSheetAction(
                                isDefaultAction: true,
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                    "Mantieni Prenotazione Precedente"))
                          ]);
                    })));
                  }
                } else {
                  List<Reservation> hourDayReservations =
                      await appState.getDayHourReservations(date);
                  if (hourDayReservations.length >= 3) {
                    showGeneralDialog(
                        "Nella data e orario selezionati sono già presenti 3 appuntamenti");
                    return;
                  }
                  if (context.mounted) {
                    Navigator.push(context, CupertinoModalPopupRoute<void>(
                        builder: (BuildContext context) {
                      return CupertinoActionSheet(
                        title: const Center(
                            child: Text("Prenotazione Appuntamento")),
                        message: Center(
                            child: Text(
                                "Verrà registrata una prenotazione dalle ore ${date.hour}:00 alle ore ${date.hour + 1}:00.")),
                        actions: <CupertinoActionSheetAction>[
                          CupertinoActionSheetAction(
                              isDefaultAction: true,
                              onPressed: () async {
                                User loggedUser = appState.loggedUser as User;
                                await appState.addReservation(
                                    loggedUser.username,
                                    loggedUser.name,
                                    loggedUser.surname,
                                    date,
                                    date.hour);

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                      context,
                                      CupertinoPageRoute(
                                          builder: (context) =>
                                              ReservationHourPage(
                                                  selectedDay: date)));
                                }
                                await sendEmailCalendarChange(
                                    loggedUser.name,
                                    loggedUser.surname,
                                    null,
                                    date,
                                    CalendarChangeOperation.creation);
                              },
                              child: const Text("Conferma")),
                          CupertinoActionSheetAction(
                            child: const Text("Annulla"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          )
                        ],
                      );
                    }));
                  }
                }
              },
              onPageChange: (date, page) {
                Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                        builder: (context) =>
                            ReservationHourPage(selectedDay: date)));
              },
              onEventTap: (events, date) {
                if ((events.first.event as EventHiddenData).username !=
                    appState.loggedUser!.username) {
                  return;
                } else if (events.first.startTime!
                    .subtract(const Duration(hours: 1))
                    .difference(DateTime.now())
                    .isNegative) {
                  showGeneralDialog(
                      "Non è possibile modificare una prenotazione a meno di un'ora prima dell'appuntamento!");
                  return;
                }
                var dateString = AppStateModel.getShortDate(date);
                Navigator.push(context, CupertinoModalPopupRoute<void>(
                    builder: (BuildContext context) {
                  return CupertinoActionSheet(
                    title: const Center(child: Text("Modifica Prenotazione")),
                    message: Center(
                        child: Text(
                            "Prenotazione del giorno $dateString dalle ore ${events.first.startTime!.hour}:00 alle ore ${events.first.startTime!.hour + 1}:00.")),
                    actions: <CupertinoActionSheetAction>[
                      CupertinoActionSheetAction(
                          isDefaultAction: true,
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                CupertinoModalPopupRoute<void>(
                                    builder: (context) => LayoutBuilder(
                                        builder:
                                            (context, constraints) => Center(
                                                    child: Column(
                                                  children: [
                                                    Container(
                                                        margin: const EdgeInsets
                                                            .only(top: 12.0),
                                                        width: constraints
                                                                .maxWidth *
                                                            0.7,
                                                        height: constraints
                                                                .maxHeight *
                                                            0.7,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .vertical(
                                                            top:
                                                                Radius.circular(
                                                                    15.0),
                                                          ),
                                                        ),
                                                        child:
                                                            CupertinoDatePicker(
                                                          backgroundColor:
                                                              Colors.white,
                                                          initialDateTime: widget
                                                              .selectedDay.withoutTime
                                                              .add(
                                                                  const Duration(
                                                                      hours:
                                                                          8)),
                                                          minimumDate: widget
                                                              .selectedDay
                                                              .withoutTime
                                                              .subtract(Duration(
                                                                  days: getMondayOrToday(
                                                                      widget
                                                                          .selectedDay))),
                                                          maximumDate: widget
                                                              .selectedDay
                                                              .withoutTime
                                                              .add(Duration(
                                                                  days: 5 -
                                                                      widget
                                                                          .selectedDay
                                                                          .weekday,
                                                                  hours: 23)),
                                                          minuteInterval: 60,
                                                          showDayOfWeek: true,
                                                          use24hFormat: true,
                                                          onDateTimeChanged:
                                                              (date) {
                                                            updateDate = date;
                                                          },
                                                        )),
                                                    Container(
                                                        width: constraints
                                                                .maxWidth *
                                                            0.7,
                                                        height: constraints
                                                                .maxHeight *
                                                            0.2,
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius.vertical(
                                                                  bottom: Radius
                                                                      .circular(
                                                                          15.0)),
                                                        ),
                                                        child: Column(
                                                            children: [
                                                              Container(
                                                                  width: 0.7 *
                                                                          constraints
                                                                              .maxWidth -
                                                                      8.0,
                                                                  height: 0.1 *
                                                                          constraints
                                                                              .maxHeight -
                                                                      4.0,
                                                                  margin: const EdgeInsets
                                                                      .only(
                                                                      bottom:
                                                                          4.0,
                                                                      left: 4.0,
                                                                      right:
                                                                          4.0),
                                                                  child: CupertinoButton
                                                                      .filled(
                                                                          onPressed:
                                                                              () async {
                                                                            
                                                                              updateDate ??= widget.selectedDay.withoutTime.add(const Duration(hours: 8));
                                                                            List<Reservation>
                                                                                hourDayReservations =
                                                                                await appState.getDayHourReservations(updateDate!);
                                                                            var todayUserEvents =
                                                                                (await appState.reservationRepository.getDayReservations(updateDate!)).where((element) => element.username == appState.loggedUser!.username).toList();

                                                                            if (!workingHours.contains(updateDate!
                                                                                .hour)) {
                                                                              showDialogWorkingHours(updateDate!);
                                                                            } else if (updateDate!.difference(DateTime.now()).inHours <=
                                                                                1) {
                                                                              showGeneralDialog("L'appuntamento deve essere prenotato con più di un'ora di anticipo!");
                                                                            } else if (updateDate!.weekday == DateTime.friday &&
                                                                                updateDate!.hour >= 16) {
                                                                              showGeneralDialog("Nella giornata di venerdì sono disponibili solo gli orari mattutini.");
                                                                            } else if (hourDayReservations.length >= 3) {
                                                                              showGeneralDialog("Nella data e orario selezionati sono già presenti 3 appuntamenti");
                                                                            } else if (todayUserEvents.isNotEmpty) {
                                                                              if (context.mounted) {
                                                                                Navigator.push(context, CupertinoModalPopupRoute<void>(builder: ((BuildContext context) {
                                                                                  return CupertinoActionSheet(
                                                                                      title: const Center(child: Text("Prenotazione Appuntamento")),
                                                                                      message: Center(
                                                                                          child: Column(children: [
                                                                                        Text("Nella data selezionata è già presente una prenotazione in ore ${todayUserEvents.first.date.hour}:00-${todayUserEvents.first.date.hour + 1}:00"),
                                                                                        const Text("Verrà aggiornata con il nuovo orario selezionato.")
                                                                                      ])),
                                                                                      actions: <CupertinoActionSheetAction>[
                                                                                        CupertinoActionSheetAction(
                                                                                            isDefaultAction: true,
                                                                                            onPressed: () async {
                                                                                              User loggedUser = appState.loggedUser as User;
                                                                                              await appState.reservationRepository.removeReservation(loggedUser.username, todayUserEvents.first.date);
                                                                                              await appState.reservationRepository.addReservation(loggedUser.username, loggedUser.name, loggedUser.surname, updateDate!, updateDate!.hour);
                                                                                              if (context.mounted) {
                                                                                                Navigator.pushAndRemoveUntil(context, CupertinoPageRoute(builder: (context) => ReservationHourPage(selectedDay: updateDate!)), (route) => route.isFirst);
                                                                                              }
                                                                                              await sendEmailCalendarChange(loggedUser.name, loggedUser.surname, todayUserEvents.first.date, updateDate!, CalendarChangeOperation.timeChange);
                                                                                            },
                                                                                            child: const Text("Aggiorna Orario Prenotazione")),
                                                                                        CupertinoActionSheetAction(isDefaultAction: true, onPressed: () => Navigator.pop(context), child: const Text("Mantieni Prenotazione Precedente"))
                                                                                      ]);
                                                                                })));
                                                                              }
                                                                            } else {
                                                                              if (context.mounted) {
                                                                                Navigator.pop(context);
                                                                                Navigator.push(context, CupertinoModalPopupRoute<void>(builder: (BuildContext context) {
                                                                                  var shortUpdatedDate = AppStateModel.getShortDate(updateDate);
                                                                                  return CupertinoActionSheet(
                                                                                    title: const Center(child: Text("Modifica Prenotazione")),
                                                                                    message: Center(child: Text("Verrà modificata la data e orario della prenotazione del giorno $dateString delle ore ${events.first.startTime!.hour}:00-${events.first.startTime!.hour + 1}:00 al giorno $shortUpdatedDate, ore ${updateDate!.hour}:00-${updateDate!.hour + 1}:00.")),
                                                                                    actions: <CupertinoActionSheetAction>[
                                                                                      CupertinoActionSheetAction(
                                                                                          isDefaultAction: true,
                                                                                          onPressed: () async {
                                                                                            User loggedUser = appState.loggedUser as User;
                                                                                            await appState.reservationRepository.removeReservation(loggedUser.username, events.first.startTime!);
                                                                                            await appState.reservationRepository.addReservation(loggedUser.username, loggedUser.name, loggedUser.surname, updateDate!, updateDate!.hour);
                                                                                            if (context.mounted) {
                                                                                                Navigator.pushAndRemoveUntil(context, CupertinoPageRoute(builder: (context) => ReservationHourPage(selectedDay: updateDate!)), (route) => route.isFirst);
                                                                                            }
                                                                                            await sendEmailCalendarChange(loggedUser.name, loggedUser.surname, events.first.startTime, updateDate!, CalendarChangeOperation.timeChange);
                                                                                          },
                                                                                          child: const Text("Conferma")),
                                                                                      CupertinoActionSheetAction(
                                                                                        child: const Text("Annulla"),
                                                                                        onPressed: () {
                                                                                          Navigator.pop(context);
                                                                                        },
                                                                                      )
                                                                                    ],
                                                                                  );
                                                                                }));
                                                                              }
                                                                            }
                                                                          },
                                                                          child:
                                                                              const Text("Conferma Orario Modifica"))),
                                                              Container(
                                                                  width: 0.7 *
                                                                          constraints
                                                                              .maxWidth -
                                                                      8.0,
                                                                  height: 0.1 *
                                                                          constraints
                                                                              .maxHeight -
                                                                      8.0,
                                                                  margin: const EdgeInsets
                                                                      .only(
                                                                      right:
                                                                          4.0,
                                                                      left: 4.0,
                                                                      bottom:
                                                                          8.0),
                                                                  child: CupertinoButton
                                                                      .filled(
                                                                          onPressed:
                                                                              () {
                                                                            Navigator.pop(context);
                                                                          },
                                                                          child:
                                                                              const Text(
                                                                            "Annulla",
                                                                          )))
                                                            ]))
                                                  ],
                                                )))));
                          },
                          child: const Text("Modifica Data/Orario")),
                      CupertinoActionSheetAction(
                          isDestructiveAction: true,
                          onPressed: () async {
                            User loggedUser = appState.loggedUser as User;
                            String username = loggedUser.username;
                            await appState.removeReservation(
                                username, events.first.date);

                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) => ReservationHourPage(
                                          selectedDay: date)));
                            }
                            await sendEmailCalendarChange(
                                loggedUser.name,
                                loggedUser.surname,
                                null,
                                events.first.date,
                                CalendarChangeOperation.deletion);
                          },
                          child: const Text("Cancella Prenotazione")),
                      CupertinoActionSheetAction(
                        child: const Text("Annulla"),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      )
                    ],
                  );
                }));
              },
            )));
  }

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting("it-IT", null);
    appState = Provider.of<AppStateModel>(context, listen: false);
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
                      title: const Text("Orario Appuntamento")),
                ],
            body: Scaffold(
              backgroundColor: Colors.transparent,
              body: FutureBuilder(
                  future: populateEvents(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return createDayViewContainer();
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  }),
            )));
  }
}

class ReservationHourPage extends StatefulWidget {
  const ReservationHourPage({super.key, required this.selectedDay});
  final DateTime selectedDay;
  @override
  State<ReservationHourPage> createState() {
    return ReservationHourPageState();
  }
}
