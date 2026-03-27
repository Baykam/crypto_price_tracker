

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/domain/models/candle.dart';
import 'package:mobile/src/domain/models/price.dart';
import 'package:mobile/src/domain/repositories/i_crypto_repository.dart';

part 'priceEvent.dart';
part 'priceState.dart';
class PriceBloc extends Bloc<PriceEvent, PriceState> {
  final ICryptoRepository _repository;
  StreamSubscription<PriceModel>? _priceSubscription;

  PriceBloc(this._repository) : super(Initial()) {
    on<StartPriceStreaming>(_onStartStreaming);
    on<SwitchSymbolEvent>(_onSwitchSymbol);
    on<_OnPriceUpdated>(_onPriceUpdated);
    on<_InternalErrorEvent>((event, emit) => emit(ErrorState(event.message)));
  }

  Future<void> _onStartStreaming(StartPriceStreaming event, Emitter<PriceState> emit) async {
    emit(Loading());

    try {
      final results = await Future.wait([
        _repository.getHistory(event.symbol),
        _repository.getLastPrice(event.symbol),
      ]);

      final history = results[0] as List<CandleModel>;
      final lastPrice = results[1] as PriceModel;

      add(_OnPriceUpdated(
        history: history,
        symbol: event.symbol,
        price: lastPrice,
      ));


      await _priceSubscription?.cancel();
      _priceSubscription = _repository.getPriceStream(event.symbol).listen(
        (price) => add(_OnPriceUpdated(price: price)),
        onError: (err) => add(_InternalErrorEvent("Stream Error: $err")),
        cancelOnError: true,
        onDone: () => add(_InternalErrorEvent("Connection Lost")),
      );
    } catch (e) {
      add(_InternalErrorEvent("Initialization Error: $e"));
    }
  }

  Future<void> _onSwitchSymbol(SwitchSymbolEvent event, Emitter<PriceState> emit) async {
  final s = state;
  if (s is Streaming) {
    emit(Loading());

    try {
      _repository.switchSymbol(s.symbol, event.newSymbol);

      final newHistory = await _repository.getHistory(event.newSymbol);
      final lastPrice = await _repository.getLastPrice(event.newSymbol);

      add(_OnPriceUpdated(
        history: newHistory, 
        symbol: event.newSymbol,
        price: lastPrice,
      ));

    } catch (e) {
      emit(ErrorState("Switch Error: $e"));
    }
  }
}

  void _onPriceUpdated(_OnPriceUpdated event, Emitter<PriceState> emit) {
  final s = state;

  if (s is Streaming) {
    List<CandleModel> currentHistory = List.from(event.history ?? s.history);

    if (event.price?.symbol != null && event.price!.symbol != s.symbol) return;
    
      
    if (event.price != null && event.price?.price != null && event.price?.price != 0.0) {
      final newCandle = CandleModel.fromPrice(event.price!);
      currentHistory.add(newCandle);
      if (currentHistory.length > 100) currentHistory.removeAt(0);
    }

    emit(s.copyWith(
      price: event.price ?? s.price,
      history: currentHistory,
      symbol: event.symbol ?? s.symbol,
    ));
  } else {
    emit(Streaming(
      price: event.price ?? const PriceModel(),
      history: event.history ?? [],
      symbol: event.symbol ?? "",
    ));
  }
}

  @override
  Future<void> close() {
    terminate();
    return super.close();
  }

  void terminate(){
    _priceSubscription?.cancel();
    _repository.dispose();
  }
}