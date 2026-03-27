import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/presentation/price/priceBloc.dart';
import 'package:mobile/src/ui/helpers/lottie_animation.dart';
import 'package:mobile/src/ui/helpers/price/shimmer.dart';
import 'package:mobile/src/ui/screens/price/widgets/coin_chart.dart';
import 'package:mobile/src/ui/screens/price/widgets/coin_selector.dart';
import 'package:mobile/src/ui/screens/price/widgets/price_header.dart';
import 'package:responsive_framework/responsive_framework.dart';

part 'functions_price.dart';

class PriceScreen extends StatefulWidget {
  const PriceScreen({super.key});

  @override
  State<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> with MIXPriceScreen {
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final isTablet = ResponsiveBreakpoints.of(context).isTablet;
    final isDesktop = ResponsiveBreakpoints.of(context).isDesktop;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text("Live Crypto Guard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<PriceBloc, PriceState>(
        builder: (context, state) {
          if (state is Loading) return PriceShimmer();
          if (state is ErrorState) return CryptoLottieErrorView(errorMessage: state.message, onRetry: onStart);
          
          if (state is Streaming) {
            // Masaüstü veya Geniş Tablet modunda yan yana (Row) yerleşim
            if (isDesktop || (isTablet && MediaQuery.of(context).orientation == Orientation.landscape)) {
              return Row(
                children: [
                  // Sol taraf: Grafik ve Header
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        PriceHeader(state: state),
                        Expanded(child: _buildChart(state)),
                      ],
                    ),
                  ),
                  Container(
                    width: 300,
                    margin: const EdgeInsets.only(right: 16, bottom: 16, top: 16),
                    child: CoinSelector(
                      cryptoList: _cryptoList, 
                      activeSymbol: state.symbol,
                      isVertical: !isMobile,
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                PriceHeader(state: state),
                Expanded(child: _buildChart(state)),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 24 : 8),
                  child: CoinSelector(
                    cryptoList: _cryptoList, 
                    activeSymbol: state.symbol
                  ),
                )
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }


  Widget _buildChart(Streaming state) {
    return Container(
      padding: const EdgeInsets.only(top: 24, right: 15, left: 15),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CoinChart(state: state),
    );
  }
}