import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mobile/src/ui/screens/navbar/navbar.dart';

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
    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      home: Navbar(),
    );
  }
}
