import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model/app_state_model.dart';
import 'model/reservation.dart';

class ReservationPageState extends State<ReservationPage> {
  Future<List<Widget>> createWidgetList(AppStateModel appState) async {
    List<Reservation> userReservations =
        await appState.getFutureReservations(appState.loggedUser!.username);
    userReservations.sort((a, b) => a.date.compareTo(b.date));
    List<Widget> widgetList = [];
    for (var reservation in userReservations) {
      var reservationContainer = Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
              color: Colors.blue[300],
              border: Border.all(width: 1.0, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              Text(
                  'Data: ${AppStateModel.getWeekdayName(reservation.date.weekday)}, ${AppStateModel.getShortDate(reservation.date)}'),
              Text(
                  "Orario: ${reservation.startingHour}:00 - ${reservation.startingHour + 1}:00")
            ],
          ));
      widgetList.add(const SizedBox(height: 20.0));
      widgetList.add(reservationContainer);
    }

    return widgetList;
  }

  @override
  Widget build(BuildContext context) {
    AppStateModel appState = Provider.of<AppStateModel>(context, listen: false);
    String username = appState.loggedUser!.username;
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
                      title: Text("Appuntamenti di $username")),
                ],
            body: Center(
                child: FutureBuilder(
                    future: createWidgetList(appState),
                    builder: ((context, snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data!.isNotEmpty
                            ? ListView(children: snapshot.data as List<Widget>)
                            : const Text(
                                "Non sono state ancora fatte prenotazioni!");
                      } else {
                        return const CircularProgressIndicator();
                      }
                    })))));
  }
}

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() {
    return ReservationPageState();
  }
}
