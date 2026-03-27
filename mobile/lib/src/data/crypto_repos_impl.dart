import 'dart:convert';
import 'dart:developer';

import 'package:mobile/src/domain/models/candle.dart';
import 'package:mobile/src/domain/models/price.dart';
import 'package:mobile/src/domain/packages/network/dio.dart';
import 'package:mobile/src/domain/packages/network/websocket.dart';
import 'package:mobile/src/domain/repositories/i_crypto_repository.dart';

class CryptoRepositoryImpl implements ICryptoRepository {
  final ApiClient _apiClient;
  final WebSocketClient _wsClient;

  CryptoRepositoryImpl(this._apiClient, this._wsClient);

  @override
  Future<List<CandleModel>> getHistory(String symbol) async {
    final cleanSymbol = symbol.trim();
    String endpoint = '/api/v1/prices/$cleanSymbol/history';
    try {
    final response = await _apiClient.dio.get(endpoint);
    dynamic rawData = response.data;

    if (rawData is String) {
      try {
        String decodedString = utf8.decode(base64Decode(rawData));
        rawData = jsonDecode(decodedString);
      } catch (e) {
        return [];
      }
    }

    if (rawData is List) {
      return rawData
          .map((e) => CandleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];

  } catch (e) {
    return [];
  }
  }
@override
Future<PriceModel> getLastPrice(String symbol) async {
  try {
    final response = await _apiClient.dio.get('/api/v1/prices/$symbol/latest');
    dynamic rawData = response.data;

    if (rawData is String) {
      try {
        rawData = jsonDecode(rawData);
      } catch (e) {
        return const PriceModel();
      }
    }

    if (rawData is Map<String, dynamic>) {
      return PriceModel.fromJson(rawData);
    }

    return const PriceModel();

  } catch (e) {
    return const PriceModel();
  }
}

  @override
  Stream<PriceModel> getPriceStream(String initialSymbol) {
    return _wsClient.connect("/$initialSymbol").map((data) {
      return PriceModel.fromJson(jsonDecode(data));
    });
  }

  @override
  void switchSymbol(String oldSymbol, String newSymbol) {
    log("Symbol Switch Requested: $oldSymbol -> $newSymbol");
    _wsClient.changeSymbol(oldSymbol, newSymbol);
  }

  @override
  void dispose() {
    _wsClient.disconnect();
  }
}