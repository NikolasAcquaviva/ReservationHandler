import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:reservation_manager/change_password.dart';
import 'package:reservation_manager/model/app_state_model.dart';
import 'rules_tab.dart';
import 'signup_tab.dart';
import 'reservation_maker_tab.dart';
import 'fixed_appointments.dart';
import 'login.dart';
import 'reservation.dart';
import 'package:provider/provider.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ChangeNotifierProvider<AppStateModel>(
      create: (_) => 
        AppStateModel()..setAlreadyLoggedUser(),
      child: CalendarControllerProvider(
          controller: EventController(), child: const MyApp())));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
   
    return const CupertinoApp(
      title: 'Reservation Handler',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: [Locale('it', '')],
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  List<PullDownMenuEntry> DropdownItems(
      AppStateModel appState, BuildContext context) {
    if (appState.loggedUser != null) {
      return [
        appState.loggedUser!.isAdmin
            ? PullDownMenuItem(
                title: 'Gestione Appuntamenti Fissi',
                onTap: () => {
                      Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const FixedAppointmentsPage(),
                          ))
                    })
            : PullDownMenuItem(
                title: 'I miei appuntamenti',
                onTap: () => {
                      Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => const ReservationPage(),
                              title:
                                  "Appuntamenti di ${appState.loggedUser!.username}"))
                    }),
        PullDownMenuDivider.large(),
        PullDownMenuItem(
            title: 'Cambio password',
            onTap: () {
              Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => const ChangePasswordPage(),
                      title: 'Aggiornamento Password'));
            }),
        const PullDownMenuDivider.large(),
        PullDownMenuItem(
            title: 'Logout',
            onTap: () async {
              await appState.logout();
              if(context.mounted){Navigator.pushAndRemoveUntil(
                  context,
                  CupertinoPageRoute(builder: (context) => const MyHomePage()),
                  (route) => false);}
            })
      ];
    } else {
      return [
        PullDownMenuItem(
            title: 'Login',
            onTap: () => {
                  Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => const LoginPage()))
                      .then((value) {
                    appState.unloggedTabController.index = 0;
                  })
                }),
        //const PullDownMenuDivider.large(),
      ];
    }
  }

  Widget DropDown(AppStateModel appState) {
    return PullDownButton(
      itemBuilder: (context) => DropdownItems(appState, context),
      position: PullDownMenuPosition.automatic,
      buttonBuilder: (context, showMenu) => CupertinoButton(
          onPressed: showMenu,
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.person_fill)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateModel>(builder: (context, appState, child) {
      appState.setEventController(context);
      return appState.loggedUser != null
          ? CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                  middle: const Text('Reservation Handler'),
                  trailing: DropDown(appState)),
              child: CupertinoTabScaffold(
                controller: appState.loggedTabController,
                tabBar: CupertinoTabBar(items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.info_circle), label: 'Regole'),
                  BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.calendar_badge_plus),
                      label: "Prenotazione")
                ]),
                tabBuilder: (context, index) {
                  return switch (index) {
                    0 => CupertinoTabView(
                        builder: (context) =>
                            const CupertinoPageScaffold(child: RulesTab())),
                    1 => CupertinoTabView(
                        builder: (context) => const CupertinoPageScaffold(
                            child: ReservationMakerTab())),
                    _ => throw Exception('Invalid index $index')
                  };
                },
              ))
          : CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                  middle: const Text('Reservation Handler'),
                  trailing: DropDown(appState)),
              child: CupertinoTabScaffold(
                controller: appState.unloggedTabController,
                tabBar: CupertinoTabBar(items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.info_circle),
                      label: 'Informazioni'),
                  BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.doc_person),
                      label: "Registrazione")
                ]),
                tabBuilder: (context, index) {
                  return switch (index) {
                    0 => CupertinoTabView(
                        builder: (context) =>
                            const CupertinoPageScaffold(child: RulesTab())),
                    1 => CupertinoTabView(
                        builder: (context) =>
                            const CupertinoPageScaffold(child: SignUpTab())),
                    _ => throw Exception('Invalid index $index')
                  };
                },
              ));
    });
  }
}
