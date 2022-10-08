import 'dart:async';
import 'dart:developer';
import 'dart:math' as m;

import 'package:sync/sync.dart';

import 'Channel.dart';
import 'Exchanger.dart';
import 'misc.dart';

Future<void> testExchanger1() async {
  var ex = Exchanger<String>();

  var rand = m.Random();

  var wg = WaitGroup();
  for (var i = 0; i < 10; i++) {
    final id = i;
    wg.add(1);
    unawaited(Future(() async {
      log("--> node $id");

      await sleep(rand.nextInt(2000));
      log("$id(1) <- ${await ex.exchange("$id(1)")}");
      await sleep(rand.nextInt(2000));
      log("$id(2) <- ${await ex.exchange("$id(2)")}");
      await sleep(rand.nextInt(2000));
      log("$id(3) <- ${await ex.exchange("$id(3)")}");
      await sleep(rand.nextInt(2000));
      log("$id(4) <- ${await ex.exchange("$id(4)")}");
      await sleep(rand.nextInt(2000));
      log("$id(5) <- ${await ex.exchange("$id(5)")}");

      wg.done();
      log("<-- node $id");
    }));
  }

  await wg.wait();
  log("done");
}

Future<void> testExchanger2() async {
  var ex = Exchanger<int>();

  var rand = m.Random();

  var totalTx = 0;
  var totalRx = 0;

  var txCount = Map<int, int>();
  var rxCount = Map<int, int>();

  for (int i = 0; i < 100; i++) {
    txCount[i] = 0;
    rxCount[i] = 0;
  }

  var wg = WaitGroup();
  for (var i = 0; i < 10; i++) {
    final id = i;
    wg.add(1);
    unawaited(Future(() async {
      log("--> node $id");

      var j = 0;

      try {
        for (var k = 0; k < 10; k++) {
          await sleep(rand.nextInt(100));
          j = rand.nextInt(100);
          totalTx += j;
          txCount[j] = txCount[j]! + 1;
          j = await ex.exchange(j).timeout(Duration(seconds: 10), onTimeout: () async {
            log("timeout in $id ; $j $ex $k $totalTx $totalRx $txCount $rxCount");
            return -1;
          });
          totalRx += j;
          rxCount[j] = rxCount[j]! + 1;
        }
      } finally {
        wg.done();
        log("<-- node $id");
      }
    }));
  }

  await wg.wait();

  log("tx $totalTx / rx $totalRx");
  assert(totalTx == totalRx);

  log("done");
}

// Ok, so turns out I missed some subtleties of this test - the Exchanger worked fine; the test created a deadlock
//   ...or DID IT???  the Exchanger, I mean.  the test definitely made a deadlock.
Future<void> testExchanger3() async {
  var ex = Exchanger<String>();

  var rand = m.Random();

  var NODES = 4;
  var MSGS = 4;

  var txCount = Map<String, int>();
  var rxCount = Map<String, int>();

  for (int i = 0; i < MSGS; i++) {
    for (int j = 0; j < NODES; j++) {
      txCount["$j:$i"] = 0;
      rxCount["$j:$i"] = 0;
    }
  }

  var wg = WaitGroup();
  for (var i = 0; i < NODES; i++) {
    final id = i;
    wg.add(1);
    unawaited(Future(() async {
      log("--> node $id");

      try {
        for (var k = 0; k < MSGS; k++) {
          await sleep(rand.nextInt(100));
          var j = "$id:$k";
          txCount[j] = txCount[j]! + 1;
          var l = await ex.exchange(j).timeout(Duration(seconds: 10), onTimeout: () async {
            log("timeout in $id ; $j $ex $k $txCount $rxCount");
            return "ERROR";
          });
          log("rx: ${j} <- ${l}");
          rxCount[l] = rxCount[l]! + 1;
        }
      } finally {
        wg.done();
        log("<-- node $id");
      }
    }));
  }

  await wg.wait();

  for (var s in txCount.keys) {
    assert(rxCount[s] == txCount[s]);
  }
  for (var s in rxCount.keys) {
    assert(txCount[s] == rxCount[s]);
  }

  log("done");
}

