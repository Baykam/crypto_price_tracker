# Crypto Price Tracker (Flutter)

A cross-platform Flutter app that displays real-time cryptocurrency prices with chart history and symbol switching. The app is designed with clean architecture, BLoC state management, and a repository layer to handle REST and WebSocket data from a backend API.

## 🚀 Features

- Live price streaming for selected crypto symbols (e.g., BTCUSDT, ETHUSDT, SOLUSDT, AVAXUSDT, BNBUSDT)
- Price change percentage (24h), current price display, and colored up/down indicator
- Candle history rendering via a responsive chart widget
- Symbol selector component with active state highlight
- Error and loading states with retry support
- Dependency injection and modular folder structure (`core`, `data`, `domain`, `presentation`, `ui`)

## 🏗 Architecture

- `BCLoC` pattern (`PriceBloc`) manages events and states:
  - `StartPriceStreaming`, `SwitchSymbolEvent`, private updates, errors
- `ICryptoRepository` interface with `CryptoRepositoryImpl`
- `ApiClient` via Dio for REST endpoints:
  - `GET /api/v1/prices/{symbol}/latest`
  - `GET /api/v1/prices/{symbol}/history`
- `WebSocketClient` for live streaming:
  - connect to `/{symbol}` endpoint
- Domain models:
  - `PriceModel` and `CandleModel`

## 📁 Main file structure

- `lib/main.dart` → app entrypoint
- `lib/src/app.dart` → MaterialApp setup, home screen
- `lib/src/core/di/injection.dart` → service locator registration
- `lib/src/data/crypto_repos_impl.dart` → REST + WS implementation
- `lib/src/presentation/price` → bloc, event, state logic
- `lib/src/ui/screens/price` → UI screen and widgets (header, chart, selector)

## ▶️ Setup and run

1. Install Flutter and required SDKs (Android/iOS/Web/Desktop) if not yet installed.
2. Open project in terminal:

   ```bash
   cd c:\Users\User\Desktop\projects\crypto_price_tracker\mobile
   flutter pub get
   ```

3. Start app on desired device/emulator:

   ```bash
   flutter run
   ```

4. For specific targets:

   - Android: `flutter run -d android`
   - iOS: `flutter run -d ios`
   - Web: `flutter run -d chrome`

## 🧪 Testing

- Widget and unit tests are located in `test/`.
- Eklendiği klasörler ve testler:
  - `test/domain/model_test.dart`:
    - `PriceModel.fromJson`
    - `PriceModel.nullData`
    - `CandleModel.fromJson`
    - `CandleModel.fromList`
    - `CandleModel.fromPrice`
  - `test/presentation/price_bloc_test.dart`:
    - `PriceBloc` başlangıç durumu
    - `StartPriceStreaming` akışı
    - Tarihçeye yeni fiyat ekleme
    - Yanlış sembol güncellemesini göz ardı etme
    - `SwitchSymbolEvent` değişikliği
    - 100 mum sınırlaması
  - `test/core/state_initializer_test.dart`:
    - `StateInitializer` widget kökünü sarar
  - `test/data/crypto_repository_impl_test.dart`:
    - `CryptoRepositoryImpl.getHistory` (doğru veri)
    - `CryptoRepositoryImpl.getLastPrice` (doğru veri)
    - Geçersiz tarihçe verisi -> boş liste
    - Hata durumunda `PriceModel` default
    - WebSocket yayınından `PriceModel` dönüşüm

- Run:

  ```bash
  flutter test
  ```

## 🔧 Customization

- Change default symbols in `lib/src/ui/screens/price/functions_price.dart`:
  `final List<String> _cryptoList = ["BTCUSDT", "ETHUSDT", "SOLUSDT", "AVAXUSDT", "BNBUSDT"];`
- Adjust backend endpoints in `lib/src/data/crypto_repos_impl.dart`.
- Add support for additional symbols and data points in `domain/models`.

## 📡 Backend expectations

The mobile app assumes API server provides:
- `GET /api/v1/prices/{symbol}/latest` (returns {symbol, price, change24h, ...})
- `GET /api/v1/prices/{symbol}/history` (returns candle array)
- WebSocket channel `/[symbol]` (JSON price updates)

### 🔌 Backend connection details

- Default API host is configured in `lib/src/domain/packages/network/dio.dart` (or similar network config class).
- WebSocket host is configured in `lib/src/domain/packages/network/websocket.dart`.
- If your backend IP or domain changes, update the host URL there, then rebuild.
- For local testing, point to your local server (e.g., `http://127.0.0.1:8080` or `ws://127.0.0.1:8080`).
- For production, point to your public backend (e.g., `https://api.mydomain.com` / `wss://socket.mydomain.com`).

### 🔁 How to change API base URL and websockets on IP change

1. Open `lib/src/domain/packages/network/dio.dart` and locate base URL value (example: `baseUrl: "http://your-ip:port"`).
2. Open `lib/src/domain/packages/network/websocket.dart` and set websocket host accordingly (example: `ws://your-ip:port`).
3. Re-run `flutter pub get` (not always needed but safe):

   ```bash
   flutter pub get
   ```

4. Hot restart / re-run app:

   ```bash
   flutter run
   ```

> Tip: set these in a shared config file or environment variable for easier switching between dev/test/prod.

## 🙌 Notes

- Error states use `CryptoLottieErrorView` (see `lib/src/ui/helpers/price/shimmer.dart`).
- Data resilience is included: fallback to empty models if API parses fail.
- This README is English as requested.

## ⬇️ Download / Clone

This project is open-source on GitHub:

- https://github.com/Baykam/crypto_price_tracker/tree/main/mobile

Clone and run:

```bash
git clone https://github.com/Baykam/crypto_price_tracker.git
cd crypto_price_tracker/mobile
flutter pub get
flutter run
```

If you publish APK/IPA bundles, add the download link here (e.g., GitHub Releases, Firebase App Distribution, or a dedicated website).

