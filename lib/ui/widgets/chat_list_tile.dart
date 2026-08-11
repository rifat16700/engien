import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;
import '../../core/providers/user_provider.dart';
import '../../core/providers/chat_list_provider.dart';
import '../../core/providers/tdlib_event_handler.dart';
import '../../core/theme/app_theme.dart';
import 'chat_avatar.dart';
import 'package:intl/intl.dart';

// ─── Chat type helpers ────────────────────────────────────────────────────
enum ChatType { personal, group, supergroup, channel, bot, service }

ChatType getChatType(td.Chat chat) {
  final t = chat.type;
  if (t is td.ChatTypePrivate) return ChatType.personal;
  if (t is td.ChatTypeBasicGroup) return ChatType.group;
  if (t is td.ChatTypeSupergroup) {
    return t.isChannel ? ChatType.channel : ChatType.supergroup;
  }
  if (t is td.ChatTypeSecret) return ChatType.personal;
  return ChatType.personal;
}

// ─── Typing Indicator Dots Animation ─────────────────────────────────────
class _TypingDotsWidget extends StatefulWidget {
  const _TypingDotsWidget();

  @override
  State<_TypingDotsWidget> createState() => _TypingDotsWidgetState();
}

class _TypingDotsWidgetState extends State<_TypingDotsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _dotCount = (_dotCount % 3) + 1);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'typing${'.' * _dotCount}',
      style: const TextStyle(fontSize: 13, color: AppTheme.tgBlue, fontStyle: FontStyle.italic),
    );
  }
}

