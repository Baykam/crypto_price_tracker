import 'package:flutter/material.dart';
import 'package:mobile/src/presentation/price/priceBloc.dart';

class PriceHeader extends StatelessWidget {
  const PriceHeader({super.key, required this.state});
  final Streaming state;
  @override
  Widget build(BuildContext context) {
    final bool isPositive = (state.price.change24h ?? 0) >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(state.symbol, style: const TextStyle(fontSize: 18, color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            "\$${state.price.price?.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            "${isPositive ? '+' : ''}${state.price.change24h?.toStringAsFixed(2)}%",
            style: TextStyle(
                fontSize: 18,
                color: isPositive ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.w600
            ),
          ),
          Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
    ),
    const SizedBox(width: 8),
    Text(state.symbol, style: const TextStyle(fontSize: 18, color: Colors.white70)),
  ],
),
        ],
      ),
    );
  }
}