import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/presentation/price/priceBloc.dart';

class CoinSelector extends StatelessWidget {
  const CoinSelector({
    super.key,
    required this.cryptoList,
    required this.activeSymbol,
    this.isVertical = false,
  });

  final List<String> cryptoList;
  final String activeSymbol;
  final bool isVertical;

  @override
  Widget build(BuildContext context) {

    return Container(
      height: isVertical ? double.infinity : 100,
      padding: EdgeInsets.symmetric(
        vertical: isVertical ? 10 : 20,
        horizontal: isVertical ? 8 : 0,
      ),
      child: ListView.builder(
        scrollDirection: isVertical ? Axis.vertical : Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isVertical ? 0 : 16),
        itemCount: cryptoList.length,
        itemBuilder: (context, index) {
          final symbol = cryptoList[index];
          final bool isActive = symbol == activeSymbol;
          final cleanSymbol = symbol.replaceAll("USDT", "");

          if (isVertical) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () => context.read<PriceBloc>().add(SwitchSymbolEvent(symbol)),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.orangeAccent.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? Colors.orangeAccent : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isActive ? Colors.orangeAccent : Colors.grey[800],
                        child: Text(cleanSymbol[0], 
                          style: TextStyle(fontSize: 10, color: isActive ? Colors.black : Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        cleanSymbol,
                        style: TextStyle(
                          color: isActive ? Colors.orangeAccent : Colors.white70,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      if (isActive) const Icon(Icons.bar_chart_rounded, color: Colors.orangeAccent, size: 18),
                    ],
                  ),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(
                cleanSymbol,
                style: TextStyle(color: isActive ? Colors.black : Colors.white),
              ),
              selected: isActive,
              selectedColor: Colors.orangeAccent,
              backgroundColor: const Color(0xFF21262D),
              onSelected: (selected) {
                if (selected) {
                  context.read<PriceBloc>().add(SwitchSymbolEvent(symbol));
                }
              },
            ),
          );
        },
      ),
    );
  }
}