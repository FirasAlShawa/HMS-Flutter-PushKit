import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huawei_push/huawei_push.dart';

void backgroundMessageCallback(RemoteMessage remoteMessage) async {
  print("---------------------------------------------");
  String? data = remoteMessage.data;
  if (data != null) {
    debugPrint(
      'Background message is received, sending local notification.',
    );
    print(data);
    //decode the data payload
    var decodePayload = jsonDecode(data);
    //get the flat params first
    Map<String, dynamic> map = Map<String, dynamic>.from(decodePayload);
    //get the data map after that
    Map<String, dynamic> datamap = Map<String, dynamic>.from(map['data']);

    Push.localNotification(
      <String, dynamic>{
        // HMSLocalNotificationAttr.TITLE: map['title'],
        // HMSLocalNotificationAttr.MESSAGE: map['message'],
        // HMSLocalNotificationAttr.DATA: "Nigga!",

        HMSLocalNotificationAttr.TITLE: 'Notification Title',
        HMSLocalNotificationAttr.MESSAGE: 'Notification Message',
        HMSLocalNotificationAttr.DATA: {"key1": "value1", "key2": "nigga2"}
      },
    );
  } else {
    debugPrint(
      'Background message is received. There is no data in the message.',
    );
  }
}

// Future<void> push_setup() async {
//   bool backgroundMessageHandler =
//       await Push.registerBackgroundMessageHandler(backgroundMessageCallback);
//   print("backgroundMessageHandler registered: $backgroundMessageHandler");
// }

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  // void _onNotificationOpenedApp(RemoteMessage remoteMessage) {
  //   if (remoteMessage != null) {
  //     var decodedobj = json.decode(remoteMessage.toMap().toString());
  //     print("_onNotificationOpenedApp => ${decodedobj.toString()}");
  //   }
  // }

  void _onNotificationOpenedApp(dynamic initialNotification) {
    print("it is clicked!");
    if (initialNotification != null) {
      Map<String, dynamic> map = Map<String, dynamic>.from(initialNotification);
      setState(() {
        ++badgeNum;
        // list.add(
        //     "MyApp:${map['extras']['name']},toyou${map['erxtras']['message']}");
      });
      Map<String, dynamic> mapExtras = Map<String, dynamic>.from(map["extras"]);

      map.forEach((key, value) {
        print("\n myNotificaitonMap =>  $key : ${value.toString()}\n");
      });

      mapExtras.forEach((key, value) {
        print("\n myNotificaitonMap =>  $key : ${value.toString()}\n");
      });
    }
  }

  // #endregion

  void myRegisterBackgroundMessageHandler() async {
    bool backgroundMessageHandler = await Push.registerBackgroundMessageHandler(
      backgroundMessageCallback,
    );
    debugPrint(
      'backgroundMessageHandler registered: $backgroundMessageHandler',
    );
  }

  void getInitialNotification() async {
    dynamic initialNotification = await Push.getInitialNotification();

    if (initialNotification == null) {
      print("getInitialNotification is : $initialNotification");
    } else {
      Map<String, dynamic> map = Map<String, dynamic>.from(initialNotification);

      Map<String, dynamic> mapExtras =
          Map<String, dynamic>.from(map["extras"]["notification"]);

      Map<String, dynamic> dataMap =
          Map<String, dynamic>.from(jsonDecode(mapExtras["data"]));

      dataMap.forEach((key, value) {
        print(
            "\n getInitialNotification =>  $key : ${value.toString()} ${value.runtimeType}\n");
      });

      if (mounted) {
        setState(() {
          ++badgeNum;
          list.add(dataMap.toString());
        });
      }
    }
    // if (initialNotification != "null") {

    // } else {
    // }
  }
// #endregion

  @override
  void initState() {
    super.initState();
    initTokenStream();
    initMessageStream();
    initNotificationListener();
    myRegisterBackgroundMessageHandler();
    getInitialNotification();
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
            Text(_token.toString()),
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
