import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/src/data/crypto_repos_impl.dart';
import 'package:mobile/src/domain/models/candle.dart';
import 'package:mobile/src/domain/packages/network/dio.dart';
import 'package:mobile/src/domain/packages/network/websocket.dart';

class FakeHttpClientAdapter implements HttpClientAdapter {
  final dynamic responseData;
  final bool shouldThrow;

  FakeHttpClientAdapter({this.responseData, this.shouldThrow = false});

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (shouldThrow) {
      throw DioException(
        requestOptions: options,
        error: 'Network error',
        type: DioExceptionType.connectionError,
      );
    }

    final json = jsonEncode(responseData);
    return ResponseBody.fromString(json, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }
}

ApiClient buildFakeApiClient(dynamic responseData, {bool throwError = false}) {
  final dio = Dio();
  dio.httpClientAdapter = FakeHttpClientAdapter(
    responseData: responseData,
    shouldThrow: throwError,
  );
  return ApiClient(dio: dio);
}


class FakeApiClient extends ApiClient {
  final dynamic data;
  final bool shouldThrow;

  FakeApiClient({this.data, this.shouldThrow = false})
      : super(dio: Dio()) {
    dio.httpClientAdapter = FakeHttpClientAdapter(
      responseData: data,
      shouldThrow: shouldThrow,
    );
  }
}

class FakeWebSocketClient extends WebSocketClient {
  final StreamController<String> controller;

  FakeWebSocketClient(this.controller);

  @override
  Stream<dynamic> connect(String initialSymbol) {
    return controller.stream;
  }

  @override
  void changeSymbol(String oldSymbol, String newSymbol) {
    // no op
  }

  @override
  void disconnect() {
    controller.close();
  }
}

void main() {
  test('CryptoRepositoryImpl getHistory from JSON list', () async {
    final repo = CryptoRepositoryImpl(
      buildFakeApiClient([
        {
          'open_time': 1650000000000,
          'open': '1.0',
          'high': '2.0',
          'low': '0.5',
          'close': '1.5',
          'volume': '10.0'
        }
      ]),
      FakeWebSocketClient(StreamController()),
    );

    final history = await repo.getHistory('BTCUSDT');
    expect(history, isNotEmpty);
    expect(history.first, isA<CandleModel>());
  });

  test('getLastPrice returns PriceModel from JSON map', () async {
    final json = {
      's': 'BTCUSDT',
      'p': '47000.2',
      'P': '1.3',
      'E': 1650000000000
    };
    final repo = CryptoRepositoryImpl(
      buildFakeApiClient(json),
      FakeWebSocketClient(StreamController()),
    );

    final lastPrice = await repo.getLastPrice('BTCUSDT');
    expect(lastPrice.symbol, 'BTCUSDT');
    expect(lastPrice.price, 47000.2);
  });

  test('getHistory returns empty list on invalid data type', () async {
    final repo = CryptoRepositoryImpl(
      buildFakeApiClient({'foo': 'bar'}),
      FakeWebSocketClient(StreamController()),
    );

    final history = await repo.getHistory('BTCUSDT');
    expect(history, isEmpty);
  });

  test('getLastPrice returns default PriceModel on Dio error', () async {
    final repo = CryptoRepositoryImpl(
      buildFakeApiClient(null, throwError: true),
      FakeWebSocketClient(StreamController()),
    );

    final lastPrice = await repo.getLastPrice('BTCUSDT');
    expect(lastPrice.price, 0.0);
  });

  test('getPriceStream transforms websocket messages to PriceModel', () async {
    final controller = StreamController<String>();
    final ws = FakeWebSocketClient(controller);
    final repo = CryptoRepositoryImpl(buildFakeApiClient([]), ws);

    final stream = repo.getPriceStream('BTCUSDT');
    final future = stream.first;

    controller.add('{"s":"BTCUSDT","p":"47100","P":"0.1","E":1650000000000}');

    final res = await future;
    expect(res.symbol, 'BTCUSDT');
    expect(res.price, 47100);
    await controller.close();
  });
}