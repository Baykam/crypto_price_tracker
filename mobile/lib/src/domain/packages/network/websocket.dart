import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient {
  WebSocketChannel? _channel;
  StreamController<dynamic>? _controller;
  final String _baseWsUrl = "ws://localhost:8080/ws";
  
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  String? _currentSymbol;
  int _reconnectAttempts = 0;

  Stream<dynamic> connect(String initialSymbol) {
    _isDisposed = false;
    _currentSymbol = initialSymbol;
    
    _controller = StreamController<dynamic>.broadcast();
    
    _establishConnection();

    return _controller!.stream;
  }

  void _establishConnection() {
    if (_isDisposed || _currentSymbol == null) return;

    final url = Uri.parse("$_baseWsUrl/$_currentSymbol");
    print("🔌 Bağlanılıyor: $url");
    
    try {
    _channel = WebSocketChannel.connect(url);

    _channel!.stream.listen(
      (data) {
        _reconnectAttempts = 0;
        _controller?.add(data);
      },
      onError: (e) {
        print("❌ WS Hatası: $e");
        _controller?.addError(e); 
        _scheduleReconnect();
      },
      onDone: () {
        if (!_isDisposed) {
          _controller?.addError("Bağlantı Kapandı");
          _scheduleReconnect();
        }
      },
    );
  } catch (e) {
    _controller?.addError("Bağlantı Kurulamıyor: $e");
    _scheduleReconnect();
  }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    if (_reconnectAttempts >= 5) {
      print("❌ 5 başarısız deneme sonrası yeniden bağlanmayı durduruyor.");
      _reconnectTimer?.cancel();
      return;
    }
    _reconnectAttempts++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      print("🔄 Yeniden bağlanmayı deniyor...");
      _establishConnection();
    });
  }

  void changeSymbol(String oldSymbol, String newSymbol) {
    if (_channel != null) {
      _currentSymbol = newSymbol;
      _channel!.sink.add("$oldSymbol->$newSymbol");
      print("🚀 Sembol Değiştirme İsteği: $oldSymbol -> $newSymbol");
    } else {
      print("❌ Hata: Aktif bir bağlantı yok!");
    }
  }

  void disconnect() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _controller?.close();
    _controller = null;
    print("🔌 Bağlantı Tamamen Kapatıldı.");
  }
}