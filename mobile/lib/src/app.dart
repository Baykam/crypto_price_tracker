import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mobile/src/core/initializer/state_initializer.dart';
import 'package:mobile/src/ui/screens/price/priceScreen.dart';
import 'package:responsive_framework/responsive_framework.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse, // for desktop working gesture
  };
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return StateInitializer(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        scrollBehavior: MyCustomScrollBehavior(),
        home: PriceScreen(),
        builder: (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: [
              Breakpoint(start: 0, end: 450, name: MOBILE),
              Breakpoint(start: 451, end: 800, name: TABLET),
              Breakpoint(start: 801, end: double.infinity, name: DESKTOP),
            ],
          ),
      ),
    );
  }
}
