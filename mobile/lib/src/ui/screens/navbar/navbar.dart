import 'package:flutter/material.dart';
import 'package:mobile/src/ui/screens/home/home.dart';

part 'widgets/bottomNavbar.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> with TickerProviderStateMixin{
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Tab verilerini tek bir yerde toplayarak Scaffold'u temizliyoruz
  final List<IconData> _navIcons = [Icons.home_filled, Icons.bar_chart];

  void _onPageChanged(int index) => setState(() => _currentIndex = index);

  void _onTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              const Home(),
              const Scaffold(body: Center(child: Text("Analytics"))),
            ],
          ),


          BottomNavbar(
            icons: _navIcons,
            currentIndex: _currentIndex,
            onTap: _onTap,
          ),
        ],
      ),
    );
  }
}
