import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Raw UDP socket test to sip.ranksitt.net:5060', () async {
    print('Testing raw UDP socket to sip.ranksitt.net:5060...');
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final localPort = socket.port;
    print('Bound UDP socket on local port $localPort');

    final addresses = await InternetAddress.lookup('sip.ranksitt.net');
    final remoteIp = addresses.first;
    print('Resolved sip.ranksitt.net to ${remoteIp.address}');

    final completer = Completer<String>();

    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = socket.receive();
        if (dg != null) {
          final text = utf8.decode(dg.data, allowMalformed: true);
          print('UDP RECEIVED (${dg.data.length} bytes):\n$text');
          if (!completer.isCompleted) {
            completer.complete(text);
          }
        }
      }
    });

    // Send SIP OPTIONS request
    final optionsMsg = 
        'OPTIONS sip:sip.ranksitt.net SIP/2.0\r\n'
        'Via: SIP/2.0/UDP 127.0.0.1:$localPort;rport;branch=z9hG4bKtest123\r\n'
        'Max-Forwards: 70\r\n'
        'To: <sip:sip.ranksitt.net>\r\n'
        'From: <sip:test@sip.ranksitt.net>;tag=12345\r\n'
        'Call-ID: test-call-id-999@127.0.0.1\r\n'
        'CSeq: 1 OPTIONS\r\n'
        'Contact: <sip:test@127.0.0.1:$localPort>\r\n'
        'Accept: application/sdp\r\n'
        'Content-Length: 0\r\n\r\n';

    final bytes = utf8.encode(optionsMsg);
    final sent = socket.send(bytes, remoteIp, 5060);
    print('Sent $sent bytes over UDP to ${remoteIp.address}:5060');

    final response = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('UDP timeout');
      return 'TIMEOUT';
    });

    socket.close();
    expect(response, isNot('TIMEOUT'));
  });
}

