import 'package:calendar_view/calendar_view.dart';

import 'reservation.dart';
import 'package:firebase_database/firebase_database.dart';

class ReservationsRepository {
  DatabaseReference dbReference = FirebaseDatabase.instance.ref('reservations');

  Future<void> addReservation(String username, String name, String surname,
      DateTime date, int startingHour) async {
    final key = dbReference.push().key;
    DatabaseReference addingReference =
        FirebaseDatabase.instance.ref("reservations/$key");
    await addingReference.set({
      'username': username,
      'name': name,
      'surname': surname,
      'date': date.toString(),
      'startingHour': startingHour
    });
  }

  Future<void> clearPastReservations() async {
    DataSnapshot first = await dbReference.get();
    if (!first.exists) return;
    DataSnapshot snapshot = await dbReference
        .orderByChild('date')
        .endBefore(DateTime.now().subtract(const Duration(hours: 2)).toString())
        .get();
    for (DataSnapshot reservation in snapshot.children) {
      await reservation.ref.remove();
    }
  }

  Future<void> removeReservation(String username, DateTime date) async {
    DataSnapshot first = await dbReference.get();
    if (!first.exists) return;
    DataSnapshot snapshot =
        await dbReference.orderByChild('username').equalTo(username).get();
    if (snapshot.exists) {
      for (DataSnapshot dateSnapshot in snapshot.children) {
        DateTime reservationDate =
            DateTime.parse(dateSnapshot.child('date').value.toString());
        if (reservationDate.compareTo(date) == 0) {
          await dateSnapshot.ref.remove();
        }
      }
    }
    return;
  }

  Future<List<Reservation>> getDayReservations(DateTime date) async {
    DataSnapshot first = await dbReference.get();
    if (!first.exists) return List.empty();

    List<Map<dynamic, dynamic>> reservationsMap = first.children
        .map((e) => e.value)
        .toList()
        .cast<Map<dynamic, dynamic>>();
    List<Reservation> reservations = reservationsMap
        .map((e) => Reservation(
            date: DateTime.parse(e['date']),
            name: e['name'],
            startingHour: e['startingHour'],
            surname: e['surname'],
            username: e['username']))
        .toList();
    return reservations
        .where((element) => element.date.compareWithoutTime(date))
        .toList();
  }

  Future<List<Reservation>> getDayHourReservations(DateTime date) async {
    DataSnapshot first = await dbReference.get();
    if (!first.exists) return List.empty();
    DataSnapshot snapshot =
        await dbReference.orderByChild("startingHour").equalTo(date.hour).get();
    if (snapshot.exists) {
      List<Map<dynamic, dynamic>> sameHourReservationsMap = snapshot.children
          .map((e) => e.value)
          .toList()
          .cast<Map<dynamic, dynamic>>();
      List<Reservation> sameHourReservations = sameHourReservationsMap
          .map((e) => Reservation(
              date: DateTime.parse(e['date']),
              name: e['name'],
              startingHour: e['startingHour'],
              surname: e['surname'],
              username: e['username']))
          .toList();
      return sameHourReservations
          .where((element) => element.date.day == date.day)
          .toList();
    } else {
      return List.empty();
    }
  }

  Future<List<Reservation>> getFutureReservations(String username) async {
    DataSnapshot first = await dbReference.get();
    if (!first.exists) return List.empty();
    DataSnapshot snapshot = await dbReference
        .orderByChild("date")
        .startAfter(DateTime.now().toString())
        .get();
    if (snapshot.exists) {
      List<Map<dynamic, dynamic>> futureReservationsMap = snapshot.children
          .map((e) => e.value)
          .toList()
          .cast<Map<dynamic, dynamic>>();
      List<Reservation> futureReservations = futureReservationsMap
          .map((e) => Reservation(
              date: DateTime.parse(e['date']),
              name: e['name'],
              startingHour: e['startingHour'],
              surname: e['surname'],
              username: e['username']))
          .toList();
      return futureReservations
          .where((element) => (element.username == username))
          .toList();
    }
    return List.empty();
  }
}
