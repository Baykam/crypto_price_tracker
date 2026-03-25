import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LineChartHome extends StatefulWidget {
  const LineChartHome({super.key});

  @override
  State<LineChartHome> createState() => _LineChartHomeState();
}

class _LineChartHomeState extends State<LineChartHome> {
  // Seçili olan zaman aralığı
  String selectedPeriod = '1W';

  // Zaman aralıkları listesi
  final List<String> periods = ['1D', '1W', '1M', '3M', '1Y', 'All'];

  // Örnek veri setleri (Gerçek projede bunları API'den veya bir repository'den alabilirsin)
  final Map<String, List<FlSpot>> allSpots = {
    '1D': [const FlSpot(0, 3), const FlSpot(1, 5), const FlSpot(2, 4), const FlSpot(3, 7)],
    '1W': [const FlSpot(0, 4), const FlSpot(1, 3.5), const FlSpot(2, 5), const FlSpot(3, 4.2), const FlSpot(4, 6), const FlSpot(5, 5.8)],
    '1M': [const FlSpot(0, 2), const FlSpot(1, 4), const FlSpot(2, 3), const FlSpot(3, 8), const FlSpot(4, 6), const FlSpot(5, 9)],
    // ... diğerleri için de veri ekleyebilirsin
  };

  @override
  Widget build(BuildContext context) {
    // Seçili periyoda ait veriyi al, yoksa boş liste döndür
    List<FlSpot> currentSpots = allSpots[selectedPeriod] ?? allSpots['1W']!;

    return Column(
      children: [
        // 1. Grafik Alanı
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 270, // Tablara yer açmak için yüksekliği biraz kıstık
          child: LineChart(
            LineChartData(
              // Dinamik sınırlar: Verinin X ve Y değerine göre otomatik ölçeklenebilir
              minX: currentSpots.first.x,
              maxX: currentSpots.last.x,
              minY: 0,
              maxY: 10,

              backgroundColor: Colors.transparent,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false, // Dikey çizgileri kapatmak daha modern durur
                horizontalInterval: 2,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.black.withOpacity(0.05),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
              ),

              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.transparent, // Eski kutuyu gizle
                  getTooltipItems: (touchedSpots) => touchedSpots.map((_) => null).toList(),
                ),
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  return spotIndexes.map((index) => TouchedSpotIndicatorData(
                    FlLine(color: Colors.black.withOpacity(0.1), strokeWidth: 2, dashArray: [5, 5]),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 6,
                        color: Colors.black,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  )).toList();
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value % 2 == 0) {
                        return Text(value.toInt().toString(), style: const TextStyle(color: Colors.black38, fontSize: 10));
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),

              lineBarsData: [
                LineChartBarData(
                  spots: currentSpots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: Colors.black,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.1), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 2. Zaman Aralığı Tableri (Selector)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.03), // Hafif gri arka plan
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: periods.map((period) {
              bool isSelected = selectedPeriod == period;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPeriod = period;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blueAccent : Colors.transparent, // Seçili tab mavi
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    period,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black54,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}