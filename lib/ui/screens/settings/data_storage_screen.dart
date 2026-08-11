import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/tdlib_event_handler.dart';
import '../../../core/theme/app_theme.dart';

class DataStorageScreen extends ConsumerStatefulWidget {
  const DataStorageScreen({super.key});

  @override
  ConsumerState<DataStorageScreen> createState() => _DataStorageScreenState();
}

class _DataStorageScreenState extends ConsumerState<DataStorageScreen> {
  bool _mobileData = false;
  bool _wifi = true;
  bool _roaming = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data and Storage'),
        backgroundColor: AppTheme.tgBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Storage section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Storage', style: TextStyle(color: AppTheme.tgBlue, fontWeight: FontWeight.bold, fontSize: 13)),
          ),

          // Estimated usage
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.storage_rounded, color: AppTheme.tgBlue, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cache Usage', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.35,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation(AppTheme.tgBlue),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('~120 MB of 500 MB', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.delete_sweep_rounded, color: AppTheme.tgRed),
            title: const Text('Clear Cache', style: TextStyle(color: AppTheme.tgRed)),
            subtitle: const Text('Free up space by clearing cached media', style: TextStyle(fontSize: 12)),
            onTap: () {
              ref.read(tdlibCoreProvider).sendRaw({'@type': 'optimizeStorage', 'size': 0, 'ttl': 0, 'count': 0, 'immunity_delay': 0});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared!'), backgroundColor: AppTheme.tgGreen),
              );
            },
          ),

          const Divider(height: 1),

          // Auto-download section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Automatic media download', style: TextStyle(color: AppTheme.tgBlue, fontWeight: FontWeight.bold, fontSize: 13)),
          ),

          SwitchListTile(
            secondary: const Icon(Icons.signal_cellular_alt_rounded, color: AppTheme.tgBlue),
            title: const Text('Mobile Data'),
            subtitle: const Text('Download media on mobile data', style: TextStyle(fontSize: 12)),
            value: _mobileData,
            activeColor: AppTheme.tgBlue,
            onChanged: (v) => setState(() => _mobileData = v),
          ),
          const Divider(indent: 56, height: 1),

          SwitchListTile(
            secondary: const Icon(Icons.wifi_rounded, color: AppTheme.tgBlue),
            title: const Text('Wi-Fi'),
            subtitle: const Text('Download media on Wi-Fi', style: TextStyle(fontSize: 12)),
            value: _wifi,
            activeColor: AppTheme.tgBlue,
            onChanged: (v) => setState(() => _wifi = v),
          ),
          const Divider(indent: 56, height: 1),

          SwitchListTile(
            secondary: const Icon(Icons.signal_wifi_statusbar_connected_no_internet_4_rounded, color: AppTheme.tgBlue),
            title: const Text('Roaming'),
            subtitle: const Text('Download media while roaming', style: TextStyle(fontSize: 12)),
            value: _roaming,
            activeColor: AppTheme.tgBlue,
            onChanged: (v) => setState(() => _roaming = v),
          ),
        ],
      ),
    );
  }
}
