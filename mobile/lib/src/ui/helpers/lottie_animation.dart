import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CryptoLottieErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final String lottieAsset; // Örn: 'assets/animations/error_connection.json'

  const CryptoLottieErrorView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    this.lottieAsset = 'assets/animations/error_connection.json', // Varsayılan animasyon
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final animationSize = screenWidth * 0.6; 

    return Center(
      child: SingleChildScrollView( 
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            Lottie.network(
            'https://assets10.lottiefiles.com/packages/lf20_ghp9v6m6.json',
            width: animationSize,
            height: animationSize,
            repeat: true,
            frameRate: FrameRate.composition,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, size: 80, color: Colors.redAccent);
            },
          ),
            // Lottie.asset(
            //   lottieAsset,
            //   width: animationSize,
            //   height: animationSize,
            //   fit: BoxFit.contain,
            //   repeat: true, 
            //   frameRate: FrameRate.composition, 
            // ),
            const SizedBox(height: 16), 
            
            const Text(
              "Bağlantı Hatası",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              "Şu an kripto borsasına ulaşamıyoruz. Endişelenmeyin, bu genellikle geçici bir durumdur.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                height: 1.6,
              ),
            ),
            
            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "(Hata Kodu: ${errorMessage.split(':').first})",
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
            
            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  "TEKRAR BAĞLAN",
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  elevation: 2,
                  shadowColor: Colors.orangeAccent.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), 
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}