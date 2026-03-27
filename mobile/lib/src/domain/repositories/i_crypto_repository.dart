import 'package:mobile/src/domain/models/candle.dart';
import 'package:mobile/src/domain/models/price.dart';

abstract class ICryptoRepository {
  /// History data take (REST)
  Future<List<CandleModel>> getHistory(String symbol);

  /// Stream broadcast start (WS)
  Stream<PriceModel> getPriceStream(String initialSymbol);

  /// Last Price get (REST)
  Future<PriceModel> getLastPrice(String symbol);

  /// Current Stream used and change symbol
  void switchSymbol(String oldSymbol, String newSymbol);

  /// Close all controllers
  void dispose();
}