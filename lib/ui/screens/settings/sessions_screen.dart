import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/tdlib_event_handler.dart';
import '../../../core/theme/app_theme.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  void _terminateAllSessions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminate All Other Sessions'),
        content: const Text('Are you sure you want to log out all other devices?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(tdlibCoreProvider).sendRaw({'@type': 'terminateAllOtherSessions'});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All other sessions terminated'), backgroundColor: AppTheme.tgGreen),
              );
            },
            child: const Text('Terminate', style: TextStyle(color: AppTheme.tgRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        backgroundColor: AppTheme.tgBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Current device card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.tgBlue.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.tgBlue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.tgBlue, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.phone_android_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('This Device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      SizedBox(height: 2),
                      Text('Android • Active now', style: TextStyle(color: AppTheme.tgGreen, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Terminate all button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: OutlinedButton.icon(
              onPressed: _terminateAllSessions,
              icon: const Icon(Icons.logout_rounded, color: AppTheme.tgRed),
              label: const Text('Terminate All Other Sessions', style: TextStyle(color: AppTheme.tgRed)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.tgRed),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Other Active Sessions', style: TextStyle(color: AppTheme.tgBlue, fontWeight: FontWeight.bold, fontSize: 14)),
          ),

          _SessionTile(
            icon: Icons.desktop_windows_rounded,
            name: 'Telegram Web',
            subtitle: 'Chrome · Windows',
            lastActive: '5 hours ago',
            onTerminate: () {
              ref.read(tdlibCoreProvider).sendRaw({'@type': 'terminateAllOtherSessions'});
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session terminated')));
            },
          ),
          _SessionTile(
            icon: Icons.laptop_rounded,
            name: 'Telegram Desktop',
            subtitle: 'macOS 14',
            lastActive: '2 days ago',
            onTerminate: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session terminated')));
            },
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String subtitle;
  final String lastActive;
  final VoidCallback onTerminate;

  const _SessionTile({
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.lastActive,
    required this.onTerminate,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.grey[700], size: 28),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text('$subtitle\n$lastActive', style: const TextStyle(fontSize: 12)),
      isThreeLine: true,
      trailing: IconButton(
        icon: const Icon(Icons.close_rounded, color: AppTheme.tgRed),
        onPressed: onTerminate,
      ),
    );
  }
}

