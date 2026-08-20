import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_data.dart';

/// Live USD -> [currencyCode] conversion via the deployed `convert-currency`
/// Edge Function (server-side key, cached — see that function's own
/// comments). Returns `null` on any failure; the caller treats that the
/// same as "no rate available" (renders an em dash), never invents one.
class CurrencyService {
  Future<ExchangeRate?> fetchRate(String currencyCode) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'convert-currency',
        queryParameters: {'to': currencyCode},
      );
      final data = response.data;
      if (data is! Map || data['rateFromUsd'] == null) return null;

      return ExchangeRate(
        currencyCode: data['currencyCode'] as String? ?? currencyCode,
        rateFromUsd: (data['rateFromUsd'] as num).toDouble(),
        fetchedAt: data['fetchedAt'] == null
            ? DateTime.now()
            : DateTime.parse(data['fetchedAt'] as String),
      );
    } catch (error) {
      debugPrint('Currency rate fetch failed for $currencyCode: $error');
      return null;
    }
  }
}
