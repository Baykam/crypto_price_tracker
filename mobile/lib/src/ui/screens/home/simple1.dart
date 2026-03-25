import 'package:flutter/material.dart';

class MemeCoinDashboard extends StatelessWidget {
  const MemeCoinDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Görseldeki Neon Yeşil Renk
    const Color neonGreen = Color(0xFFD4F06B);
    const Color darkBg = Color(0xFF121212);

    return Scaffold(
      backgroundColor: neonGreen, // Üst kısmın taşmalarını korumak için
      body: CustomScrollView(
        slivers: [
          // 1. Üst Kısım: Bakiye ve Grafik
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
              color: neonGreen,
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  const Text("10 780,48 \$", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  const SizedBox(height: 8),
                  _buildPriceChangeTag(),
                  const SizedBox(height: 40),
                  _buildSimpleWaveChart(), // Basit dalgalı çizgi grafiği temsili
                  const SizedBox(height: 40),
                  _buildTimeFilters(),
                ],
              ),
            ),
          ),

          // 2. Alt Kısım: Siyah Liste Paneli
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              decoration: const BoxDecoration(
                color: darkBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Sürüklenebilir bar çizgisi
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Asset", style: TextStyle(color: Colors.white54, fontSize: 13)),
                        Text("Price", style: TextStyle(color: Colors.white54, fontSize: 13)),
                        Text("Holdings", style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),

                  // Coin Listesi
                  _buildAssetItem("Bonk", "BONK", "0,00002989 \$", "- 2,15 %", "345,76 \$", "10,76 M BONK", Colors.orange),
                  _buildAssetItem("ai16z", "ai16z", "1,1264 \$", "+ 22,55 %", "500,93 \$", "560,23 AI16Z", Colors.deepPurpleAccent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Yardımcı Widgetlar ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const CircleAvatar(backgroundColor: Colors.pinkAccent, child: Text("😎")),
        DropdownButton<String>(
          value: 'My Meme Coins',
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          items: ['My Meme Coins'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))).toList(),
          onChanged: (_) {},
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
          child: const Icon(Icons.add, color: Colors.white),
        )
      ],
    );
  }

  Widget _buildPriceChangeTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
      child: const Text("+ 740,44 \$ (+ 2,15 %)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTimeFilters() {
    final filters = ["1D", "1W", "1M", "3M", "1Y", "All"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: filters.map((f) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: f == "1W" ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(f, style: TextStyle(color: f == "1W" ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
      )).toList(),
    );
  }

  Widget _buildAssetItem(String name, String symbol, String price, String change, String val, String amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color, radius: 24, child: const Icon(Icons.token, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(symbol, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text(change, style: TextStyle(color: change.contains('+') ? Colors.greenAccent : Colors.redAccent, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text(amount, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // Grafik alanı için CustomPainter kullanılabilir, burada basitçe placeholder geçiyorum
  Widget _buildSimpleWaveChart() {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: CustomPaint(painter: _WavePainter()),
    );
  }
}

// Basit Çizgi Grafik Painter'ı
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 3;
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.2, size.width * 0.4, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.9, size.width * 0.8, size.height * 0.3);
    path.lineTo(size.width, size.height * 0.4);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}