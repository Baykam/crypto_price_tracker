import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/src/core/initializer/state_initializer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  testWidgets('StateInitializer wraps child with MultiBlocProvider',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StateInitializer(
          child: const Text('wrapped'),
        ),
      ),
    );

    expect(find.text('wrapped'), findsOneWidget);
    expect(find.byType(MultiBlocProvider), findsOneWidget);
  });
}
