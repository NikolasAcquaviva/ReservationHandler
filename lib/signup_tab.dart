import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reservation_manager/model/app_state_model.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:email_validator/email_validator.dart';

class SignUpTabState extends State<SignUpTab> {
  String? name; 
  String? surname;
  String? emailAddress;
  String? username;
  String? password;
  final formKey = GlobalKey<FormState>();
  late AppStateModel appState;

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
        placeholder: 'Nome',
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

  Widget buildSurnameField() {
    return CupertinoTextFormFieldRow(
        prefix: const SizedBox(
            width: 40,
            child: Icon(CupertinoIcons.doc_person_fill,
                color: CupertinoColors.inactiveGray, 
                              size: 28)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        textCapitalization: TextCapitalization.words,
        textInputAction: 
                TextInputAction.next,
                    autovalidateMode
                    : AutovalidateMode.onUserInteraction,
                    autocorrect: false,
                    decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            border: Border.all(
                color: CupertinoColors.inactiveGray,
                width: 1.0,
                style: BorderStyle.solid)),
        placeholder: 'Cognome',
        onChanged: (newSurname) {
          setState(() {
            surname = newSurname;
          });
        },
        validator: (input) {
          return (input == null || input.isEmpty)
              ? "Compila questo campo"
              : null;
        });
  }

  Widget buildEmailField(){
    return CupertinoTextFormFieldRow(
        prefix: const SizedBox(
            width: 40,
            child: Icon(CupertinoIcons.mail_solid,
                color: CupertinoColors.inactiveGray, size: 28)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        textCapitalization: TextCapitalization.none,
        textInputAction: TextInputAction.next,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        autocorrect: false,
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            border: Border.all(
                color: CupertinoColors.inactiveGray,
                width: 1.0,
                style: BorderStyle.solid)),
        placeholder: 'Indirizzo email',
        onChanged: (newEmail) {
          setState(() {
            emailAddress = newEmail;
          });
        },
        validator: (input) {
          return (input == null || input.isEmpty)
              ? "Compila questo campo"
              : (!EmailValidator.validate(input) 
                ? "Indirizzo email non valido"
                : null);
        });
  }

  Widget buildUsernameField() {
    return CupertinoTextFormFieldRow(
        prefix: const SizedBox(
            width: 40,
            child: Icon(CupertinoIcons.person_fill,
                color: CupertinoColors.inactiveGray, size: 28)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        textInputAction: TextInputAction.next,
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
            bool successfulSignUp =
                await appState.SignUp(name!, surname!, emailAddress!, username!, password!);
            if (!successfulSignUp) {
              Fluttertoast.showToast(
                  msg: "Un utente con questo username è gia esistente!",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.TOP,
                  webPosition: "center",
                  timeInSecForIosWeb: 2,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0);
            } else {
              form.reset();
              appState.unloggedTabController.index = 0;
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
            title: const Text("Registrazione"))
      ],
      body: Form(
        key: formKey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            CupertinoFormSection(
              margin: const EdgeInsets.all(12),
              backgroundColor: Colors.transparent,
              children: [
                buildNameField(),
                buildSurnameField(),
                buildEmailField(),
                buildUsernameField(),
                buildPasswordField()
              ],
            ),
            const SizedBox(height: 20),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: double.infinity,
                child: CupertinoButton.filled(
                    child: const Text('Crea Account'),
                    onPressed: () async {
                      final form = formKey.currentState!;

                      if (form.validate()) {
                        bool successfulSignUp = await appState.SignUp(
                            name!, surname!, emailAddress!, username!, password!);
                        if (!successfulSignUp) {
                          Fluttertoast.showToast(
                              msg:
                                  "Un utente con questo username è gia esistente!",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.TOP,
                              webPosition: "center",
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 16.0);
                        } else {
                          form.reset();
                          appState.unloggedTabController.index = 0;
                        }
                      }
                    }))
          ],
        ),
      ),
    ));
  }
}

class SignUpTab extends StatefulWidget {
  const SignUpTab({super.key});

  @override
  State<SignUpTab> createState() {
    return SignUpTabState();
  }
}
