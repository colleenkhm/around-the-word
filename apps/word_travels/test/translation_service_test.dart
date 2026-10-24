import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:word_travels/services/translation_service.dart';

/// A provider wired to [handler] instead of the network, with a short
/// deadline so the timeout case doesn't make the suite wait on it.
MyMemoryTranslationProvider providerFor(
  Future<http.Response> Function(http.Request) handler,
) => MyMemoryTranslationProvider(
  client: MockClient(handler),
  timeout: const Duration(milliseconds: 50),
);

Matcher failsWith(TranslationFailure failure) => throwsA(
  isA<TranslationException>().having((e) => e.failure, 'failure', failure),
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
      failsWith(TranslationFailure.unreachable),
    );
  });

  test('a spent quota dressed up as HTTP 200 reports as a spent quota', () {
    // MyMemory answers 200 with the complaint sitting in translatedText when
    // the daily allowance is gone; only responseStatus says so. Reporting
    // this as a network error would send the user to fix their wifi, and
    // reporting it as a translation would save the complaint as Spanish.
    final provider = providerFor(
      (_) async => http.Response(
        '{"responseStatus": "403", "responseData": {"translatedText": '
        '"YOU USED ALL AVAILABLE FREE TRANSLATIONS FOR TODAY"}}',
        200,
      ),
    );
    expect(
      provider.translate('hello', from: 'en', to: 'es'),
      failsWith(TranslationFailure.quotaExhausted),
    );
  });

  test('rate limiting is also a wait-until-later failure', () {
    final provider = providerFor(
      (_) async => http.Response('{"responseStatus": 429}', 200),
    );
    expect(
      provider.translate('hello', from: 'en', to: 'es'),
      failsWith(TranslationFailure.quotaExhausted),
    );
  });

  test('an unparseable body is a service error, not a translation', () {
    final provider = providerFor((_) async => http.Response('not json', 200));
    expect(
      provider.translate('hello', from: 'en', to: 'es'),
      failsWith(TranslationFailure.serviceError),
    );
  });

  test('a non-200 HTTP status is a service error', () {
    final provider = providerFor((_) async => http.Response('nope', 500));
    expect(
      provider.translate('hello', from: 'en', to: 'es'),
      failsWith(TranslationFailure.serviceError),
    );
  });

  test('an empty translation is reported as having none', () {
    final provider = providerFor(
      (_) async => http.Response(
        '{"responseStatus": 200, "responseData": {"translatedText": ""}}',
        200,
      ),
    );
    expect(
      provider.translate('hello', from: 'en', to: 'es'),
      failsWith(TranslationFailure.noTranslation),
    );
  });
}
