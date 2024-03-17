class User {
  User(
    {
      required this.name,
      required this.surname,
      required this.emailAddress,
      required this.username,
      required this.password,
      required this.isAdmin
    }
  );

  final String name;
  final String surname;
  final String emailAddress;
  final String username;
  String password;
  final bool isAdmin;  
}
