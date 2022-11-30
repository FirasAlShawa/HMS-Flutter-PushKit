import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huawei_push/huawei_push.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _token = "";
  int badgeNum = 0;
  List<String> list = [];

// #region HMS Push - Get Token

  // #region Get Token
  void _onTokenEvent(String event) {
    setState(() {
      _token = event;
    });

    print("Token Event : " + _token);
  }

  void _onTokenError(Object error) {
    PlatformException e = error as PlatformException;
    print("TokenErrorEvent" + e.message!);
  }

  Future<void> initTokenStream() async {
    if (!mounted) return;
    Push.getTokenStream.listen(_onTokenEvent, onError: _onTokenError);
  }

  void getToken() {
    Push.getToken("");
  }
  // #endregion

  // #region ReceiveDataMessage
  Future<void> initMessageStream() async {
    print("initMessageStream before");
    if (!mounted) return;
    print("initMessageStream is mounted");
    Push.onMessageReceivedStream.listen(_onMessageReceived);
  }

  void _onMessageReceived(RemoteMessage remoteMessage) {
    print("_onMessageReceived");
    String? data = remoteMessage.data;
    // ignore: avoid_print
    print("firas data $data");
    setState(() {
      ++badgeNum;
      list.add(data.toString());
    });
    log("Data => ${data}");
  }

  void _onMessageReceiveError() {
    print("_onMessageReceiveError");
  }
  // #endregion

  // #region onNotificaionOpenApp
  Future<void> initNotificationListener() async {
    if (!mounted) return;
    Push.onNotificationOpenedApp
        .listen((remoteMessage) => _onNotificationOpenedApp(remoteMessage));
  }

  void _onNotificationOpenedApp(dynamic initialNotification) {
    if (initialNotification != null) {
      Map<String, dynamic> map = Map<String, dynamic>.from(initialNotification);
      setState(() {
        ++badgeNum;
        list.add(
            "MyApp:${map['extras']['name']},toyou${map['extras']['message']}");
      });
      print("onNotificationOpenedApp " + map['extras']['name'].toString());
      print("onNotificationOpenedApp " + map['extras']['message'].toString());
    }
  }

  // #endregion
// #endregion

  @override
  void initState() {
    super.initState();
    initTokenStream();
    initMessageStream();
    initNotificationListener();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Badge(
              badgeContent: Text(
                badgeNum.toString(),
                style: const TextStyle(color: Colors.white),
              ),
              badgeColor: Colors.blue,
              child: const Icon(
                Icons.add,
                size: 50.0,
              ),
            ),
            const Text('HMS Push Kit'),
            ElevatedButton(
                onPressed: getToken, child: const Text("Get Push Token")),
            TextButton(
              onPressed: () => showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('AlertDialog Title'),
                  content: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        return Text(list[index].toString());
                      }),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'Cancel'),
                      child: const Text('Close'),
                    )
                  ],
                ),
              ),
              child: const Text('Show Dialog'),
            )
          ],
        ),
      ),
    );
  }
}
