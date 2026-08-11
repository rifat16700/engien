import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/chat_avatar.dart';
import '../profile/my_profile_screen.dart';
import 'privacy_settings_screen.dart';
import 'sessions_screen.dart';
import 'data_storage_screen.dart';
import 'appearance_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(myUserProvider);
    final photo = me?.profilePhoto?.small;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.tgBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Profile header
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyProfileScreen())),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ChatAvatar(
                    file: photo,
                    name: me != null ? '${me.firstName} ${me.lastName}' : 'Me',
                    radius: 30,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          me != null ? '${me.firstName} ${me.lastName}'.trim() : 'Loading...',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (me?.phoneNumber != null)
                          Text('+${me!.phoneNumber}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Settings list
          ListTile(
            leading: const Icon(Icons.lock_rounded, color: AppTheme.tgBlue),
            title: const Text('Privacy and Security'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsScreen())),
          ),
          const Divider(indent: 72, height: 1),
          ListTile(
            leading: const Icon(Icons.devices_rounded, color: AppTheme.tgBlue),
            title: const Text('Devices'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionsScreen())),
          ),
          const Divider(indent: 72, height: 1),
          ListTile(
            leading: const Icon(Icons.data_usage_rounded, color: AppTheme.tgBlue),
            title: const Text('Data and Storage'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataStorageScreen())),
          ),
          const Divider(indent: 72, height: 1),
          ListTile(
            leading: const Icon(Icons.color_lens_rounded, color: AppTheme.tgBlue),
            title: const Text('Appearance'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppearanceScreen())),
          ),
        ],
      ),
    );
  }
}

