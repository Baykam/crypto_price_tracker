import 'package:get_it/get_it.dart';
import 'package:mobile/src/data/crypto_repos_impl.dart';
import 'package:mobile/src/domain/packages/network/dio.dart';
import 'package:mobile/src/domain/packages/network/websocket.dart';
import 'package:mobile/src/domain/repositories/i_crypto_repository.dart';
import 'package:mobile/src/presentation/price/priceBloc.dart';
final sl = GetIt.instance; // Service Locator

final class DependencyInjection {
  static Future<void> setup() async {
    /// External
    sl.registerLazySingleton(() => ApiClient());
    sl.registerLazySingleton(() => WebSocketClient());

    /// Repository
    sl.registerLazySingleton<ICryptoRepository>(
          () => CryptoRepositoryImpl(sl(), sl()),
    );

    /// Bloc
    sl.registerFactory(() => PriceBloc(sl()));
  }
}