part of 'priceScreen.dart';

mixin MIXPriceScreen on State<PriceScreen> {
  final List<String> _cryptoList = ["BTCUSDT", "ETHUSDT", "SOLUSDT", "AVAXUSDT", "BNBUSDT"];

  @override
  void initState() {
    super.initState();
    context.read<PriceBloc>().add(StartPriceStreaming(_cryptoList.first));
  }

  void onStart(){
    final symbol = context.read<PriceBloc>().state is Streaming 
    ? (context.read<PriceBloc>().state as Streaming).symbol 
    : _cryptoList.first;
    context.read<PriceBloc>().add(StartPriceStreaming(symbol));
  }
}