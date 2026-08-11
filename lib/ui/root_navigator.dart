import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/auth_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'splash_screen.dart';

class RootNavigator extends ConsumerWidget {
  const RootNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    Widget currentScreen;
    if (authState.isInitializing || authState.authorizationState == 'authorizationStateWaitTdlibParameters' || authState.authorizationState == 'authorizationStateWaitEncryptionKey') {
      currentScreen = const SplashScreen();
    } else if (authState.isReady) {
      currentScreen = const HomeScreen();
    } else {
      currentScreen = const AuthScreen();
    }

    return currentScreen;
  }
}
