import 'dart:developer';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _log('🟢 onCreate: ${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _log('🟡 onChange: ${bloc.runtimeType} | Current: ${change.currentState} -> Next: ${change.nextState}');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _log('🔵 onTransition: ${bloc.runtimeType} | Event: ${transition.event}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    _log('🔴 onError: ${bloc.runtimeType} | Error: $error');
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    _log('⚪ onClose: ${bloc.runtimeType}');
  }

  void _log(String message) {
    log(' [BLOC_GUARD] $message');
  }
}



final class ApplicationInitialize {
  Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
    FlutterError.onError = (details) {
      log(details.exceptionAsString());
    };

    await runZonedGuarded(
          () async {
            await _initialize();

            Bloc.observer = AppBlocObserver();
            runApp(await builder());
      },
          (error, stackTrace) {
            log("🚨 Uncaught Async Error: $error");
          },
    );
  }

  /// initialize method for app when starting
  Future<void> _initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          statusBarColor: Colors.transparent,
        ),
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await DependencyInjection.setup();


  }
}