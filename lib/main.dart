import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;
import 'core/tdlib/tdlib_core.dart';
import 'core/providers/tdlib_event_handler.dart';
import 'core/theme/app_theme.dart';
import 'ui/root_navigator.dart';
import 'ui/screens/call/call_screen.dart';

import 'core/services/background_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeBackgroundService();

  // ─── TDLib Library Path ────────────────────────────────────────────────
  String? libraryPath;
  if (!kIsWeb) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.linux:
        libraryPath = 'libtdjson.so';
        break;
      case TargetPlatform.windows:
        libraryPath = 'tdjson.dll';
        break;
      default:
        libraryPath = null;
    }
  }

  // ─── Initialize TDLib ──────────────────────────────────────────────────
  final core = TdlibCore();
  await core.initialize(libraryPath);

  runApp(
    ProviderScope(
      overrides: [
        // TdlibCore singleton inject করা হচ্ছে
        tdlibCoreProvider.overrideWithValue(core),
      ],
      child: const NChatApp(),
    ),
  );
}

class NChatApp extends ConsumerStatefulWidget {
  const NChatApp({super.key});

  @override
  ConsumerState<NChatApp> createState() => _NChatAppState();
}

class _NChatAppState extends ConsumerState<NChatApp> {
  @override
  void initState() {
    super.initState();
    // TDLib client তৈরি করো এবং event handler শুরু করো
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final core = ref.read(tdlibCoreProvider);
      core.createClient();

      // Event handler চালু করো
      ref.read(tdlibEventHandlerProvider).start();

      // Auth state জানতে চাও
      core.send(const td.GetAuthorizationState());
    });
  }

  @override
  void dispose() {
    ref.read(tdlibEventHandlerProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NCHAT',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            const CallOverlay(),
          ],
        );
      },
      home: const RootNavigator(),
    );
  }
}
