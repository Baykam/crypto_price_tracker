import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/src/domain/models/candle.dart';
import 'package:mobile/src/domain/models/price.dart';

void main() {
  group('PriceModel', () {
    test('fromJson parses numeric and string fields correctly', () {
      final json = {
        's': 'BTCUSDT',
        'p': '47000.25',
        'P': '1.3',
        'E': 1650000000000
      };
      final model = PriceModel.fromJson(json);

      expect(model.symbol, 'BTCUSDT');
      expect(model.price, 47000.25);
      expect(model.change24h, 1.3);
      expect(model.timestamp?.millisecondsSinceEpoch.toString(), 1650000000000);
    });

    test('nullData returns non-null fields with defaults', () {
      final m = const PriceModel().nullData();
      expect(m.symbol, '');
      expect(m.price, 0.0);
      expect(m.change24h, 0.0);
      expect(m.timestamp, isA<DateTime>());
    });

    test('parseToDouble handles null, num, and string', () {
      expect(PriceModel.parseToDouble(null), 0.0);
      expect(PriceModel.parseToDouble(1), 1.0);
      expect(PriceModel.parseToDouble('15.5'), 15.5);
      expect(PriceModel.parseToDouble('xxx'), 0.0);
    });
  });

  group('CandleModel', () {
    test('fromJson works with valid map', () {
      final json = {
        'open_time': 1650000000000,
        'open': '1.0',
        'high': '2.0',
        'low': '0.5',
        'close': '1.5',
        'volume': '10.0'
      };
      final candle = CandleModel.fromJson(json);

      expect(candle.time.millisecondsSinceEpoch, 1650000000000);
      expect(candle.open, 1.0);
      expect(candle.high, 2.0);
      expect(candle.low, 0.5);
      expect(candle.close, 1.5);
      expect(candle.volume, 10.0);
    });

    test('fromList works with dynamic array', () {
      final list = [1650000000000, '1.0', '2.0', '0.5', '1.5', '10.0'];
      final candle = CandleModel.fromList(list);

      expect(candle.time.millisecondsSinceEpoch, 1650000000000);
      expect(candle.open, 1.0);
      expect(candle.high, 2.0);
      expect(candle.low, 0.5);
      expect(candle.close, 1.5);
      expect(candle.volume, 10.0);
    });

    test('fromPrice converts PriceModel to CandleModel with same in/out values',
        () {
      final now = DateTime.now();
      final price =
          PriceModel(symbol: 'BTCUSDT', price: 48500.0, timestamp: now);
      final candle = CandleModel.fromPrice(price);

      expect(candle.time, now);
      expect(candle.open, 48500.0);
      expect(candle.high, 48500.0);
      expect(candle.low, 48500.0);
      expect(candle.close, 48500.0);
      expect(candle.volume, 0.0);
    });
  });
}
