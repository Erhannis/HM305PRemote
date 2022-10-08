import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:multicast_dns/multicast_dns.dart';
import 'package:sync/sync.dart' as s;
import 'dart:io';
import 'dart:developer';

import 'package:sync/waitgroup.dart';

import 'MessageSocket.dart';

const String _SERVICE = '_0f50032d-cc47-407c-9f1a-a3a28a680c1e._http._tcp.local';
String localId = "CLIENT_ID"; //DO Make random or st

Future<MessageSocket?> autoconnect() async {
  //TODO Doesn't distinguish between different power supply instances

  log("create client");
  final MDnsClient client = MDnsClient(rawDatagramSocketFactory: (dynamic host, int port, {bool? reuseAddress, bool? reusePort, int ttl = 1}) {
    log("rawDatagramSocketFactory $host $port $reuseAddress $reusePort $ttl");
    return RawDatagramSocket.bind(host, port, reuseAddress: true, reusePort: false, ttl: ttl);
  });

  log("start client");
  await client.start();

  var addresses = <InternetAddress>[];
  int port = -1;
  log("await ptr");
  await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(_SERVICE))) {
    log("in ptr lookup");

    print("await srv1");
    await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))) {
      print("in srv1");
      print('instance found at ${srv.target}:${srv.port}.');
      port = srv.port;
    }

    log("await addr lookup");
    await for (final IPAddressResourceRecord addr in client.lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(ptr.domainName))) {
      log("in addr lookup");
      log("$addr");
      addresses.add(addr.address);
    }
  }
  log("$addresses $port");

  if (port == -1) {
    return null;
  }

  var wg = WaitGroup();
  wg.add(1);

  MessageSocket? mSock = null;

  for (var addr in addresses) {
    unawaited(Future(() async {
      Socket? localSocket = null;
      try {
        localSocket = await Socket.connect(addr.address, port);

        if (mSock != null) {
          localSocket.close();
          return;
        }

        log('connected via ${addr.address} $port');
        mSock = MessageSocket(localSocket);

        wg.done();
      } catch (e) {
        print("error connecting: ${addr.address} $port $e");
        if (localSocket != null) {
          localSocket.close();
        }
      }
    }));
  }

  await wg.wait().timeout(Duration(seconds: 15), onTimeout: () {}); //TODO Time?

  log("stop client");
  client.stop();
  log("done");

  final lSock = mSock;
  if (lSock != null) {
    await lSock.sendString(localId); // nodeId
    await lSock.sendString("");      // serviceId
    log("remote    nodeId ${String.fromCharCodes((await lSock.recvMsg())!)}"); // nodeId
    log("remote serviceId ${String.fromCharCodes((await lSock.recvMsg())!)}"); // serviceId
  }

  return lSock;
}