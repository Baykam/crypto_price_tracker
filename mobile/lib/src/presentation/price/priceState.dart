part of 'priceBloc.dart';

abstract class PriceState extends Equatable {
  const PriceState();
  @override
  List<Object?> get props => [];
}

class Initial extends PriceState {}
class Loading extends PriceState {}
class Streaming extends PriceState {
  final PriceModel price;
  final List<CandleModel> history;
  final String symbol;
  const Streaming({required this.price, this.history = const[], this.symbol = ""});
  @override
  List<Object?> get props => [price, history, symbol];


  Streaming copyWith({
    PriceModel? price,
    List<CandleModel>? history,
    String? symbol,
  }){
    return Streaming(
      price: price ?? this.price,
      history: history ?? this.history,
      symbol: symbol ?? this.symbol,
    );
  }
}
class ErrorState extends PriceState {
  final String message;
  const ErrorState(this.message);
}