import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'test.dart';

import 'HM305PConnector.dart';

const SERVICE_ID = "0f50032d-cc47-407c-9f1a-a3a28a680c1e";

void main() async {
  runApp(const MyApp());
  await testExchanger4();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HM305P Remote',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    //String type = '_wonderful-service._tcp';
    String type = '_0f50032d-cc47._tcp';
    //String type = '_0f50032d-cc47-407c-9f1a-a3a28a680c1e._http._tcp.local.';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(child: Text("scan"), onPressed: () async {
              await autoconnect();
            },),
          ],
        ),
      ),
    );
  }
}
