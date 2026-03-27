import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PriceShimmer extends StatelessWidget {
  const PriceShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF161B22),
      highlightColor: const Color(0xFF21262D),
      child: Column(
        children: [
          // 1. Header Shimmer (Fiyat ve Sembol)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Container(width: 80, height: 20, color: Colors.white),
                const SizedBox(height: 12),
                Container(width: 180, height: 45, color: Colors.white),
                const SizedBox(height: 8),
                Container(width: 60, height: 18, color: Colors.white),
              ],
            ),
          ),

          // 2. Grafik Alanı Shimmer
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // 3. Coin Selector Shimmer
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              children: List.generate(4, (index) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 80,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}