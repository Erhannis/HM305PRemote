import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hm305p_remote/HM305PInterface.dart';
import 'package:prompt_dialog/prompt_dialog.dart';
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
      home: MyHomePage(_iface, title: 'HM305P Remote'),
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

class Token {
  
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
  Set<Token> _activeAutoconnects = {};
  
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
          Row(children: [
            Expanded(flex: 1, child: ElevatedButton(child: Text("Autoconnect"), onPressed: () async {
              var t = Token();
              _activeAutoconnects.add(t);
              setState(() {});
              try {
                await widget._iface.autoconnect();
              } finally {
                _activeAutoconnects.remove(t);
                setState(() {});
              }
            },)),
            if (_activeAutoconnects.isNotEmpty) Icon(Icons.hourglass_top),
          ]),
          Text(textAlign: TextAlign.center, "Connected to server: ${widget._iface.isConnected()}"),
          if (widget._iface.isConnected()) Text(textAlign: TextAlign.center, "Server connected to PSU: ${widget._iface.serverConnectedToPSU}"),
          if (widget._iface.isConnected() && widget._iface.serverConnectedToPSU) ...[
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
            Table(border: TableBorder(horizontalInside: BorderSide(color: Colors.black)), children: [ // I am struggling not to use impolite words in the direction of Flutter's UI framework.  "wrap_contents" shouldn't be a difficult behavior to achieve.
              TableRow(children: [Align(alignment: Alignment.bottomRight, child: Text("Live voltage: ")),Text("${widget._iface.liveVoltage.toStringAsFixed(3)}"),const Text("")]),
              TableRow(children: [Align(alignment: Alignment.bottomRight, child: Text("Live current: ")),Text("${widget._iface.liveCurrent.toStringAsFixed(3)}"),const Text("")]),
              TableRow(children: [Align(alignment: Alignment.bottomRight, child: Text("Set voltage: ")),Text("${widget._iface.voltageSetpoint.toStringAsFixed(3)}"),ElevatedButton(child: Text("Edit"), onPressed: () async {await editField(widget._iface.voltageSetpoint, widget._iface.setVoltageSetpoint);},)]),
              TableRow(children: [Align(alignment: Alignment.bottomRight, child: Text("Set current: ")),Text("${widget._iface.currentSetpoint.toStringAsFixed(3)}"),ElevatedButton(child: Text("Edit"), onPressed: () async {await editField(widget._iface.currentSetpoint, widget._iface.setCurrentSetpoint);},)]),
              TableRow(children: [Align(alignment: Alignment.bottomRight, child: Text("Voltage overprotect: ")),Text("${widget._iface.voltageOverprotect.toStringAsFixed(3)}"),ElevatedButton(child: Text("Edit"), onPressed: () async {await editField(widget._iface.voltageOverprotect, widget._iface.setVoltageOverprotect);},)]),
              TableRow(children: [Align(alignment: Alignment.bottomRight, child: Text("Current overprotect: ")),Text("${widget._iface.currentOverprotect.toStringAsFixed(3)}"),ElevatedButton(child: Text("Edit"), onPressed: () async {await editField(widget._iface.currentOverprotect, widget._iface.setCurrentOverprotect);},)]),
            ]),
          ],
        ],
      ),
    );
  }

  Future<void> editField(double initial, Future<void> Function(double x) commitCallback) async {
    var ret = await prompt(context, initialValue: "$initial");
    if (ret != null) {
      try {
        var d = double.parse(ret);
        await commitCallback(d);
      } catch (e) {
        log("Error editing field: $e");
      }
    }
  }
}