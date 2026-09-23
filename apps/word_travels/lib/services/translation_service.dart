import 'dart:convert';

import 'package:http/http.dart' as http;

/// A backend that can translate text from one language to another. The seam
/// for swapping the free provider below for a paid one later (Google Cloud
/// Translate, DeepL, ...) — a new class implementing this, no changes to any
/// call site.
abstract class TranslationProvider {
  Future<String> translate(String text, {required String from, required String to});
}

/// Free, no API key required: https://mymemory.translated.net
class MyMemoryTranslationProvider implements TranslationProvider {
  const MyMemoryTranslationProvider();

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
      response = await http.get(uri);
    } catch (_) {
      throw Exception('Could not reach the translation service.');
    }

    if (response.statusCode != 200) {
      throw Exception('Translation service returned an error.');
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Translation service returned an unexpected response.');
    }

    // MyMemory answers HTTP 200 even when it's refusing — a blown daily
    // quota comes back as responseStatus 403 with the complaint sitting in
    // translatedText, which would otherwise get saved as if it were a real
    // translation. It types the field as either a number or a string.
    if (body['responseStatus'].toString() != '200') {
      throw Exception('Translation service returned an error.');
    }

    final translated =
        (body['responseData'] as Map<String, dynamic>?)?['translatedText']
            as String?;
    if (translated == null || translated.isEmpty) {
      throw Exception('No translation found.');
    }
    return translated;
  }
}

/// The provider the app runs on, handed to the widget tree in `main.dart`
/// and read from there — so swapping to a paid provider later means
/// changing this line (plus adding the new class), and tests can substitute
/// a fake without touching the network.
const TranslationProvider activeTranslationProvider = MyMemoryTranslationProvider();
