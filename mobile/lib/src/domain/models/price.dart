import 'package:equatable/equatable.dart';

class PriceModel extends Equatable {
  final String? symbol;
  final double? price;
  final double? change24h;
  final DateTime? timestamp;

  const PriceModel({
    this.symbol,
    this.price,
    this.change24h,
    this.timestamp,
  });

  PriceModel nullData(){
    return PriceModel(
      symbol: '',
      price: 0.0,
      change24h: 0.0,
      timestamp: DateTime.now(),
    );
  }

  factory PriceModel.fromJson(Map<String, dynamic> json) {
    return PriceModel(
      symbol: json['s']?.toString() ?? '',
      price: _parseToDouble(json['p']),
      change24h: _parseToDouble(json['P']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['E'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  List<Object?> get props => [symbol, price, change24h, timestamp];
}