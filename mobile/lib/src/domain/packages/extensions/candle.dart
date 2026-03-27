import 'package:fl_chart/fl_chart.dart';
import 'package:mobile/src/domain/models/candle.dart';

extension EXTCandle on CandleModel {
  double get body => close - open;
  double get upperShadow => high - (close > open ? close : open);
  double get lowerShadow => (close < open ? close : open) - low;
}

extension EXTCandleList on List<CandleModel> {
  List<double> get bodies => map((candle) => candle.body).toList();
  List<double> get upperShadows => map((candle) => candle.upperShadow).toList();
  List<double> get lowerShadows => map((candle) => candle.lowerShadow).toList();
  List<FlSpot> getSpots() {
    if (isEmpty) return [];
  return asMap().entries.map((e) {
    return FlSpot(
      e.value.time.millisecondsSinceEpoch.toDouble(),
      e.value.close,
    );
  }).toList();
}
}