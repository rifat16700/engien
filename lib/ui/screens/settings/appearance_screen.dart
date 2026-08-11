import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

// Simple state provider for theme/font size
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
final fontSizeProvider = StateProvider<double>((ref) => 1.0);

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final fontSize = ref.watch(fontSizeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        backgroundColor: AppTheme.tgBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Color Theme section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Color theme', style: TextStyle(color: AppTheme.tgBlue, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            secondary: const Icon(Icons.light_mode_rounded),
            value: ThemeMode.light,
            groupValue: themeMode,
            activeColor: AppTheme.tgBlue,
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            secondary: const Icon(Icons.dark_mode_rounded),
            value: ThemeMode.dark,
            groupValue: themeMode,
            activeColor: AppTheme.tgBlue,
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System default'),
            secondary: const Icon(Icons.settings_system_daydream_rounded),
            value: ThemeMode.system,
            groupValue: themeMode,
            activeColor: AppTheme.tgBlue,
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),

          const Divider(height: 1),

          // Font Size section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Font Size', style: TextStyle(color: AppTheme.tgBlue, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('A', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: fontSize,
                        min: 0.8,
                        max: 1.4,
                        divisions: 3,
                        activeColor: AppTheme.tgBlue,
                        onChanged: (v) => ref.read(fontSizeProvider.notifier).state = v,
                      ),
                    ),
                    const Text('A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                // Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Preview: Hello! This is how your messages will look.',
                    style: TextStyle(fontSize: 15 * fontSize),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Chat background
          ListTile(
            leading: const Icon(Icons.wallpaper_rounded, color: AppTheme.tgBlue),
            title: const Text('Chat Background'),
            trailing: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFC0DAE8), Color(0xFF8AB5CC)]),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Background customization coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }
}

