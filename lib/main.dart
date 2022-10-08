import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hm305p_remote/HM305PInterface.dart';
import 'test.dart';

import 'HM305PConnector.dart';

const SERVICE_ID = "0f50032d-cc47-407c-9f1a-a3a28a680c1e";

void main() async {
  runApp(MyApp());
  //await testStreams();
}

class MyApp extends StatelessWidget {
  HM305PInterface _iface;
  MyApp({super.key}): this._iface = HM305PInterface();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HM305P Remote',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(_iface, title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  HM305PInterface _iface;

  MyHomePage(this._iface, {super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  _MyHomePageState();

  late void Function() _notificationCallback = () {
    setState(() {
    });
  };

  @override
  void initState() {
    super.initState();
    widget._iface.addListener(_notificationCallback);
  }

  @override
  void dispose() {
    widget._iface.removeListener(_notificationCallback);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          ElevatedButton(child: Text("Autoconnect"), onPressed: () async {
            await widget._iface.autoconnect();
          },),
          ElevatedButton(child: Text("Turn on"), onPressed: widget._iface.isConnected() ? () async {
            await widget._iface.turnOn();
          } : null,),
          ElevatedButton(child: Text("Turn off"), onPressed: widget._iface.isConnected() ? () async {
            await widget._iface.turnOff();
          } : null,),
        ],
      ),
    );
  }
}
