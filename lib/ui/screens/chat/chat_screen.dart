import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;
import '../../../core/providers/messages_provider.dart';
import '../../../core/providers/chat_list_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/tdlib_event_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/chat_avatar.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/shimmer_loading.dart';
import '../profile/chat_profile_screen.dart';
import '../../widgets/message_input.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int chatId;
  final String chatTitle;

  const ChatScreen({super.key, required this.chatId, required this.chatTitle});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  bool _showScrollDown = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Instant load — local first, then remote
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messagesNotifierProvider(widget.chatId).notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load older messages when scrolled near top (reversed list)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(messagesNotifierProvider(widget.chatId).notifier).loadHistory();
    }

    final showBtn = _scrollController.position.pixels > 400;
    if (showBtn != _showScrollDown) {
      setState(() => _showScrollDown = showBtn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatListNotifierProvider).chats[widget.chatId];
    final chatState = ref.watch(chatListNotifierProvider);
    final isTyping = chatState.isTyping(widget.chatId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: _buildAppBar(chat, isTyping),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFC0DAE8),
          image: DecorationImage(
            image: AssetImage('assets/images/chat_bg.png'),
            repeat: ImageRepeat.repeat,
            opacity: 0.15,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(child: _buildMessageList()),
                MessageInput(chatId: widget.chatId),
              ],
            ),
            if (_showScrollDown)
              Positioned(
                bottom: 80,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: _scrollToBottom,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.tgBlue),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(td.Chat? chat, bool isTyping) {
    int? userId;
    if (chat?.type is td.ChatTypePrivate) {
      userId = (chat!.type as td.ChatTypePrivate).userId;
    }

    String statusText = '';
    if (userId != null) {
      final isOnline = ref.watch(userNotifierProvider).isOnline(userId);
      statusText = isOnline ? 'online' : 'last seen recently';
    }

    return AppBar(
      backgroundColor: AppTheme.tgBlue.withValues(alpha: 0.75),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () => _openProfile(chat),
        child: Row(
          children: [
            ChatAvatar(
              file: chat?.photo?.small,
              name: chat?.title ?? widget.chatTitle,
              radius: 18,
              heroTag: 'chat_avatar_${widget.chatId}',
              showOnlineBadge: userId != null &&
                  ref.watch(userNotifierProvider).isOnline(userId),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    chat?.title ?? widget.chatTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Status / typing
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isTyping
                        ? const Text(
                            'typing...',
                            key: ValueKey('typing'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : (statusText.isNotEmpty
                            ? Text(
                                statusText,
                                key: const ValueKey('status'),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('empty'))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_rounded, color: Colors.white),
          onPressed: () => _startCall(userId, isVideo: false),
        ),
        IconButton(
          icon: const Icon(Icons.videocam_rounded, color: Colors.white),
          onPressed: () => _startCall(userId, isVideo: true),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: _showChatMenu,
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return Consumer(
      builder: (context, ref, _) {
        final msgState = ref.watch(messagesNotifierProvider(widget.chatId));
        final messages = msgState.messages;

        // Show shimmer while initial loading (no messages yet)
        if (msgState.isInitialLoading && messages.isEmpty) {
          return const MessageListShimmer();
        }

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline, size: 36, color: AppTheme.tgGrey),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No messages yet',
                  style: TextStyle(color: AppTheme.tgGrey, fontSize: 15),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            bottom: 8,
          ),
          itemCount: messages.length + (msgState.isLoadingHistory ? 1 : 0),
          itemBuilder: (_, i) {
            // Loading indicator at top (oldest end) — shimmer style
            if (i == messages.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerLoading(
                      isLoading: true,
                      child: Container(
                        width: 120,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final message = messages[i];
            final prevMsg = i < messages.length - 1 ? messages[i + 1] : null;
            final nextMsg = i > 0 ? messages[i - 1] : null;

            final bool isFirstInGroup = prevMsg == null ||
                prevMsg.senderId != message.senderId ||
                (message.date - prevMsg.date > 300);

            final bool isLastInGroup = nextMsg == null ||
                nextMsg.senderId != message.senderId ||
                (nextMsg.date - message.date > 300);

            return MessageBubble(
              message: message,
              isOutgoing: message.isOutgoing,
              showAvatar: !message.isOutgoing && isLastInGroup,
              isFirstInGroup: isFirstInGroup,
              isLastInGroup: isLastInGroup,
            );
          },
        );
      },
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _openProfile(td.Chat? chat) {
    if (chat == null) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ChatProfileScreen(chat: chat)));
  }

  void _startCall(int? userId, {required bool isVideo}) {
    if (userId == null) return;
    ref.read(tdlibCoreProvider).send(td.CreateCall(
      userId: userId,
      protocol: const td.CallProtocol(
        udpP2p: true,
        udpReflector: true,
        minLayer: 65,
        maxLayer: 92,
        libraryVersions: ['4.0.0', '5.0.0'],
      ),
      isVideo: isVideo,
    ));
  }

  void _showChatMenu() {
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
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search in Chat'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search: Use the search icon in home screen')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                final chat = ref.read(chatListNotifierProvider).chats[widget.chatId];
                _openProfile(chat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off_rounded),
              title: const Text('Mute Notifications'),
              onTap: () {
                Navigator.pop(context);
                ref.read(tdlibCoreProvider).sendRaw({
                  '@type': 'setChatNotificationSettings',
                  'chat_id': widget.chatId,
                  'notification_settings': {
                    '@type': 'chatNotificationSettings',
                    'use_default_mute_for': false,
                    'mute_for': 2147483647,
                    'use_default_sound': true,
                    'use_default_show_preview': true,
                  },
                });
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
