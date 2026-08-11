import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

class CallLogScreen extends ConsumerWidget {
  const CallLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls'),
        backgroundColor: AppTheme.tgBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          final isMissed = index % 2 == 0;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.tgBlue,
              child: Text('U${index + 1}', style: const TextStyle(color: Colors.white)),
            ),
            title: Text(
              'User ${index + 1}',
              style: TextStyle(color: isMissed ? AppTheme.tgRed : Colors.black),
            ),
            subtitle: Row(
              children: [
                Icon(
                  isMissed ? Icons.call_missed : Icons.call_made,
                  size: 14,
                  color: isMissed ? AppTheme.tgRed : Colors.green,
                ),
                const SizedBox(width: 4),
                const Text('Yesterday, 10:00 PM'),
              ],
            ),
            trailing: const Icon(Icons.info_outline, color: AppTheme.tgBlue),
            onTap: () {},
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.tgBlue,
        onPressed: () {},
        child: const Icon(Icons.add_call, color: Colors.white),
      ),
    );
  }
}
