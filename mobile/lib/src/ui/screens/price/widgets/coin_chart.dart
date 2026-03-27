import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mobile/src/domain/packages/extensions/candle.dart';
import 'package:mobile/src/presentation/price/priceBloc.dart';

class CoinChart extends StatelessWidget {
  const CoinChart({super.key, required this.state});
  final Streaming state;
  @override
  Widget build(BuildContext context) {
    final spots = state.history.getSpots();

  if (spots.isEmpty) {
    return const Center(
      child: Text("Veri yükleniyor...", style: TextStyle(color: Colors.white54)),
    );
  }

  final minX = spots.first.x;
  final maxX = spots.last.x;

  return LineChart(
    LineChartData(
      minX: minX,
      maxX: maxX,
      minY: state.history.map((e) => e.low).reduce((a, b) => a < b ? a : b) * 0.999,
      maxY: state.history.map((e) => e.high).reduce((a, b) => a > b ? a : b) * 1.001,
      
      gridData: FlGridData(show: false), 
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(show: false),

      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.orangeAccent.withOpacity(0.8),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              return LineTooltipItem(
                '\$${barSpot.y.toStringAsFixed(2)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            }).toList();
          },
        ),
      ),

      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: Colors.orangeAccent,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.orangeAccent.withOpacity(0.3),
                Colors.orangeAccent.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    ),
  );
  }
}