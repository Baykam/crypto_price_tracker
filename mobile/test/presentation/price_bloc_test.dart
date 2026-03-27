import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/src/domain/models/candle.dart';
import 'package:mobile/src/domain/models/price.dart';
import 'package:mobile/src/domain/repositories/i_crypto_repository.dart';
import 'package:mobile/src/presentation/price/priceBloc.dart';

class FakeCryptoRepository implements ICryptoRepository {
  final StreamController<PriceModel> _streamController =
      StreamController.broadcast();
  final List<CandleModel> baseHistory;
  final PriceModel basePrice;

  String currentSymbol;

  FakeCryptoRepository(
      {required this.currentSymbol,
      required this.baseHistory,
      required this.basePrice});

  @override
  Future<List<CandleModel>> getHistory(String symbol) async => baseHistory;

  @override
  Future<PriceModel> getLastPrice(String symbol) async => basePrice;

  @override
  Stream<PriceModel> getPriceStream(String initialSymbol) {
    currentSymbol = initialSymbol;
    return _streamController.stream;
  }

  @override
  void switchSymbol(String oldSymbol, String newSymbol) {
    if (oldSymbol != currentSymbol) throw StateError('Symbol mismatch');
    currentSymbol = newSymbol;
  }

  @override
  void dispose() => _streamController.close();

  void push(PriceModel price) => _streamController.add(price);
}

void main() {
  group('PriceBloc', () {
    late FakeCryptoRepository repository;
    late PriceBloc bloc;

    setUp(() {
      repository = FakeCryptoRepository(
        currentSymbol: 'BTCUSDT',
        baseHistory: [
          CandleModel(
              time: DateTime.now(),
              open: 44000,
              high: 45000,
              low: 43500,
              close: 44800,
              volume: 1000),
        ],
        basePrice: PriceModel(
            symbol: 'BTCUSDT',
            price: 44800,
            change24h: 1.1,
            timestamp: DateTime.now()),
      );
      bloc = PriceBloc(repository);
    });

    tearDown(() async {
      await bloc.close();
    });

    test('initial state is Initial', () {
      expect(bloc.state, isA<Initial>());
    });

    test('StartPriceStreaming emits Loading then Streaming', () async {
      bloc.add(const StartPriceStreaming('BTCUSDT'));

      await expectLater(
          bloc.stream, emitsInOrder([isA<Loading>(), isA<Streaming>()]));
    });

    test('price events update history and value', () async {
      bloc.add(const StartPriceStreaming('BTCUSDT'));
      await expectLater(bloc.stream, emitsThrough(isA<Streaming>()));

      repository.push(PriceModel(
          symbol: 'BTCUSDT', price: 44900, timestamp: DateTime.now()));

      await expectLater(
        bloc.stream,
        emits(predicate<PriceState>((state) {
          return state is Streaming &&
              state.history.length == 2 &&
              state.price.price == 44900;
        })),
      );
    });

    test('price update with wrong symbol is ignored', () async {
      bloc.add(const StartPriceStreaming('BTCUSDT'));
      await expectLater(bloc.stream, emitsThrough(isA<Streaming>()));

      final before = bloc.state as Streaming;
      repository.push(PriceModel(
          symbol: 'ETHUSDT', price: 1800, timestamp: DateTime.now()));
      await Future.delayed(const Duration(milliseconds: 100));

      final after = bloc.state as Streaming;
      expect(after.symbol, before.symbol);
      expect(after.history.length, before.history.length);
    });

    test('switch symbol emits Loading then Streaming with new symbol',
        () async {
      bloc.add(const StartPriceStreaming('BTCUSDT'));
      await expectLater(bloc.stream, emitsThrough(isA<Streaming>()));

      repository.switchSymbol('BTCUSDT', 'ETHUSDT');
      bloc.add(const SwitchSymbolEvent('ETHUSDT'));

      await expectLater(
          bloc.stream, emitsInOrder([isA<Loading>(), isA<Streaming>()]));
      expect((bloc.state as Streaming).symbol, 'ETHUSDT');
    });

    test('history limits at 100 candles', () async {
      bloc.add(const StartPriceStreaming('BTCUSDT'));
      await expectLater(bloc.stream, emitsThrough(isA<Streaming>()));

      for (var i = 0; i < 120; i++) {
        repository.push(PriceModel(
            symbol: 'BTCUSDT',
            price: (45000 + i).toDouble(),
            timestamp: DateTime.now().add(Duration(seconds: i))));
      }

      await Future.delayed(const Duration(milliseconds: 200));
      final finalState = bloc.state as Streaming;
      expect(finalState.history.length, lessThanOrEqualTo(100));
    });
  });
}
