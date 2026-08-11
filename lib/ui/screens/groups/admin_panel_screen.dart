import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrators'),
        backgroundColor: AppTheme.tgBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Who can add members?', style: TextStyle(color: AppTheme.tgBlue, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('All Members'),
            trailing: Radio<int>(
              value: 0,
              groupValue: 0,
              onChanged: (v) {},
            ),
          ),
          ListTile(
            title: const Text('Only Admins'),
            trailing: Radio<int>(
              value: 1,
              groupValue: 0,
              onChanged: (v) {},
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add, color: AppTheme.tgBlue),
            title: const Text('Add Admin', style: TextStyle(color: AppTheme.tgBlue)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
