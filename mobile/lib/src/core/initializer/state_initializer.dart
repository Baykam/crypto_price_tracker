import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/presentation/price/priceBloc.dart';

class StateInitializer extends StatelessWidget {
  const StateInitializer({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<PriceBloc>()),
      ], 
      child: child,
    );
  }
}
