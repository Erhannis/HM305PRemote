import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:hm305p_remote/MessageSocket.dart';
import 'HM305PConnector.dart' as Connector;

class HM305PInterface extends ChangeNotifier {
  MessageSocket? _sock;

  HM305PInterface();

  Future<bool> autoconnect() async {
    if (_sock != null) {
      await _sock!.close();
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