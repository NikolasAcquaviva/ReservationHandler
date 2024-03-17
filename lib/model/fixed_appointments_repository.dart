import 'fixed_appointment.dart';
import 'package:firebase_database/firebase_database.dart';

class FixedAppointmentsRepository {
  DatabaseReference dbReference =
      FirebaseDatabase.instance.ref('fixed_appointments');

  Future<bool> sameNameFixedAppointment(String name) async {
    DataSnapshot first = await dbReference.get();
    if (!first.exists) return false;
    DataSnapshot snapshot =
        await dbReference.orderByChild("name").equalTo(name).get();
    return snapshot.exists;
  }

  Future<void> addFixedAppointment(
      String name, int weekday, int startingHour) async {
    final key = dbReference.push().key;
    DatabaseReference addingReference =
        FirebaseDatabase.instance.ref('fixed_appointments/$key');
    await addingReference
        .set({'name': name, 'weekday': weekday, 'startingHour': startingHour});
  }

  Future<void> removeFixedAppointment(String name) async {
    DataSnapshot snapshot =
        await dbReference.orderByChild("name").equalTo(name).get();
    if (snapshot.exists) {
      for (var element in snapshot.children) {
        await element.ref.remove();
      }
    }
    return;
  }

  Future<List<FixedAppointment>> getFixedAppointments() async {
    DataSnapshot snapshot = await dbReference.get();
    if (snapshot.exists) {
      List<Map<dynamic, dynamic>> fixedAppointments = snapshot.children
          .map((e) => e.value)
          .toList()
          .cast<Map<dynamic, dynamic>>();
      return fixedAppointments
          .map((e) => FixedAppointment(
              name: e['name'],
              weekday: e['weekday'],
              startingHour: e['startingHour']))
          .toList();
    }
    return List.empty();
  }

  Future<List<FixedAppointment>> getWeekdayFixedAppointments(
      int weekday) async {
    DataSnapshot first = await dbReference.get();
    if (!first.exists) return List.empty();
    DataSnapshot snapshot =
        await dbReference.orderByChild("weekday").equalTo(weekday).get();
    if (snapshot.exists) {
      List<Map<dynamic, dynamic>> fixedAppointments = snapshot.children
          .map((e) => e.value)
          .toList()
          .cast<Map<dynamic, dynamic>>();
      return fixedAppointments
          .map((e) => FixedAppointment(
              name: e['name'],
              weekday: e['weekday'],
              startingHour: e['startingHour']))
          .toList();
    }
    return List.empty();
  }
}
