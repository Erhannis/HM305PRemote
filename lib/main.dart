import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hm305p_remote/HM305PInterface.dart';
import 'misc.dart';
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
    var state = widget._iface.state;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        padding: EdgeInsets.all(4),
        children: <Widget>[
          ElevatedButton(child: Text("Autoconnect"), onPressed: () async {
            await widget._iface.autoconnect();
          },),
          if (widget._iface.isConnected()) ...[
            ElevatedButton(style: ElevatedButton.styleFrom(
                backgroundColor: state ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                //shadowColor: Colors.greenAccent,
                //elevation: 3,
                //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
                minimumSize: Size(100, 100), //////// HERE
              ), child: Text(state ? "ON" : "OFF"), onPressed: widget._iface.isConnected() ? () async {
                if (state) {
                  await widget._iface.turnOff();
                } else {
                  await widget._iface.turnOn();
                }
            } : null,),
            Row(children: [Spacer(), ...transpose([
              [Text("Live voltage:"),Text("${widget._iface.liveVoltage.toStringAsFixed(3)}")],
              [Text("Live current:"),Text("${widget._iface.liveCurrent.toStringAsFixed(3)}")],
              [Text("Set voltage:"),Text("${widget._iface.voltageSetpoint.toStringAsFixed(3)}")],
              [Text("Set current:"),Text("${widget._iface.currentSetpoint.toStringAsFixed(3)}")],
            ]).map((e) => Column(children: e, crossAxisAlignment: CrossAxisAlignment.end,)).toList(), Spacer()]),
          ],
        ],
      ),
    );
  }
}
