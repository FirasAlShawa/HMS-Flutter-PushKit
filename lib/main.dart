import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';

import 'package:badges/badges.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:hms_flutter_push/DataModel.dart';
import 'package:huawei_push/huawei_push.dart';

void backgroundMessageCallback(RemoteMessage remoteMessage) async {
  DataModel model = dataModelFromJson(remoteMessage.getData.toString());

  Push.localNotification(
    <String, dynamic>{
      HMSLocalNotificationAttr.TITLE: model.greeting,
      HMSLocalNotificationAttr.MESSAGE: model.instructions,
      HMSLocalNotificationAttr.DATA: model.toJson()
    },
  );
}

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
  List<DataModel> list = [];

// #region HMS Push

  // #region Get Token
  void _onTokenEvent(String event) async {
    setState(() {
      _token = event;
    });
  }

  void _onTokenError(Object error) {
    PlatformException e = error as PlatformException;
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
    if (!mounted) return;
    Push.onMessageReceivedStream.listen(_onMessageReceived);
  }

  void _onMessageReceived(RemoteMessage remoteMessage) {
    if (remoteMessage.data != null) {
      DataModel dataModel = dataModelFromJson(remoteMessage.data!);
      setState(() {
        ++badgeNum;
        list.add(dataModel);
      });
    }
    // DataModel dataModel = dataModelFromJson(map["extras"]["data"]);
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
      if (map["extras"]["data"] == null) {
        //get your data from the extra object
        String greeting = map["extras"]["greeting"];
        String instructions = map["extras"]["instructions"];

        DataModel dataModel =
            DataModel(greeting: greeting, instructions: instructions);
        setState(() {
          ++badgeNum;
          list.add(dataModel);
        });
      } else {}
    }
  }
  // #endregion

  // #region Register Background handler
  void myRegisterBackgroundMessageHandler() async {
    bool backgroundMessageHandler = await Push.registerBackgroundMessageHandler(
      backgroundMessageCallback,
    );
  }
  // #endregion

  // #region get local Notificaiton Remote Message payload
  void getInitialNotification() async {
    dynamic initialNotification = await Push.getInitialNotification();
    if (initialNotification != null) {
      // DataModel dataModel = dataModelFromJson(initialNotification.)

      try {
        Map<String, dynamic> map =
            Map<String, dynamic>.from(initialNotification);
        Map<String, dynamic> mapExtras =
            Map<String, dynamic>.from(map["extras"]["notification"]);
        DataModel dataModel = dataModelFromJson(mapExtras["data"]);
        if (mounted) {
          setState(() {
            ++badgeNum;
            list.add(dataModel);
          });
        }
      } catch (e) {
        Map<String, dynamic> map =
            Map<String, dynamic>.from(initialNotification);
        //get your data from the extra object
        String greeting = map["extras"]["greeting"];
        String instructions = map["extras"]["instructions"];

        DataModel dataModel =
            DataModel(greeting: greeting, instructions: instructions);
        setState(() {
          ++badgeNum;
          list.add(dataModel);
        });
      }
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
    myRegisterBackgroundMessageHandler();
    getInitialNotification();
  }

  final snackBar = const SnackBar(
    content: Text('Check the token in your clipboard'),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: Container(
        padding: EdgeInsets.all(16.0),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Badge(
                    badgeContent: Text(
                      badgeNum.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    badgeColor: Colors.blue,
                    child: const Icon(
                      Icons.notifications,
                      size: 100.0,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      getToken();
                      await Clipboard.setData(
                          ClipboardData(text: "Push Kit : $_token"));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Get and Copy\n Push Token"),
                    ),
                  ),
                ],
              ),
            ),
            list.length > 0
                ? Expanded(
                    child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      DataModel model = list[index];

                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.notifications_active_rounded),
                          title: Text(model.greeting),
                          subtitle: Text(model.instructions),
                          trailing: Icon(Icons.more_vert),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ))
                : const Expanded(child: Center(child: Text("Empty!")))
          ],
        ),
      ),
    ));
  }
}
