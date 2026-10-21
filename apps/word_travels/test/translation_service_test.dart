import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocket_talk/services/translation_service.dart';

/// A provider wired to [handler] instead of the network, with a short
/// deadline so the timeout case doesn't make the suite wait on it.
MyMemoryTranslationProvider providerFor(
  Future<http.Response> Function(http.Request) handler,
) => MyMemoryTranslationProvider(
  client: MockClient(handler),
  timeout: const Duration(milliseconds: 50),
);

void main() {
  test('a successful response returns the translated text', () async {
    final provider = providerFor(
      (_) async => http.Response(
        '{"responseStatus": 200, "responseData": {"translatedText": "Hola"}}',
        200,
      ),
    );
    expect(
      await provider.translate('hello', from: 'en', to: 'es'),
      'Hola',
    );
  });

  test('a request that never answers fails instead of hanging', () async {
    // Travel wifi's failure mode: the connection is accepted and then
    // nothing comes back. Never completing (rather than delaying) means
    // there's no timer for the deadline to race against — only the timeout
    // can end this call.
    final provider = providerFor((_) => Completer<http.Response>().future);
    await expectLater(
      provider.translate('hello', from: 'en', to: 'es'),
      throwsException,
    );
  });

  test('a refusal dressed up as HTTP 200 is not treated as a translation', () {
    // MyMemory answers 200 with the complaint sitting in translatedText when
    // the daily quota is gone; only responseStatus says so.
    final provider = providerFor(
      (_) async => http.Response(
        '{"responseStatus": "403", "responseData": {"translatedText": '
        '"YOU USED ALL AVAILABLE FREE TRANSLATIONS FOR TODAY"}}',
        200,
      ),
    );
    expect(
      provider.translate('hello', from: 'en', to: 'es'),
      throwsException,
    );
  });

  test('an unparseable body is an error, not a translation', () {
    final provider = providerFor((_) async => http.Response('not json', 200));
    expect(
      provider.translate('hello', from: 'en', to: 'es'),
      throwsException,
    );
  });
}
