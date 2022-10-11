import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:hm305p_remote/MessageSocket.dart';
import 'HM305PConnector.dart' as Connector;
import 'misc.dart';

class HM305PInterface extends ChangeNotifier {
  MessageSocket? _sock;

  bool serverConnectedToPSU = false;
  bool state = false;
  double liveVoltage = 0.0;
  double liveCurrent = 0.0;
  double voltageSetpoint = 0.0;
  double currentSetpoint = 0.0;
  double voltageOverprotect = 0.0;
  double currentOverprotect = 0.0;

  HM305PInterface() {
    unawaited(Future(() async {
      while (true) {
        await sleep(5000);
        if (_sock != null) {
          try {
            while (true) {
              var msg = String.fromCharCodes((await _sock!.recvMsg())!);
              log("state reader rx msg $msg");
              //zc.broadcast(f"voltageOverprotect:{voltageOverprotect}")
              //zc.broadcast(f"currentOverprotect:{currentOverprotect}")
              List<String> parts = msg.split(":");
              if (parts.length != 2) {
                log("rx unhandled message: $msg");
                continue;
              }
              try {
                switch (parts[0]) {
                  case "connected":
                    serverConnectedToPSU = parts[1] == "True";
                    break;
                  case "state":
                    state = parts[1] == "1";
                    break;
                  case "liveVoltage":
                    liveVoltage = double.parse(parts[1]);
                    break;
                  case "liveCurrent":
                    liveCurrent = double.parse(parts[1]);
                    break;
                  case "voltageSetpoint":
                    voltageSetpoint = double.parse(parts[1]);
                    break;
                  case "currentSetpoint":
                    currentSetpoint = double.parse(parts[1]);
                    break;
                  case "voltageOverprotect":
                    voltageOverprotect = double.parse(parts[1]);
                    break;
                  case "currentOverprotect":
                    currentOverprotect = double.parse(parts[1]);
                    break;
                }
                notifyListeners();
              } catch (e) {
                log("error parsing state message $msg : $e");
              }
            }
          } catch (e) {
            log("error in state reader: $e");
            try {
              await autoconnect();
            } catch (e2) {
              log("state reader failed to reconnect: $e2");
              //TODO ???
            }
          }
        }
      }
    }));
  }

  Future<bool> autoconnect() async {
    if (_sock != null) {
      await _sock!.close();
      _sock = null;
    }
    _sock = await Connector.autoconnect();
    notifyListeners();
    return _sock != null;
  }

  Future<void> disconnect() async {
    if (_sock != null) {
      await _sock!.close();
      notifyListeners();
    }
  }

  /**
   * Not very accurate - just reports whether we currently have a connection.  Doesn't have to be alive or nothin.
   */
  bool isConnected() {
    return _sock != null;
  }

  //TODO Apparently there's a call deep in socket code that throws an exception not returned to us, if the socket's disconnected and we write to it.
  //  I'm not sure there's a lot we can do about it, right now, but it messes things up royally.
  //  I'm going to ignore it for now.
  //  https://github.com/dart-lang/http/issues/551

  Future<void> turnOn() async {
    try {
      await _sock?.sendString("power=true");
    } catch (e) {
      log("error in turnOn: $e");
      _sock = null;
      notifyListeners();
      rethrow; //TODO Should?  Shouldn't?
    }
  }

  Future<void> turnOff() async {
    try {
      await _sock?.sendString("power=false");
    } catch (e) {
      log("error in turnOn: $e");
      _sock = null;
      notifyListeners();
      rethrow; //TODO Should?  Shouldn't?
    }
  }

  Future<void> setVoltageSetpoint(double x) async {
    try {
      await _sock?.sendString("voltageSetpoint=$x");
    } catch (e) {
      log("error in setVoltageSetpoint: $e");
      _sock = null;
      notifyListeners();
      rethrow; //TODO Should?  Shouldn't?
    }
  }

  Future<void> setCurrentSetpoint(double x) async {
    try {
      await _sock?.sendString("currentSetpoint=$x");
    } catch (e) {
      log("error in setCurrentSetpoint: $e");
      _sock = null;
      notifyListeners();
      rethrow; //TODO Should?  Shouldn't?
    }
  }

  Future<void> setVoltageOverprotect(double x) async {
    try {
      await _sock?.sendString("voltageOverprotect=$x");
    } catch (e) {
      log("error in setVoltageOverprotect: $e");
      _sock = null;
      notifyListeners();
      rethrow; //TODO Should?  Shouldn't?
    }
  }

  Future<void> setCurrentOverprotect(double x) async {
    try {
      await _sock?.sendString("currentOverprotect=$x");
    } catch (e) {
      log("error in setCurrentOverprotect: $e");
      _sock = null;
      notifyListeners();
      rethrow; //TODO Should?  Shouldn't?
    }
  }
}