import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:reservation_manager/main.dart';
import 'model/app_state_model.dart';

class ChangePasswordPageState extends State<ChangePasswordPage> {
  final formKey = GlobalKey<FormState>();
  String? oldPassword, newPassword, confirmPassword;
  late AppStateModel appState;
  Widget buildOldPasswordField() {
    return CupertinoTextFormFieldRow(
        prefix: const SizedBox(
            width: 40,
            child: Icon(CupertinoIcons.lock_open_fill,
                color: CupertinoColors.inactiveGray, size: 28)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        textInputAction: TextInputAction.next,
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
        placeholder: 'Inserisci vecchia password',
        onChanged: (input) {
          setState(() {
            oldPassword = input;
          });
        },
        validator: (input) {
          return (input == null || input.isEmpty)
              ? "Compila questo campo"
              : null;
        });
  }

  Widget buildNewPasswordField() {
    return CupertinoTextFormFieldRow(
        prefix: const SizedBox(
            width: 40,
            child: Icon(CupertinoIcons.lock_fill,
                color: CupertinoColors.inactiveGray, size: 28)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        textInputAction: TextInputAction.next,
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
        placeholder: 'Inserisci nuova password',
        onChanged: (input) {
          setState(() {
            newPassword = input;
          });
        },
        validator: (input) {
          if (input == null || input.isEmpty) {
            return "Compila questo campo";
          } else if (input == oldPassword) {
            return "La nuova password non può essere uguale alla precedente!";
          } else {
            return null;
          }
        });
  }

  Widget buildConfirmPasswordField() {
    return CupertinoTextFormFieldRow(
        prefix: const SizedBox(
            width: 40,
            child: Icon(CupertinoIcons.lock_rotation,
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
        placeholder: 'Conferma nuova password',
        onChanged: (input) {
          setState(() {
            confirmPassword = input;
          });
        },
        onFieldSubmitted: (value) async {
          final form = formKey.currentState!;
          if (form.validate()) {
            bool successfulPasswordChange = await appState.changePassword(
                appState.loggedUser!.username, oldPassword!, confirmPassword!);
            if (!successfulPasswordChange) {
              Fluttertoast.showToast(
                  msg: "La vecchia password inserita non è corretta!",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.TOP,
                  webPosition: "center",
                  timeInSecForIosWeb: 2,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0);
            } else {
              await appState.logout();
              if(context.mounted){
                Navigator.pushAndRemoveUntil(
                  context,
                  CupertinoPageRoute(builder: (context) => const MyHomePage()),
                  (route) => false);
              }
            }
          }
        },
        validator: (input) {
          if (input == null || input.isEmpty) {
            return "Compila questo campo";
          } else if (input != newPassword) {
            return "La nuova password non coincide con la conferma!";
          } else {
            return null;
          }
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
            title: const Text("Aggiornamento Password"))
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
                buildOldPasswordField(),
                buildNewPasswordField(),
                buildConfirmPasswordField()
              ],
            ),
            const SizedBox(height: 20),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: double.infinity,
                child: CupertinoButton.filled(
                    child: const Text('Aggiorna Password'),
                    onPressed: () async {
                      final form = formKey.currentState!;
                      if (form.validate()) {
                        bool successfulPasswordChange = await appState.changePassword(
                            appState.loggedUser!.username,
                            oldPassword!,
                            confirmPassword!);
                        if (!successfulPasswordChange) {
                          Fluttertoast.showToast(
                              msg:
                                  "La vecchia password inserita non è corretta!",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.TOP,
                              webPosition: "center",
                              timeInSecForIosWeb: 2,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 16.0);
                        } else {
                          await appState.logout();
                          if(context.mounted){
                            Navigator.pushAndRemoveUntil(
                              context,
                              CupertinoPageRoute(
                                  builder: (context) => const MyHomePage()),
                              (route) => false);
                          }
                        }
                      }
                    }))
          ],
        ),
      ),
    ));
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() {
    return ChangePasswordPageState();
  }
}
