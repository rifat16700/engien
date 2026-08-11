import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;
import '../../../core/theme/app_theme.dart';
import '../../widgets/chat_avatar.dart';

class GroupProfileScreen extends ConsumerWidget {
  final td.Chat chat;
  const GroupProfileScreen({super.key, required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.tgBlue,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(chat.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              background: Container(
                color: AppTheme.tgBlue,
                child: Center(
                  child: Hero(
                    tag: 'avatar_${chat.id}',
                    child: ChatAvatar(
                      file: chat.photo?.big,
                      name: chat.title,
                      radius: 60,
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {}, // TODO: Edit group
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const ListTile(
                leading: Icon(Icons.info_outline_rounded, color: AppTheme.tgBlue),
                title: Text('No description'),
                subtitle: Text('Description'),
              ),
              const Divider(indent: 72, height: 1),
              ListTile(
                leading: const Icon(Icons.link_rounded, color: AppTheme.tgBlue),
                title: const Text('t.me/group_link'),
                subtitle: const Text('Invite Link'),
                onTap: () {},
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('Members', style: TextStyle(color: AppTheme.tgBlue, fontWeight: FontWeight.bold)),
                    Spacer(),
                    Icon(Icons.search, color: Colors.grey),
                  ],
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.tgBlue,
                  child: Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                ),
                title: const Text('Add Members', style: TextStyle(color: AppTheme.tgBlue)),
                onTap: () {},
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
