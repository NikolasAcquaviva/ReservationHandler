import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:provider/provider.dart';
import 'package:reservation_manager/main.dart';
import 'package:reservation_manager/model/app_state_model.dart';
import 'model/users_repository.dart';
import 'package:mailer/smtp_server.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginPageState extends State<LoginPage> {
  String? username;
  String? password;
  UsersRepository usersRepository = UsersRepository();
  late AppStateModel appState;
  final formKey = GlobalKey<FormState>();

  String generatePassword(int length) {
    var rand = Random.secure();
    var values = List<int>.generate(length, (index) => rand.nextInt(255));
    String base64Password = base64UrlEncode(values);
    return base64Password.substring(0, base64Password.length - 2);
  }

  sendPasswordRecoveryEmail(String username) async {
    final smtpServer =
        gmail(appState.handlerEmailAddress, appState.applicationPassword);
    String userEmail = await appState.getUserEmailAddress(username);
    String generatedPassword = generatePassword(8);
    final message = Message()
      ..from = Address(appState.handlerEmailAddress)
      ..recipients.add(userEmail)
      ..subject = "Aggiornamento Password"
      ..html =
          "<h1>Abbiamo aggiornato la tua password!</h1>\n<p>Ciao $username!</p><br><p>La tua nuova password è:</p><br><p><b>$generatedPassword</b></p>";

    await send(message, smtpServer);
    await appState.changePassword(username, "", generatedPassword);
  }

  Widget buildUsernameField(bool forgotten) {
    return CupertinoTextFormFieldRow(
        prefix: const SizedBox(
            width: 40,
            child: Icon(CupertinoIcons.person_solid,
                color: CupertinoColors.inactiveGray, size: 28)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        autofocus: true,
        textInputAction:
            forgotten ? TextInputAction.done : TextInputAction.next,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            border: Border.all(
                color: CupertinoColors.inactiveGray,
                width: 1.0,
                style: BorderStyle.solid)),
        placeholder: 'Username',
        onChanged: (newUsername) {
          setState(() {
            username = newUsername;
          });
        },
        validator: (input) {
          return (input == null || input.isEmpty)
              ? "Compila questo campo"
              : null;
        });
  }

  Widget buildPasswordField() {
    return CupertinoTextFormFieldRow(
        prefix: const SizedBox(
            width: 40,
            child: Icon(CupertinoIcons.lock_fill,
                color: CupertinoColors.inactiveGray, size: 28)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        textInputAction: TextInputAction.done,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
        obscureText: true,
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            border: Border.all(
                color: CupertinoColors.inactiveGray,
                width: 1.0,
                style: BorderStyle.solid)),
        placeholder: 'Password',
        onChanged: (newPassword) {
          setState(() {
            password = newPassword;
          });
        },
        onFieldSubmitted: (value) async {
          final form = formKey.currentState!;

          if (form.validate()) {
            bool successfulSignIn =
                await appState.SignIn(username!.trim(), password!);
            if (!successfulSignIn) {
              Fluttertoast.showToast(
                  msg: "Le credenziali sono incorrette!",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.TOP,
                  webPosition: "center",
                  timeInSecForIosWeb: 2,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0);
            } else {
              form.reset();
              await appState.logUser(username!, password!);
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => const MyHomePage()),
                    (route) => false);
              }
            }
          }
        },
        validator: (input) {
          return (input == null || input.isEmpty)
              ? "Compila questo campo"
              : null;
        });
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text("Autenticazione"),
        )
      ],
      body: Form(
        key: formKey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            CupertinoFormSection(
              margin: const EdgeInsets.all(12),
              backgroundColor: Colors.transparent,
              children: [buildUsernameField(false), buildPasswordField()],
            ),
            const SizedBox(height: 10),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: double.infinity,
                child: CupertinoButton(
                    child: const Text('Ho dimenticato la password'),
                    onPressed: () {
                      Navigator.push(
                          context,
                          CupertinoModalPopupRoute(    
                              builder: (context) => CupertinoActionSheet(

                                    title: const Center(
                                        child: Text("Recupero Password")),
                                    message: Center(
                                        child: Column(
                                      children: [
                                        const Text(
                                            "Inserisci il tuo username per ricevere una nuova password all'indirizzo email registrato."),
                                        buildUsernameField(true)
                                      ],
                                    )),
                                    actions: <CupertinoActionSheetAction>[
                                      CupertinoActionSheetAction(
                                          isDefaultAction: true,
                                          onPressed: () async {
                                            if ((await appState.userRepository
                                                    .getUserByUsername(
                                                        username!)) ==
                                                null) {
                                              Fluttertoast.showToast(
                                                  msg:
                                                      "Questo utente non esiste!",
                                                  toastLength:
                                                      Toast.LENGTH_SHORT,
                                                  gravity: ToastGravity.TOP,
                                                  webPosition: "center",
                                                  timeInSecForIosWeb: 1,
                                                  backgroundColor: Colors.red,
                                                  textColor: Colors.white,
                                                  fontSize: 16.0);
                                              return;
                                            }
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                            }
                                            await sendPasswordRecoveryEmail(
                                                username!);
                                          },
                                          child: const Text("Ricevi email")),
                                      CupertinoActionSheetAction(
                                          isDefaultAction: true,
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Annulla"))
                                    ],
                                  )));
                    })),
            const SizedBox(height: 20),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: double.infinity,
                child: CupertinoButton.filled(
                    child: const Text('Login'),
                    onPressed: () async {
                      final form = formKey.currentState!;

                      if (form.validate()) {
                        bool successfulSignIn =
                            await appState.SignIn(username!.trim(), password!);
                        if (!successfulSignIn) {
                          Fluttertoast.showToast(
                              msg: "Le credenziali sono incorrette!",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.TOP,
                              webPosition: "center",
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 16.0);
                        } else {
                          form.reset();
                          await appState.logUser(username!, password!);
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                                context,
                                CupertinoPageRoute(
                                    builder: (context) => const MyHomePage()),
                                (route) => false);
                          }
                        }
                      }
                    })),
          ],
        ),
      ),
    ));
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() {
    return LoginPageState();
  }
}
