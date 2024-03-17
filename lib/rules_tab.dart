import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RulesTab extends StatelessWidget {
  const RulesTab({super.key});

  @override
  Widget build(BuildContext context) {
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
                      title:
                          const Text("Regole e Informazioni"))
                ],
            body: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ListView(
                    children: const [
                      Text(
                          "Il primo passo per poter prenotare degli appuntamenti è quello di registrarsi ed eseguire il login."),
                      Text(
                          "A questo proposito è importante inserire l'indirizzo email corretto poiché verrà utilizzato per notificare gli utenti sui prossimi appuntamenti."),
                      Text(
                          "Una volta eseguito il login, cliccare sulla tab \"Prenotazione\" in basso a destra e scegliere un giorno nel quale prenotare un appuntamento."),
                      Text(
                          "È possibile scegliere un giorno partendo dal momento attuale fino al venerdì della settimana successiva.­"),
                      Text(
                          "Una volta selezionato un giorno sarà possibile selezionare un orario tra quelli lavorativi per aggiungere una prenotazione.Ad esempio, per selezionare l'orario 10:00 bisogna cliccare nello spazio bianco tra le linee che indicano gli orari 10:00 e 11:00."),
                      Text(
                          "Gli appuntamenti iniziano sempre all'ora in punto e durano un'ora esatta. Gli orari disponibili sono i seguenti:"),
                      Text("Mattina:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                          "Dalle ore 8:00 alle ore 12:00 con l'ultimo appuntamento disponibile dalle 12:00 alle 13:00."),
                      Text("Pomeriggio:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                          "Dalle ore 16:00 alle ore 19:00 con l'ultimo appuntamento disponibile dalle 19:00 alle 20:00."),
                      Text(
                          "Il venerdì sono disponibili solamente gli orari mattutini."),
                      Text(
                          "È possibile prenotarsi in uno stesso orario al massimo in 3 persone contemporaneamente.")
                    ]))));
  }
}
