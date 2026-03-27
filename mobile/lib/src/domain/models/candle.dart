import 'package:equatable/equatable.dart';
import 'package:mobile/src/domain/models/price.dart';

class CandleModel extends Equatable {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const CandleModel({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory CandleModel.fromList(List<dynamic> list) {
    return CandleModel(
      time: DateTime.fromMillisecondsSinceEpoch(list[0]),
      open: double.parse(list[1].toString()),
      high: double.parse(list[2].toString()),
      low: double.parse(list[3].toString()),
      close: double.parse(list[4].toString()),
      volume: double.parse(list[5].toString()),
    );
  }

  factory CandleModel.fromJson(Map<String, dynamic> json) {
    return CandleModel(
      time: DateTime.fromMillisecondsSinceEpoch(json['open_time']),
      open: double.tryParse(json['open'] ?? '0.0') ?? 0.0,
      high: double.tryParse(json['high'] ?? '0.0') ?? 0.0,
      low: double.tryParse(json['low'] ?? '0.0') ?? 0.0,
      close: double.tryParse(json['close'] ?? '0.0') ?? 0.0,
      volume: double.tryParse(json['volume'] ?? '0.0') ?? 0.0,
    );
  }

  factory CandleModel.fromPrice(PriceModel price){
    return CandleModel(
      time: price.timestamp ?? DateTime.now(),
      open: price.price ?? 0.0,
      high: price.price ?? 0.0,
      low: price.price ?? 0.0,
      close: price.price ?? 0.0,
      volume: 0.0,
    );
  }

  @override
  List<Object?> get props => [time, open, high, low, close, volume];
}