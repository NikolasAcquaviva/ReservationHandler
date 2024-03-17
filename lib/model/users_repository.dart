import 'user.dart';
import 'package:firebase_database/firebase_database.dart';

class UsersRepository {
  DatabaseReference dbReference = FirebaseDatabase.instance.ref('users');

  Future<String> getUserEmailAddress(String username) async {
    DataSnapshot first = await dbReference.get();
    if (!first.exists) return "";
    DataSnapshot snapshot =
        await dbReference.child('$username/emailAddress').get();
    if (snapshot.exists) {
      return snapshot.value.toString();
    } else {
      return "";
    }
  }

  Future<User?> getUser(String username, String password) async {
    DataSnapshot first = await dbReference.get();
    if (!first.exists) return null;
    DataSnapshot snapshot = await dbReference.child(username).get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> result = snapshot.value as Map<dynamic, dynamic>;
      User user = User(
          name: result['name'],
          surname: result['surname'],
          emailAddress: result['emailAddress'],
          username: result['username'],
          password: result['password'],
          isAdmin: result['isAdmin']);
      if (user.password == password) {
        return user;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  Future<User?> getUserByUsername(String username) async {
    DataSnapshot first = await dbReference.get();
    if (!first.exists) return null;
    DataSnapshot snapshot = await dbReference.child(username).get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> result = snapshot.value as Map<dynamic, dynamic>;
      return User(
          name: result['name'],
          surname: result['surname'],
          emailAddress: result['emailAddress'],
          username: result['username'],
          password: result['password'],
          isAdmin: result['isAdmin']);
    } else {
      return null;
    }
  }

  Future<void> addUserToDb(String name, String surname, String emailAddress,
      String username, String password) async {
    DatabaseReference addingUserReference =
        FirebaseDatabase.instance.ref("users/$username");
    await addingUserReference.set({
      'name': name,
      'surname': surname,
      'emailAddress': emailAddress,
      'username': username,
      'password': password,
      'isAdmin': false
    });
  }

  Future<bool> addUser(String name, String surname, String emailAddress,
      String username, String password) async {
    DataSnapshot first = await dbReference.get();
    if (!first.exists) {
      await addUserToDb(name, surname, emailAddress, username, password);
      return true;
    } else {
      DataSnapshot snapshot = await dbReference.child(username).get();
      if (snapshot.exists) {
        return false;
      } else {
        await addUserToDb(name, surname, emailAddress, username, password);
        return true;
      }
    }
  }

  Future<bool> changePassword(
      String username, String oldPassword, String confirmPassword) async {
    DataSnapshot snapshot = await dbReference.child(username).get();
    if (!snapshot.exists) {
      return false;
    } else {
      Map<dynamic, dynamic> userMap = snapshot.value as Map<dynamic, dynamic>;
      User user = User(
          name: userMap['name'],
          surname: userMap['surname'],
          emailAddress: userMap['emailAddress'],
          username: userMap['username'],
          password: userMap['password'],
          isAdmin: userMap['isAdmin']);
      if (oldPassword != "" && user.password != oldPassword) {
        return false;
      }
      DatabaseReference updatingReference = snapshot.ref;
      await updatingReference.update({"password": confirmPassword});
      return true;
    }
  }
}
