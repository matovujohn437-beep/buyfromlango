import 'json_helpers.dart';

class MarketPriceModel {
  const MarketPriceModel({
    required this.id,
    required this.districtId,
    required this.itemName,
    required this.districtName,
    this.marketPriceUgx,
    this.farmGatePriceUgx,
    this.wholesalePriceUgx,
    this.retailPriceUgx,
    required this.priceChangePercent,
    this.updatedAt,
  });

  final int id;
  final int districtId;
  final String itemName;
  final String districtName;
  final num? marketPriceUgx;
  final num? farmGatePriceUgx;
  final num? wholesalePriceUgx;
  final num? retailPriceUgx;
  final num priceChangePercent;
  final DateTime? updatedAt;

  factory MarketPriceModel.fromJson(Map<String, dynamic> json) {
    return MarketPriceModel(
      id: JsonReader.intValue(json, 'id', defaultValue: 0) ?? 0,
      districtId:
          JsonReader.intValue(json, 'district_id', defaultValue: 0) ?? 0,
      itemName: JsonReader.string(json, 'crop_name'),
      districtName: (json['district'] as Map?)?['name']?.toString() ?? '',
      marketPriceUgx: JsonReader.numValue(json, 'price_per_kg_ugx'),
      farmGatePriceUgx: JsonReader.numValue(json, 'farm_gate_price_ugx'),
      wholesalePriceUgx: JsonReader.numValue(json, 'wholesale_price_ugx'),
      retailPriceUgx: JsonReader.numValue(json, 'retail_price_ugx'),
      priceChangePercent:
          JsonReader.numValue(json, 'price_change_percent') ?? 0,
      updatedAt: JsonReader.dateTime(json, 'updated_at'),
    );
  }
}
