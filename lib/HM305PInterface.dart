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

  Future<void> turnOn() async {
    try {
      await _sock?.sendString("power=true");
    } catch (e) {
      log("error in turnOn: $e");
      _sock = null;
      rethrow; //TODO Should?  Shouldn't?
    }
  }

  Future<void> turnOff() async {
    try {
      await _sock?.sendString("power=false");
    } catch (e) {
      log("error in turnOn: $e");
      _sock = null;
      rethrow; //TODO Should?  Shouldn't?
    }
  }
}