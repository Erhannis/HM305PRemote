import 'dart:async';
import 'dart:developer';

import 'package:sync/sync.dart';

/**
 * Like java.util.concurrent.Exchanger; two Futures simultaneously exchange objects
 */
class Exchanger<T> {
  T? pending;

  Completer<void>? _c = null;

  List<String> _entrants = [];

  Future<T> exchange(String tag, T x) async {
    _entrants.add(tag);
    if (_entrants.length > 2) {
      log("TOO MANY ENTRANTS; HOW?");
    }
    if (pending == null) {
      pending = x;
      _c = Completer<void>.sync();
      await _c!.future;
      /*
      I had a problem - pending is T?.  So I need to return r!.  But T can itself be nullable, and there that will fail.  Therefore, dynamic.
       */
      dynamic r = pending;
      pending = null;
      _entrants.remove(tag);
      return r;
    } else {
      dynamic r = pending;
      pending = x;
      _c!.complete();
      _entrants.remove(tag);
      return r;
    }
  }
}