Future<void> testChannel() async {
  var c = Channel<int>();
  var ci = c.getIn();
  var co = c.getOut();

  var TXERS = 100;
  var RXERS = TXERS;

  var MSGS = 100;

  var txSum = 0;
  var rxSum = 0;

  var rand = m.Random();
  var wg = WaitGroup();
  var start = WaitGroup();
  start.add(1);

  for (var i = 0; i < TXERS; i++) {
    final id = i;
    wg.add(1);
    unawaited(Future(() async {
      try {
        log("--> TXER $id");
        await start.wait();
        log("t$id 1");
        for (var j = 0; j < MSGS; j++) {
          //log("t$id 2 $j");
          await sleep(rand.nextInt(10));
          //log("t$id 3 $j");
          var x = rand.nextInt(100);
          //log("t$id 4 $j");
          txSum += x;
          //log("t$id 5 $j");
          await co.write(x).timeout(Duration(seconds: 30), onTimeout: () async {
            log("error on t$id : $j $txSum $rxSum $c $ci $co");
            throw Exception("ERROR");
          });
          //log("t$id 6 $j");
        }
        log("t$id 7");
      } finally {
        wg.done();
        log("<-- TXER $id");
      }
    }));
  }

  for (var i = 0; i < RXERS; i++) {
    final id = i;
    wg.add(1);
    unawaited(Future(() async {
      try {
        log("--> RXER $id");
        await start.wait();
        log("r$id 1");
        for (var j = 0; j < MSGS; j++) {
          //log("r$id 2 $j");
          await sleep(rand.nextInt(10));
          //log("r$id 3 $j");
          var x = await ci.read().timeout(Duration(seconds: 30), onTimeout: () async {
            log("error on r$id : $j $txSum $rxSum $c $ci $co");
            throw Exception("ERROR");
          });
          //log("r$id 4 $j");
          rxSum += x;
          //log("r$id 5 $j");
        }
        log("r$id 6");
      } finally {
        wg.done();
        log("<-- RXER $id");
      }
    }));
  }

  start.done();
  await wg.wait(); //TODO This isn't finishing, despite the finallys?
  assert(txSum == rxSum);
  log("done");
}

Future<void> testExchanger4() async {
  var ex = Exchanger<String>();

  var rand = m.Random();

  var NODES = 2;
  var MSGS = 100000;

  var txCount = Map<String, int>();
  var rxCount = Map<String, int>();

  for (int i = 0; i < MSGS; i++) {
    for (int j = 0; j < NODES; j++) {
      txCount["$j:$i"] = 0;
      rxCount["$j:$i"] = 0;
    }
  }

  var wg = WaitGroup();
  for (var i = 0; i < NODES; i++) {
    final id = i;
    wg.add(1);
    unawaited(Future(() async {
      log("--> node $id");

      try {
        for (var k = 0; k < MSGS; k++) {
          //await sleep(rand.nextInt(10));
          var j = "$id:$k";
          txCount[j] = txCount[j]! + 1;
          var l = await ex.exchange(j).timeout(Duration(seconds: 10), onTimeout: () async {
            log("timeout in $id ; $j $ex $k $txCount $rxCount");
            return "ERROR";
          });
          //log("rx: ${j} <- ${l}");
          rxCount[l] = rxCount[l]! + 1;
        }
      } finally {
        wg.done();
        log("<-- node $id");
      }
    }));
  }

  await wg.wait();

  for (var s in txCount.keys) {
    assert(rxCount[s] == txCount[s]);
  }
  for (var s in rxCount.keys) {
    assert(txCount[s] == rxCount[s]);
  }

  log("done");
}

Future<void> testStreams() async {
  var sc = StreamController<String>();

  unawaited(Future(() async {
    log("--> generator");
    for (var i = 0; i < 10; i++) {
      log("--- generator $i");
      sc.add("$i");
    }
    log("<-- generator");
  }));

  await for (var s in sc.stream) {
    log("rx $s");
    await sleep(1000);
  }

  // This didn't work
  // sc.stream.listen((s) async {
  //   log("rx $s");
  //   await sleep(1000);
  // });

  await sleep(20000);
  log("done");
}