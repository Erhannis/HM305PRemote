import 'dart:async';
import 'dart:convert';

import 'package:multicast_dns/multicast_dns.dart';
import 'package:sync/sync.dart' as s;
import 'dart:io';
import 'dart:developer';

import 'package:sync/waitgroup.dart';

const String _SERVICE = '_0f50032d-cc47-407c-9f1a-a3a28a680c1e._http._tcp.local';

Future<void> autoconnect() async {
  //TODO Doesn't distinguish between different power supply instances

  log("create client");
  final MDnsClient client = MDnsClient(rawDatagramSocketFactory: (dynamic host, int port, {bool? reuseAddress, bool? reusePort, int ttl = 1}) {
    log("rawDatagramSocketFactory $host $port $reuseAddress $reusePort $ttl");
    return RawDatagramSocket.bind(host, port, reuseAddress: true, reusePort: false, ttl: ttl);
  });

  log("start client");
  await client.start();

  var addresses = <InternetAddress>[];

  log("await ptr");
  await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(_SERVICE))) {
    log("in ptr lookup");
    log("await addr lookup");
    await for (final IPAddressResourceRecord addr in client.lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(ptr.domainName))) {
      log("in addr lookup");
      log("$addr");
      addresses.add(addr.address);
    }
  }

  log("$addresses");

  var wg = WaitGroup();
  wg.add(1);

  for (var addr in addresses) {
    unawaited(Future(() async {
      Socket socket = await Socket.connect('192.168.1.99', 1024);
      log('connected');

      socket.listen((List<int> event) {
        log(utf8.decode(event));
      });

      socket.add(utf8.encode('hello'));

      await Future.delayed(Duration(seconds: 5));

      socket.close();

      try {
        wg.done();
      } catch (e) {
      }
    }));
  }

  wg.wait();

  log("stop client");
  client.stop();
  log("done");
}