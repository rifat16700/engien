import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/tdlib_event_handler.dart';
import '../../../core/providers/chat_list_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../widgets/chat_avatar.dart';

class ChatProfileScreen extends ConsumerWidget {
  final td.Chat chat;
  const ChatProfileScreen({super.key, required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveChat = ref.watch(chatListNotifierProvider).chats[chat.id] ?? chat;
    final isMuted = liveChat.notificationSettings.muteFor > 0;

    int? userId;
    if (liveChat.type is td.ChatTypePrivate) {
      userId = (liveChat.type as td.ChatTypePrivate).userId;
    }
    final user = userId != null ? ref.watch(userByIdProvider(userId)) : null;
    final phone = user != null && user.phoneNumber.isNotEmpty ? '+${user.phoneNumber}' : '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.tgBlue,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(liveChat.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              background: _buildHeroAvatar(liveChat),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () => _showOptions(context, ref, liveChat, isMuted),
              ),
            ],
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              // Action buttons row
              _buildActionButtons(context, ref, liveChat, userId),
              const Divider(height: 1),

              // User info
              if (phone.isNotEmpty) ...[
                _buildInfoTile(Icons.phone_rounded, 'Phone', phone),
                const Divider(indent: 72, height: 1),
              ],
              _buildInfoTile(
                isMuted ? Icons.notifications_off_rounded : Icons.notifications_rounded,
                'Notifications',
                isMuted ? 'Muted' : 'Enabled',
              ),
              const Divider(height: 1),

              // Shared Media header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Shared Media', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    TextButton(onPressed: () {}, child: const Text('See All', style: TextStyle(color: AppTheme.tgBlue))),
                  ],
                ),
              ),
              _buildMediaGrid(),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAvatar(td.Chat c) {
    return Container(
      color: AppTheme.tgBlue,
      child: Center(
        child: Hero(
          tag: 'avatar_${c.id}',
          child: ChatAvatar(file: c.photo?.big, name: c.title, radius: 60),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, td.Chat c, int? userId) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.message_rounded,
            label: 'Message',
            onTap: () => Navigator.pop(context),
          ),
          if (userId != null) ...[
            _ActionButton(
              icon: Icons.call_rounded,
              label: 'Call',
              onTap: () {
                Navigator.pop(context);
                ref.read(tdlibCoreProvider).send(td.CreateCall(
                  userId: userId,
                  protocol: const td.CallProtocol(
                    udpP2p: true, udpReflector: true,
                    minLayer: 65, maxLayer: 92,
                    libraryVersions: ['4.0.0', '5.0.0'],
                  ),
                  isVideo: false,
                ));
              },
            ),
            _ActionButton(
              icon: Icons.videocam_rounded,
              label: 'Video',
              onTap: () {
                Navigator.pop(context);
                ref.read(tdlibCoreProvider).send(td.CreateCall(
                  userId: userId,
                  protocol: const td.CallProtocol(
                    udpP2p: true, udpReflector: true,
                    minLayer: 65, maxLayer: 92,
                    libraryVersions: ['4.0.0', '5.0.0'],
                  ),
                  isVideo: true,
                ));
              },
            ),
          ],
          _ActionButton(icon: Icons.search_rounded, label: 'Search', onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.tgBlue),
      title: Text(subtitle),
      subtitle: Text(title, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildMediaGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        children: List.generate(9, (_) => Container(color: Colors.grey[200])),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref, td.Chat c, bool isMuted) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isMuted ? Icons.notifications_rounded : Icons.notifications_off_rounded),
              title: Text(isMuted ? 'Enable Notifications' : 'Mute Notifications'),
              onTap: () {
                Navigator.pop(context);
                ref.read(tdlibCoreProvider).sendRaw({
                  '@type': 'setChatNotificationSettings',
                  'chat_id': c.id,
                  'notification_settings': {
                    '@type': 'chatNotificationSettings',
                    'use_default_mute_for': false,
                    'mute_for': isMuted ? 0 : 2147483647,
                    'use_default_sound': true,
                    'use_default_show_preview': true,
                  },
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: AppTheme.tgRed),
              title: const Text('Block User', style: TextStyle(color: AppTheme.tgRed)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppTheme.tgBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppTheme.tgBlue),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.tgBlue)),
        ],
      ),
    );
  }
}

