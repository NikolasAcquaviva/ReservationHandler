import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reservation_manager/model/fixed_appointment.dart';
import 'model/app_state_model.dart';

class FixedAppointmentsPageState extends State<FixedAppointmentsPage> {
  String? name;
  Map<int, bool> weekdayChecked = <int, bool>{
    1: false,
    2: false,
    3: false,
    4: false,
    5: false
  };
  late AppStateModel appState;
  late double boxHeight, boxWidth;

  Widget buildNameField() {
    return CupertinoTextFormFieldRow(
        prefix: const SizedBox(
            width: 40,
            child: Icon(CupertinoIcons.doc_person_fill,
                color: CupertinoColors.inactiveGray, size: 28)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        autocorrect: false,
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            border: Border.all(
                color: CupertinoColors.inactiveGray,
                width: 1.0,
                style: BorderStyle.solid)),
        placeholder: 'Nome cliente',
        onChanged: (newName) {
          setState(() {
            name = newName;
          });
        },
        validator: (input) {
          return (input == null || input.isEmpty)
              ? "Compila questo campo"
              : null;
        });
  }

  List<Widget> weekdayCheckboxList() {
    List<Widget> widgetList = [];
    for (int i = 1; i <= 5; i++) {
      widgetList.add(StatefulBuilder(
          builder: (context, setState) => CupertinoCheckbox(
              value: weekdayChecked[i]!,
              onChanged: (newValue) {
                setState(() {
                  weekdayChecked[i] = newValue!;
                });
              })));
    }
    return widgetList;
  }

