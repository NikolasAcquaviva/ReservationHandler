// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:calendar_view/calendar_view.dart';
import 'user.dart';
import 'users_repository.dart';
import 'reservation.dart';
import 'reservations_repository.dart';
import 'fixed_appointment.dart';
import 'fixed_appointments_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FixedAppointmentViewModel {
  const FixedAppointmentViewModel(
      {required this.customerName,
      required this.weekdays,
      required this.startingHourWeekday});
  final String customerName;
  final List<int> weekdays;
  final Map<int, int> startingHourWeekday;
}

class AppStateModel extends foundation.ChangeNotifier {
  User? loggedUser;
  final CupertinoTabController unloggedTabController = CupertinoTabController();
  final CupertinoTabController loggedTabController = CupertinoTabController();
  late EventController eventController;
  final handlerEmailAddress = "reservationhandler@gmail.com";
  final applicationPassword = "knkagbcynvuwycxn";
  UsersRepository userRepository = UsersRepository();
  ReservationsRepository reservationRepository = ReservationsRepository();
  FixedAppointmentsRepository fixedAppointmentsRepository =
      FixedAppointmentsRepository();
  late SharedPreferences prefs;

  static String? getShortDate(DateTime? date) {
    if (date == null) return null;
    return date
        .toString()
        .replaceFirst(RegExp(r'[0-2]{1}[0-9]{1}:00:00\.000'), "")
        .trim()
        .split("-")
        .reversed
        .take(2)
        .join("-");
  }

  static String? getWeekdayName(int? weekdayNumber) {
    if (weekdayNumber == null) return null;
    return switch (weekdayNumber) {
      1 => "Lunedì",
      2 => "Martedì",
      3 => "Mercoledì",
      4 => "Giovedì",
      5 => "Venerdì",
      _ => "Lunedì"
    };
  }

  void setAlreadyLoggedUser() async {
    prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString("username");
    if (username != null) {
      loggedUser = await userRepository.getUserByUsername(username);
      notifyListeners();
    }
  }

  void setEventController(BuildContext context) {
    eventController = CalendarControllerProvider.of(context).controller;
  }

  void emptyEventController() {
    if (eventController.events.isNotEmpty) {
      eventController.removeWhere((element) => true);
    }
  }

  Future<void> logUser(String username, String password) async {
    loggedUser = await userRepository.getUser(username, password);
    await prefs.setString("username", username);
    loggedTabController.index = 0;
    notifyListeners();
  }

  Future<void> logout() async {
    await prefs.remove("username");
    loggedUser = null;
    unloggedTabController.index = 0;
    notifyListeners();
  }

  Future<bool> SignUp(String name, String surname, String emailAddress,
      String username, String password) async {
    return await userRepository.addUser(
        name, surname, emailAddress, username, password);
  }

  Future<bool> SignIn(String username, String password) async {
    return (await userRepository.getUser(username, password)) != null;
  }

  Future<bool> changePassword(
      String username, String oldPassword, String confirmPassword) async {
    return await userRepository.changePassword(
        username, oldPassword, confirmPassword);
  }

  Future<String> getUserEmailAddress(String username) async {
    return await userRepository.getUserEmailAddress(username);
  }

  Future<void> addReservation(String username, String name, String surname,
      DateTime date, int startingHour) async {
    await reservationRepository.addReservation(
        username, name, surname, date, startingHour);
  }

  Future<void> removeReservation(String username, DateTime date) async {
    await reservationRepository.removeReservation(username, date);
  }

  Future<List<Reservation>> getDateReservations(DateTime date) async {
    return await reservationRepository.getDayReservations(date);
  }

  Future<List<Reservation>> getDayHourReservations(DateTime date) async {
    return await reservationRepository.getDayHourReservations(date);
  }

  Future<List<Reservation>> getFutureReservations(String username) async {
    return await reservationRepository.getFutureReservations(username);
  }

  Future<void> addFixedAppointment(
      String name, int weekday, int startingHour) async {
    await fixedAppointmentsRepository.addFixedAppointment(
        name, weekday, startingHour);
  }

  Future<void> removeFixedAppointment(String name) async {
    await fixedAppointmentsRepository.removeFixedAppointment(name);
  }

  Future<List<FixedAppointment>> getFixedAppointments() async {
    return await fixedAppointmentsRepository.getFixedAppointments();
  }

  Future<List<FixedAppointment>> getWeekdayFixedAppointments(
      int weekday) async {
    return await fixedAppointmentsRepository
        .getWeekdayFixedAppointments(weekday);
  }

  Future<bool> sameNameFixedAppointment(String name) async {
    return await fixedAppointmentsRepository.sameNameFixedAppointment(name);
  }

  Future<void> clearPastReservations() async {
    await reservationRepository.clearPastReservations();
  }
}
