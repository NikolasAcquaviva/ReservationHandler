class Reservation{
  const Reservation(
    {
      required this.username,
      required this.name,
      required this.surname,
      required this.date,
      required this.startingHour
    }
  );

  final String username;
  final String name;
  final String surname;
  final DateTime date;
  final int startingHour;
}