import 'dart:convert';

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString().replaceAll(RegExp(r'[^0-9\.\-]'), '');
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

String? _str(dynamic v) => v == null ? null : v.toString();
DateTime? _toDt(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  try {
    return DateTime.parse(s).toLocal();
  } catch (_) {
    return null;
  }
}

String _retailerDisplay(String? raw) {
  final r = (raw ?? '').toLowerCase();
  if (r.contains('amazon')) return 'Amazon';
  if (r.contains('mercado')) return 'Mercado Libre';
  if (r.contains('cyberpuerta')) return 'Cyberpuerta';
  return raw ?? '';
}

class PriceEntry {
  final String retailer;
  final String retailerDisplayName;
  final String? currency;
  final double? price;
  final String? url;
  final String? countryCode;
  final String? availability;
  final String? condition;
  final DateTime? scrapedAt;

  PriceEntry({
    required this.retailer,
    required this.retailerDisplayName,
    this.currency,
    this.price,
    this.url,
    this.countryCode,
    this.availability,
    this.condition,
    this.scrapedAt,
  });

  factory PriceEntry.fromJson(Map<String, dynamic> j) {
    final retailerRaw =
        _str(j['retailer']) ?? _str(j['store']) ?? _str(j['seller']);
    final curr = _str(j['currency']) ?? _str(j['ccy']) ?? 'MXN';
    final url = _str(j['url']) ?? _str(j['product_url']) ?? _str(j['link']);
    final price = _toDouble(
      j['price'] ?? j['amount'] ?? j['value'] ?? j['price_mxn'],
    );
    final cc = _str(j['country_code']) ?? _str(j['country']);
    final avail = _str(j['availability']) ?? _str(j['stock']);
    final cond = _str(j['condition']);
    final ts = _toDt(j['scraped_at'] ?? j['last_seen'] ?? j['updated_at']);
    return PriceEntry(
      retailer: retailerRaw ?? '',
      retailerDisplayName: _retailerDisplay(retailerRaw),
      currency: curr,
      price: price,
      url: url,
      countryCode: cc,
      availability: avail,
      condition: cond,
      scrapedAt: ts,
    );
  }

  Map<String, dynamic> toJson() => {
    'retailer': retailer,
    'currency': currency,
    'price': price,
    'url': url,
    'country_code': countryCode,
    'availability': availability,
    'condition': condition,
    'scraped_at': scrapedAt?.toIso8601String(),
  };
}

class ComponentPricing {
  final int? componentId;
  final List<PriceEntry> offers;
  final double? minPrice;
  final double? maxPrice;
  final String? currency;
  final DateTime? updatedAt;

  ComponentPricing({
    this.componentId,
    required this.offers,
    this.minPrice,
    this.maxPrice,
    this.currency,
    this.updatedAt,
  });

  factory ComponentPricing.fromJson(dynamic data) {
    if (data is List) {
      final offers = data
          .map((e) => PriceEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final prices = offers.map((e) => e.price).whereType<double>().toList()
        ..sort();
      final curr = offers.isNotEmpty ? offers.first.currency : 'MXN';
      final up = offers
          .map((e) => e.scrapedAt)
          .whereType<DateTime>()
          .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
      return ComponentPricing(
        offers: offers,
        minPrice: prices.isEmpty ? null : prices.first,
        maxPrice: prices.isEmpty ? null : prices.last,
        currency: curr,
        updatedAt: up,
      );
    }
    final j = Map<String, dynamic>.from(data as Map);
    final compId = j['component_id'] is int
        ? j['component_id'] as int
        : int.tryParse('${j['component_id']}');
    final listRaw = j['prices'] ?? j['offers'] ?? j['data'] ?? j['items'] ?? [];
    final list = (listRaw is List) ? listRaw : [];
    final offers = list
        .map((e) => PriceEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final prices = offers.map((e) => e.price).whereType<double>().toList()
      ..sort();
    final minJ = _toDouble(j['min_price']);
    final maxJ = _toDouble(j['max_price']);
    final curr =
        _str(j['currency']) ??
        (offers.isNotEmpty ? offers.first.currency : 'MXN');
    final up =
        _toDt(j['updated_at']) ??
        offers
            .map((e) => e.scrapedAt)
            .whereType<DateTime>()
            .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    return ComponentPricing(
      componentId: compId,
      offers: offers,
      minPrice: minJ ?? (prices.isEmpty ? null : prices.first),
      maxPrice: maxJ ?? (prices.isEmpty ? null : prices.last),
      currency: curr,
      updatedAt: up,
    );
  }

  Map<String, dynamic> toJson() => {
    'component_id': componentId,
    'currency': currency,
    'min_price': minPrice,
    'max_price': maxPrice,
    'updated_at': updatedAt?.toIso8601String(),
    'offers': offers.map((e) => e.toJson()).toList(),
  };

  String? get retailersDisplay {
    if (offers.isEmpty) return null;
    final names =
        offers
            .map((e) => e.retailerDisplayName)
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return names.join(', ');
  }

  String priceLabel([String? fallbackCurrency]) {
    final ccy = currency ?? fallbackCurrency ?? 'MXN';
    final p = minPrice;
    if (p == null) return '-';
    return '\$${p.toStringAsFixed(0)} $ccy';
  }
}

ComponentPricing parseComponentPricingResponse(String body) {
  final decoded = jsonDecode(body);
  return ComponentPricing.fromJson(decoded);
}
