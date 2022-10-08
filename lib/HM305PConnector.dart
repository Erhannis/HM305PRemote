import 'package:multicast_dns/multicast_dns.dart';
import 'dart:io';

Future<void> foo() async {
  //const String name = '_dartobservatory._tcp.local';
  //const String name = '_PSUTEST._tcp.local';
  const String service = '_0f50032d-cc47-407c-9f1a-a3a28a680c1e._http._tcp.local';

  print("create client");
  final MDnsClient client = MDnsClient(rawDatagramSocketFactory: (dynamic host, int port, {bool? reuseAddress, bool? reusePort, int ttl = 1}) {
    print("rawDatagramSocketFactory $host $port $reuseAddress $reusePort $ttl");
    return RawDatagramSocket.bind(host, port, reuseAddress: true, reusePort: false, ttl: ttl);
  });
  // Start the client with default options.
  print("start client");
  await client.start();

  // print("await srv1");
  // await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(ResourceRecordQuery.service("_HM305P._PSUTEST._tcp.local", isMulticast: false))) {
  //   print("in srv1");
  //   // Domain name will be something like "io.flutter.example@some-iphone.local._dartobservatory._tcp.local"
  //   print('instance found at ${srv.target}:${srv.port}.');
  // }


  // Get the PTR record for the service.
  print("await ptr");
  await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(service))) {
    print("in ptr lookup");
    // Use the domainName from the PTR record to get the SRV record,
    // which will have the port and local hostname.
    // Note that duplicate messages may come through, especially if any
    // other mDNS queries are running elsewhere on the machine.
    print("await srv2");
    await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))) {
      print("in srv2 lookup");
      // Domain name will be something like "io.flutter.example@some-iphone.local._dartobservatory._tcp.local"
      final String bundleId = ptr.domainName; //.substring(0, ptr.domainName.indexOf('@'));
      print('Dart observatory instance found at ${srv.target}:${srv.port} for "$bundleId".');
    }

    print("await addr lookup");
    await for (final IPAddressResourceRecord addr in client.lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(ptr.domainName))) {
      print("in addr lookup");
      print(addr);
    }
  }


  print("stop client");
  client.stop();
  print("done");
}