  CupertinoModalPopupRoute weekdayModalRoute(
      int weekday, String name, List<int> selectedWeekdays, int index) {
    int hourSelected = 8;
    DateTime today = DateTime.now();
    DateTime initialDateTime = DateTime(today.year, today.month, today.day);
    return CupertinoModalPopupRoute(
        builder: (context) => CupertinoActionSheet(
              title: Center(child: Text("Cliente: $name")),
              message: SizedBox(
                  height: boxHeight * 0.75,
                  width: boxWidth,
                  child: LayoutBuilder(
                      builder: (context, constraints) => Center(
                              child: Column(children: [
                            Text(
                                "Inserisci l'orario per ${AppStateModel.getWeekdayName(weekday)}"),
                            Container(
                                margin: const EdgeInsets.only(top: 12.0),
                                width: constraints.maxWidth * 0.7,
                                height: constraints.maxHeight * 0.7,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(15.0),
                                  ),
                                ),
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.time,
                                  backgroundColor: Colors.white,
                                  initialDateTime: initialDateTime,
                                  minuteInterval: 60,
                                  use24hFormat: true,
                                  onDateTimeChanged: (time) =>
                                      hourSelected = time.hour,
                                ))
                          ])))),
              actions: [
                CupertinoActionSheetAction(
                    onPressed: () async {
                      await appState.addFixedAppointment(name, weekday, hourSelected);
                      if (index == selectedWeekdays.length - 1) {
                        weekdayChecked.updateAll((key, value) => false);
                        if(context.mounted){Navigator.pushAndRemoveUntil(
                          context,
                          CupertinoPageRoute(
                              builder: (context) =>
                                  const FixedAppointmentsPage()),
                          (route) => route.isFirst,
                        );}
                      } else {
                        weekdaySteps(selectedWeekdays, index + 1, name);
                      }
                    },
                    child: const Text('Procedi')),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await appState.removeFixedAppointment(name);
                    if(context.mounted){Navigator.pop(context);}
                  },
                  child: const Text('Annulla'),
                )
              ],
            ));
  }

  void weekdaySteps(List<int> selectedWeekdays, int index, String name) {
    Navigator.pop(context);
    Navigator.push(
        context,
        weekdayModalRoute(
            selectedWeekdays[index], name, selectedWeekdays, index));
  }

  Future<List<Widget>> createViewWidgetList() async {
    appState = Provider.of<AppStateModel>(context, listen: false);
    List<Widget> widgetList = [];
    List<Widget> checkboxList = weekdayCheckboxList();
    widgetList.add(buildNameField());
    for (int i = 0; i < checkboxList.length; i++) {
      widgetList.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Row(children: [
            checkboxList[i],
            const SizedBox(width: 8.0),
            Text(AppStateModel.getWeekdayName(i + 1) as String)
          ])));
    }

    List<Widget> viewWidgetList = [];
    viewWidgetList.add(Container(
        margin: const EdgeInsets.only(top: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: CupertinoButton.filled(
            child: const Text("Aggiungi Appuntamento Fisso"),
            onPressed: () => {
                  Navigator.push(
                      context,
                      CupertinoModalPopupRoute(
                          builder: (context) => CupertinoActionSheet(
                                  title: const Text(
                                      "Configurazione Appuntamento Fisso"),
                                  message: Column(children: widgetList),
                                  actions: <CupertinoActionSheetAction>[
                                    CupertinoActionSheetAction(
                                        onPressed: () async {
                                          List<int> selectedWeekdays =
                                              weekdayChecked.entries
                                                  .where((element) =>
                                                      element.value)
                                                  .map((e) => e.key)
                                                  .toList();
                                          if (name == null ||
                                              name == "" ||
                                              selectedWeekdays.isEmpty) {
                                            return;
                                          }
                                          bool sameName = await appState
                                              .sameNameFixedAppointment(name!);
                                          if (sameName && context.mounted) {
                                            showCupertinoDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return CupertinoAlertDialog(
                                                      title: const Center(
                                                          child: Text(
                                                              "Prenotazione Appuntamento")),
                                                      content: const Center(
                                                          child: Text(
                                                        "Esiste già un appuntamento fisso con questo nome!",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.black),
                                                      )),
                                                      actions: <CupertinoDialogAction>[
                                                        CupertinoDialogAction(
                                                            isDefaultAction:
                                                                true,
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                "Chiudi"))
                                                      ]);
                                                });
                                            return;
                                          }

                                          if (context.mounted) {
                                            boxHeight = context.size!.height;
                                            boxWidth = context.size!.width;
                                          }
                                          weekdaySteps(
                                              selectedWeekdays, 0, name!);
                                        },
                                        child: const Text('Procedi')),
                                    CupertinoActionSheetAction(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Annulla'))
                                  ])))
                })));
    List<FixedAppointment> appointments = await appState.getFixedAppointments();
    List<FixedAppointmentViewModel> viewAppointments =
        <FixedAppointmentViewModel>[];
    List<String> fixedCustomerNames =
        appointments.map((e) => e.name).toSet().toList();

    for (String fixedName in fixedCustomerNames) {
      List<FixedAppointment> nameAppointmentsEntries =
          appointments.where((element) => element.name == fixedName).toList();
      List<int> weekdayList = <int>[];
      Map<int, int> startingHourWeekdayEntry = <int, int>{};

      for (var entry in nameAppointmentsEntries) {
        weekdayList.add(entry.weekday);
        startingHourWeekdayEntry.putIfAbsent(
            entry.weekday, () => entry.startingHour);
      }

      viewAppointments.add(FixedAppointmentViewModel(
          customerName: fixedName,
          weekdays: weekdayList,
          startingHourWeekday: startingHourWeekdayEntry));
    }

    for (var viewAppointment in viewAppointments) {
      List<Text> columnTexts = <Text>[];
      columnTexts.add(Text(
          'Cliente: ${viewAppointment.customerName}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
      for (int weekday in viewAppointment.weekdays) {
        String weekdayName = AppStateModel.getWeekdayName(weekday) as String;
        int startingHour = viewAppointment.startingHourWeekday[weekday] as int;
        String hourRange = "$startingHour:00-${startingHour + 1}:00";
        columnTexts.add(Text("$weekdayName: $hourRange", style: const TextStyle(color: Colors.white)));
      }
      viewWidgetList.add(CupertinoButton(
          onPressed: () {
            Navigator.push(context,
                CupertinoModalPopupRoute<void>(builder: (BuildContext context) {
              return CupertinoActionSheet(
                  title:
                      const Center(child: Text('Gestione Appuntamento Fisso')),
                  actions: <CupertinoActionSheetAction>[
                    CupertinoActionSheetAction(
                        isDestructiveAction: true,
                        child: const Text('Rimuovi Appuntamento Fisso'),
                        onPressed: () async {
                          await appState.removeFixedAppointment(
                              viewAppointment.customerName);
                          if(context.mounted){
                            Navigator.pushAndRemoveUntil(
                              context,
                              CupertinoPageRoute(
                                  builder: (context) =>
                                      const FixedAppointmentsPage()),
                              (route) => route.isFirst);
                          }
                        }),
                    CupertinoActionSheetAction(
                        isDefaultAction: true,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Annulla"))
                  ]);
            }));
          },
          child: Container(
              width: 230,
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                  color: Colors.blue[300],
                  border: Border.all(width: 1.0, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: columnTexts,
              ))));
    }
    return viewWidgetList;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        child: NestedScrollView(
      headerSliverBuilder: ((context, innerBoxIsScrolled) => [
            SliverAppBar(
                pinned: true,
                backgroundColor: Colors.blue[200],
                centerTitle: true,
                expandedHeight: 48,
                toolbarHeight: 40,
                collapsedHeight: 40,
                title: const Text("Appuntamenti Fissi"))
          ]),
      body: Center(
          child: FutureBuilder(
        future: createViewWidgetList(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView(children: snapshot.data as List<Widget>);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      )),
    ));
  }
}

class FixedAppointmentsPage extends StatefulWidget {
  const FixedAppointmentsPage({super.key});

  @override
  State<FixedAppointmentsPage> createState() {
    return FixedAppointmentsPageState();
  }
}
