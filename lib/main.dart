import 'dart:ffi';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:uuid/uuid.dart';
import 'package:websockets/global.dart';
import 'package:websockets/options.dart';
import 'package:websockets/rpc.dart';

void main() {
  runApp(Provider(
      create: (_) {
        var option = Options();
        option.load();
        return option;
      },
      child: const MyApp()));
}

Future<http.Response> createRoom(sessionId) {
  return http.post(
    Uri.parse("${Global.httpRpc}timer/create"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'X-Requested-With': 'XMLHttpRequest'
    },
    body: jsonEncode(<String, String>{
      'session': sessionId.toString(),
    }),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int time = 1;
  String _counter = "00:00:00";
  // String appSession = const Uuid().v1().toString();
  String appSession = "s68d4f98sd-05f1-654sd-8944-s98fsd45fs6df98";

  var alertStyle = AlertStyle(
    animationType: AnimationType.fromBottom,
    isCloseButton: false,
    isOverlayTapDismiss: false,
    descStyle: const TextStyle(fontWeight: FontWeight.bold),
    descTextAlign: TextAlign.start,
    animationDuration: const Duration(milliseconds: 400),
    alertBorder: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(0),
      side: const BorderSide(
        color: Colors.grey,
      ),
    ),
    titleStyle: const TextStyle(
      color: Colors.red,
    ),
    alertAlignment: Alignment.center,
  );

  @override
  void initState() {
    super.initState();
    loadWebSocket();
  }

  void loadWebSocket() async {
    // init rpc.
    if (!rpc.isLinked()) {
      print("room-$appSession");
      await rpc.init(Global.wsRpc, "room-$appSession");
    }
    rpc.addListener('room_timeleft', _timeLeft);
  }

  _timeLeft(res) {
    Map data = json.decode(res);
    print(data);
    setState(() {
      _counter = data['time_left'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey.shade900,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                _counter.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 70),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    createRoom(appSession);
                  });
                },
                child: const Text('Create Room'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                    )),
                    onPressed: () {
                      setState(() {
                        time--;
                        if (time == 0) time = -1;
                      });
                    },
                    child: const Icon(Icons.exposure_minus_1),
                  ),
                  Text(
                    time.toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 50),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                    )),
                    onPressed: () {
                      setState(() {
                        time++;
                        if (time == 0) time = 1;
                      });
                    },
                    child: const Icon(Icons.exposure_plus_1),
                  )
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(
                    fontSize: 25,
                    color: Colors.white,
                    height: 1,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 40),
                ),
                onPressed: () {
                  Alert(
                    context: context,
                    style: alertStyle,
                    type: AlertType.info,
                    title: "Timer",
                    desc: "Are you sure you wana update: ($time)",
                    buttons: [
                      DialogButton(
                          onPressed: () => Navigator.pop(context),
                          color: const Color.fromRGBO(0, 0, 0, 0),
                          radius: BorderRadius.circular(0.0),
                          child: const Text(
                            "close",
                            style: TextStyle(
                                color: Color.fromRGBO(0, 179, 134, 1.0),
                                fontSize: 20,
                                decoration: TextDecoration.underline),
                          )),
                      DialogButton(
                          color: const Color.fromRGBO(0, 179, 134, 1.0),
                          radius: BorderRadius.circular(0.0),
                          onPressed: () async {
                            final res = await httpPost(
                                "timer/time", appSession, {'time': time});
                            if (res.isOk) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(res.message),
                              ));
                              time = 1;
                            }
                            print({res.isOk, res.message, res.error});
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "update",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ))
                    ],
                  ).show();
                },
                child: const Text('Save'),
              ),
              const SizedBox(height: 24),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                          height: 1,
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 40),
                      ),
                      onPressed: () async {
                        final res = await httpPost(
                            "timer/status/pause", appSession, {});
                        if (res.isOk) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(res.message),
                          ));
                          time = 1;
                        }
                      },
                      child: const Text('Pause'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                          height: 1,
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 40),
                      ),
                      onPressed: () async {
                        final res =
                            await httpPost("timer/status/play", appSession, {});
                        if (res.isOk) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(res.message),
                          ));
                          time = 1;
                        }
                      },
                      child: const Text('Play'),
                    )
                  ])
            ],
          ),
        ));
  }
}
