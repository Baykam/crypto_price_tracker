part of 'priceBloc.dart';

abstract class PriceEvent extends Equatable {
  const PriceEvent();
  @override
  List<Object?> get props => [];
}

class StartPriceStreaming extends PriceEvent {
  final String symbol;
  const StartPriceStreaming(this.symbol);
  @override
  List<Object?> get props => [symbol];
}

class SwitchSymbolEvent extends PriceEvent {
  final String newSymbol;
  const SwitchSymbolEvent(this.newSymbol);
  @override
  List<Object?> get props => [newSymbol];
}

class _OnPriceUpdated extends PriceEvent {
  final PriceModel? price;
  final List<CandleModel>? history;
  final String? symbol;
  const _OnPriceUpdated({this.price, this.symbol, this.history});
  @override
  List<Object?> get props => [price, symbol,history];
}

class _InternalErrorEvent extends PriceEvent {
  final String message;
  const _InternalErrorEvent(this.message);
}