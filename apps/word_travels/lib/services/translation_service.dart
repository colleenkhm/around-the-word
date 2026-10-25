import 'dart:convert';

import 'package:http/http.dart' as http;

/// A backend that can translate text from one language to another. The seam
/// for swapping the free provider below for a paid one later (Google Cloud
/// Translate, DeepL, ...) — a new class implementing this, no changes to any
/// call site.
abstract class TranslationProvider {
  Future<String> translate(String text, {required String from, required String to});
}

/// Why a lookup didn't produce a translation. The reason, not the wording:
/// which of these happened changes what the user should do about it — wait
/// for signal, give up until tomorrow, or just try again — and only the UI
/// knows how to say so. A provider that can't tell these apart is free to
/// report [serviceError] for everything.
enum TranslationFailure {
  /// Never got an answer: no connection, or a captive portal swallowing the
  /// request until it timed out. Retrying is the right move.
  unreachable,

  /// The service is refusing for the rest of the day — the free tier's word
  /// limit. Retrying now cannot help, which is the thing the old single
  /// "check your connection" message got wrong.
  quotaExhausted,

  /// The service answered, but not with anything usable.
  serviceError,

  /// The service worked and had no translation to offer for this text.
  noTranslation,
}

/// A lookup that failed, carrying [failure] so the UI can choose what to say
/// and whether to offer a retry. [detail] is for debugging, never for
/// display.
class TranslationException implements Exception {
  const TranslationException(this.failure, [this.detail]);

  final TranslationFailure failure;
  final String? detail;

  @override
  String toString() =>
      'TranslationException(${failure.name}${detail == null ? '' : ': $detail'})';
}

/// How long to wait on the translation service before giving up. Travel wifi
/// — hotel, airport, café — is the normal case for this app, and a captive
/// portal completes the TCP connection and then never answers. Without a
/// deadline the request hangs forever and the UI sits on "Translating..."
/// with nothing to retry, so this fails loudly instead.
const Duration _requestTimeout = Duration(seconds: 10);

/// Free, no API key required: https://mymemory.translated.net
class MyMemoryTranslationProvider implements TranslationProvider {
  const MyMemoryTranslationProvider({this.client, this.timeout = _requestTimeout});

  /// The HTTP client to send through, or null to use a one-off client per
  /// request (what the top-level `http.get` does). Only tests pass one, to
  /// stand in for the network.
  final http.Client? client;

  final Duration timeout;

  Future<http.Response> _get(Uri uri) {
    final c = client;
    return c == null ? http.get(uri) : c.get(uri);
  }

  @override
  Future<String> translate(
    String text, {
    required String from,
    required String to,
  }) async {
    final uri = Uri.https('api.mymemory.translated.net', '/get', {
      'q': text,
      'langpair': '$from|$to',
    });

    final http.Response response;
    try {
      response = await _get(uri).timeout(timeout);
    } catch (e) {
      throw TranslationException(TranslationFailure.unreachable, '$e');
    }

    if (response.statusCode != 200) {
      throw TranslationException(
        _failureForStatus(response.statusCode),
        'HTTP ${response.statusCode}',
      );
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw TranslationException(TranslationFailure.serviceError, '$e');
    }

    // MyMemory answers HTTP 200 even when it's refusing — a blown daily
    // quota comes back as responseStatus 403 with the complaint sitting in
    // translatedText, which would otherwise get saved as if it were a real
    // translation. It types the field as either a number or a string.
    final status = body['responseStatus'].toString();
    if (status != '200') {
      throw TranslationException(
        _failureForStatus(int.tryParse(status)),
        'responseStatus $status',
      );
    }

    final translated =
        (body['responseData'] as Map<String, dynamic>?)?['translatedText']
            as String?;
    if (translated == null || translated.isEmpty) {
      throw const TranslationException(TranslationFailure.noTranslation);
    }
    return translated;
  }

  /// MyMemory reports a spent daily allowance as 403, and rate limiting as
  /// 429 — both mean "not now", and neither is worth a retry button.
  /// Anything else is just a bad answer.
  TranslationFailure _failureForStatus(int? status) =>
      status == 403 || status == 429
          ? TranslationFailure.quotaExhausted
          : TranslationFailure.serviceError;
}

/// The provider the app runs on, handed to the widget tree in `main.dart`
/// and read from there — so swapping to a paid provider later means
/// changing this line (plus adding the new class), and tests can substitute
/// a fake without touching the network.
const TranslationProvider activeTranslationProvider = MyMemoryTranslationProvider();
