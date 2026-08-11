import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/tdlib_event_handler.dart';
import '../../../core/theme/app_theme.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  String _lastSeen = 'Everybody';
  String _profilePhoto = 'Everybody';
  String _calls = 'Everybody';
  bool _twoStep = false;

  void _showPrivacyDialog(String title, List<String> options, String current, Function(String) onSelect) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((o) => RadioListTile<String>(
            title: Text(o),
            value: o,
            groupValue: current,
            activeColor: AppTheme.tgBlue,
            onChanged: (v) {
              Navigator.pop(ctx);
              onSelect(v!);
            },
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy and Security'),
        backgroundColor: AppTheme.tgBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Privacy section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Privacy', style: TextStyle(color: AppTheme.tgBlue, fontWeight: FontWeight.bold, fontSize: 13)),
          ),

          ListTile(
            leading: const Icon(Icons.block_rounded, color: AppTheme.tgBlue),
            title: const Text('Blocked Users'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No blocked users')));
            },
          ),
          const Divider(indent: 56, height: 1),

          ListTile(
            leading: const Icon(Icons.access_time_rounded, color: AppTheme.tgBlue),
            title: const Text('Last Seen & Online'),
            trailing: Text(_lastSeen, style: const TextStyle(color: Colors.grey)),
            onTap: () => _showPrivacyDialog('Last Seen & Online', ['Everybody', 'My Contacts', 'Nobody'], _lastSeen,
                (v) => setState(() => _lastSeen = v)),
          ),
          const Divider(indent: 56, height: 1),

          ListTile(
            leading: const Icon(Icons.photo_rounded, color: AppTheme.tgBlue),
            title: const Text('Profile Photo'),
            trailing: Text(_profilePhoto, style: const TextStyle(color: Colors.grey)),
            onTap: () => _showPrivacyDialog('Profile Photo', ['Everybody', 'My Contacts', 'Nobody'], _profilePhoto,
                (v) => setState(() => _profilePhoto = v)),
          ),
          const Divider(indent: 56, height: 1),

          ListTile(
            leading: const Icon(Icons.call_rounded, color: AppTheme.tgBlue),
            title: const Text('Calls'),
            trailing: Text(_calls, style: const TextStyle(color: Colors.grey)),
            onTap: () => _showPrivacyDialog('Calls', ['Everybody', 'My Contacts', 'Nobody'], _calls,
                (v) => setState(() => _calls = v)),
          ),

          // Security section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Security', style: TextStyle(color: AppTheme.tgBlue, fontWeight: FontWeight.bold, fontSize: 13)),
          ),

          SwitchListTile(
            secondary: const Icon(Icons.lock_rounded, color: AppTheme.tgBlue),
            title: const Text('Two-Step Verification'),
            subtitle: Text(_twoStep ? 'Enabled' : 'Disabled', style: const TextStyle(fontSize: 12)),
            value: _twoStep,
            activeColor: AppTheme.tgBlue,
            onChanged: (v) {
              setState(() => _twoStep = v);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Two-Step Verification ${v ? "Enabled" : "Disabled"}')),
              );
            },
          ),

          const Divider(indent: 56, height: 1),

          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.tgRed),
            title: const Text('Active Sessions', style: TextStyle(color: AppTheme.tgRed)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.tgRed),
            onTap: () => ref.read(tdlibCoreProvider).sendRaw({'@type': 'getActiveSessions'}),
          ),
        ],
      ),
    );
  }
}
