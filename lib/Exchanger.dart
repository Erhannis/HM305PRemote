import 'dart:async';
import 'dart:developer';

import 'package:sync/sync.dart';

/**
 * Like java.util.concurrent.Exchanger; two Futures simultaneously exchange objects
 */
class Exchanger<T> {
  bool hasItem = false;
  T? pending = null;

  Completer<void>? _c = null;

  List<String> _entrants = [];

  Future<T> exchange(String tag, T x) async {
    _entrants.add(tag);
    if (_entrants.length > 2) {
      log("TOO MANY ENTRANTS; HOW?");
    }
    if (!hasItem) {
      log("exa1 $tag");
      pending = x;
      hasItem = true;
      log("exa2 $tag");
      _c = Completer<void>.sync();
      log("exa3 $tag");
      await _c!.future;
      log("exa4 $tag");
      /*
      I had a problem - pending is T?.  So I need to return r!.  But T can itself be nullable, and there that will fail.  Therefore, dynamic.
      (D'OH, I was using `pending == null` to mean "no item"; caused deadlock.)
       */
      dynamic r = pending;
      log("exa5 $tag");
      pending = null;
      hasItem = false;
      log("exa6 $tag");
      _entrants.remove(tag);
      log("exa7 $tag");
      return r;
    } else {
      log("exb1 $tag");
      dynamic r = pending;
      log("exb2 $tag");
      pending = x;
      log("exb3 $tag");
      _c!.complete();
      log("exb4 $tag");
      _entrants.remove(tag);
      log("exb5 $tag");
      return r;
    }
  }
}