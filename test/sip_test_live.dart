import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:sip_ua/sip_ua.dart';

void main() {
  test('Live SIP TCP test against sip.ranksitt.net', () async {
    print('Starting live SIP test against sip.ranksitt.net:5060...');
    final helper = SIPUAHelper(customLogger: Logger(printer: SimplePrinter(printTime: true)));

    final settings = UaSettings();
    settings.webSocketSettings.allowBadCertificate = true;
    settings.tcpSocketSettings.allowBadCertificate = true;
    settings.host = 'sip.ranksitt.net';
    settings.port = '5060';
    settings.transportType = TransportType.TCP;
    settings.uri = 'sip:09617733133@sip.ranksitt.net';
    settings.authorizationUser = '09617733133';
    settings.password = 'au9g9qiue2';
    settings.displayName = '09617733133';

    helper.addSipUaHelperListener(MyListener());

    print('Calling helper.start(settings)...');
    await helper.start(settings);

    await Future.delayed(const Duration(seconds: 8));
    print('Done waiting.');
    helper.stop();
  }, timeout: const Timeout(Duration(seconds: 20)));
}

class MyListener implements SipUaHelperListener {
  @override
  void registrationStateChanged(RegistrationState state) {
    print('>>> REGISTRATION: ${state.state} - ${state.cause}');
  }

  @override
  void transportStateChanged(TransportState state) {
    print('>>> TRANSPORT: ${state.state} - ${state.cause}');
  }

  @override
  void callStateChanged(Call call, CallState state) {
    print('>>> CALL: ${state.state}');
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}
}