// ─── Chat List Tile ───────────────────────────────────────────────────────
class ChatListTile extends ConsumerWidget {
  final td.Chat chat;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ChatListTile({
    super.key,
    required this.chat,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatListNotifierProvider);
    final chatType = getChatType(chat);
    final lastMsg = chat.lastMessage;
    final unreadCount = chat.unreadCount;
    final isTyping = chatState.isTyping(chat.id);
    final isMuted = chatState.isMuted(chat.id);
    final lastReadOutbox = chatState.getLastReadOutbox(chat.id);

    // Bot check
    bool isBot = false;
    int? userId;
    if (chat.type is td.ChatTypePrivate) {
      userId = (chat.type as td.ChatTypePrivate).userId;
      final user = ref.watch(userByIdProvider(userId));
      isBot = user?.type is td.UserTypeBot;
    }

    // Online status for personal chats
    bool isOnline = false;
    if (userId != null) {
      isOnline = ref.watch(userNotifierProvider).isOnline(userId);
    }

    // Swipe to archive (left) and pin (right)
    return Dismissible(
      key: ValueKey('dismiss_${chat.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Archive
          _archiveChat(ref);
        } else {
          // Pin/Unpin
          _pinChat(ref);
        }
        return false; // don't actually dismiss
      },
      background: Container(
        color: Colors.blue[400],
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              chat.positions.any((p) => p.isPinned) ? Icons.push_pin_outlined : Icons.push_pin,
              color: Colors.white,
            ),
            Text(
              chat.positions.any((p) => p.isPinned) ? 'Unpin' : 'Pin',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Colors.grey[500],
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive_outlined, color: Colors.white),
            Text('Archive', style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Avatar with online badge
              ChatAvatar(
                file: chat.photo?.small,
                name: chat.title,
                radius: 27,
                heroTag: 'chat_avatar_${chat.id}',
                showOnlineBadge: isOnline && chatType == ChatType.personal,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title row ───────────────────────────────────────
                    Row(
                      children: [
                        // Pin icon
                        if (chat.positions.any((p) => p.isPinned))
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.push_pin, size: 12, color: AppTheme.tgGrey),
                          ),
                        // Chat type icon
                        if (chatType == ChatType.channel)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.campaign_rounded, size: 14, color: AppTheme.tgGrey),
                          ),
                        if (chatType == ChatType.group || chatType == ChatType.supergroup)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.group_rounded, size: 14, color: AppTheme.tgGrey),
                          ),
                        if (isBot)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.smart_toy_rounded, size: 14, color: AppTheme.tgBlue),
                          ),
                        // Chat name
                        Expanded(
                          child: Text(
                            chat.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Time
                        if (lastMsg != null)
                          Text(
                            _formatTime(lastMsg.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: unreadCount > 0 && !isMuted
                                  ? AppTheme.tgBlue
                                  : AppTheme.tgGrey,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // ── Last message / Typing row ────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: isTyping
                              ? const _TypingDotsWidget()
                              : _buildLastMessage(lastMsg, chatType, lastReadOutbox, ref),
                        ),
                        // Unread badge
                        if (unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isMuted ? AppTheme.tgGrey : AppTheme.tgBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount > 999 ? '999+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        // Muted icon (when no unread)
                        if (unreadCount == 0 && isMuted)
                          const Icon(Icons.volume_off, size: 14, color: AppTheme.tgGrey),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastMessage(td.Message? msg, ChatType chatType,
      int lastReadOutbox, WidgetRef ref) {
    if (msg == null) {
      return const Text('', style: TextStyle(fontSize: 14, color: AppTheme.tgGrey));
    }

    String preview = '';
    final content = msg.content;

    if (content is td.MessageText) {
      preview = content.text.text;
    } else if (content is td.MessagePhoto) {
      preview = '📷 Photo';
    } else if (content is td.MessageVideo) {
      preview = '🎥 Video';
    } else if (content is td.MessageVoiceNote) {
      final caption = content.caption.text;
      if (caption.startsWith('#PTT_')) {
        preview = '🎙 Voice Chat';
      } else {
        preview = '🎤 Voice message';
      }
    } else if (content is td.MessageAudio) {
      preview = '🎵 ${content.audio.title.isNotEmpty ? content.audio.title : 'Audio'}';
    } else if (content is td.MessageDocument) {
      preview = '📄 ${content.document.fileName}';
    } else if (content is td.MessageSticker) {
      preview = '${content.sticker.emoji} Sticker';
    } else if (content is td.MessageVideoNote) {
      preview = '🎥 Video message';
    } else if (content is td.MessageLocation) {
      preview = '📍 Location';
    } else if (content is td.MessageContact) {
      preview = '👤 Contact';
    } else if (content is td.MessageCall) {
      final isIncoming = !msg.isOutgoing;
      final missed = content.isVideo ? '📹' : '📞';
      preview = '$missed ${isIncoming ? 'Incoming' : 'Outgoing'} call';
    } else if (content is td.MessagePinMessage) {
      preview = '📌 Pinned message';
    } else {
      preview = 'Message';
    }

    // Outgoing: "You: " prefix + read receipt icon
    Widget? leadingWidget;
    if (msg.isOutgoing) {
      // Read receipt
      Icon readIcon;
      if (msg.id <= lastReadOutbox && lastReadOutbox > 0) {
        readIcon = const Icon(Icons.done_all_rounded, size: 14, color: AppTheme.tgBlue);
      } else if (msg.sendingState != null) {
        readIcon = const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.tgGrey);
      } else {
        readIcon = const Icon(Icons.done_all_rounded, size: 14, color: AppTheme.tgGrey);
      }
      leadingWidget = readIcon;
    }

    return Row(
      children: [
        if (leadingWidget != null) ...[leadingWidget, const SizedBox(width: 3)],
        // "You:" prefix for group outgoing
        if (msg.isOutgoing && chatType != ChatType.personal)
          const Text('You: ', style: TextStyle(fontSize: 14, color: AppTheme.tgGrey, fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: AppTheme.tgGrey),
          ),
        ),
      ],
    );
  }

  void _archiveChat(WidgetRef ref) {
    ref.read(tdlibCoreProvider).sendRaw({
      '@type': 'addChatToList',
      'chat_id': chat.id,
      'chat_list': {'@type': 'chatListArchive'},
    });
  }

  void _pinChat(WidgetRef ref) {
    final isPinned = chat.positions.any((p) => p.isPinned);
    ref.read(tdlibCoreProvider).sendRaw({
      '@type': 'toggleChatIsPinned',
      'chat_list': {'@type': 'chatListMain'},
      'chat_id': chat.id,
      'is_pinned': !isPinned,
    });
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    final isMuted = ref.read(chatListNotifierProvider).isMuted(chat.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Chat name header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ChatAvatar(
                    file: chat.photo?.small,
                    name: chat.title,
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    chat.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.done_all_rounded),
              title: const Text('Mark as Read'),
              onTap: () {
                Navigator.pop(context);
                ref.read(tdlibCoreProvider).sendRaw({
                  '@type': 'readChatList',
                  'chat_list': {'@type': 'chatListMain'},
                });
              },
            ),
            ListTile(
              leading: Icon(isMuted ? Icons.volume_up : Icons.volume_off),
              title: Text(isMuted ? 'Unmute' : 'Mute'),
              onTap: () {
                Navigator.pop(context);
                ref.read(tdlibCoreProvider).sendRaw({
                  '@type': 'setChatNotificationSettings',
                  'chat_id': chat.id,
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
              leading: Icon(chat.positions.any((p) => p.isPinned)
                  ? Icons.push_pin_outlined
                  : Icons.push_pin),
              title: Text(
                  chat.positions.any((p) => p.isPinned) ? 'Unpin' : 'Pin'),
              onTap: () {
                Navigator.pop(context);
                _pinChat(ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive'),
              onTap: () {
                Navigator.pop(context);
                _archiveChat(ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);

    if (msgDay == today) {
      return DateFormat.jm().format(dt);
    } else if (today.difference(msgDay).inDays == 1) {
      return 'Yesterday';
    } else if (today.difference(msgDay).inDays < 7) {
      return DateFormat.E().format(dt);
    } else {
      return DateFormat('d MMM').format(dt);
    }
  }
}
