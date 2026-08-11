import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;
import '../../../core/providers/file_provider.dart';
import '../../../core/providers/tdlib_event_handler.dart';
import '../../../core/providers/chat_list_provider.dart';
import '../../../core/providers/messages_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'physics/swipe_to_reply_wrapper.dart';

class MessageBubble extends ConsumerWidget {
  final td.Message message;
  final bool isOutgoing;
  final bool showAvatar;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
    required this.showAvatar,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = message.content;

    // PTT মেসেজ হিডেন রাখো (normal chat এ দেখাবে না)
    if (content is td.MessageVoiceNote) {
      final caption = content.caption.text;
      if (caption.startsWith('#PTT_')) {
        return const SizedBox.shrink(); // PTT chunk hidden
      }
    }

    return SwipeToReplyWrapper(
      onReply: () {
        // Handle Reply Draft using TDLib SetChatDraftMessage
        ref.read(tdlibCoreProvider).send(td.SetChatDraftMessage(
          chatId: message.chatId,
          messageThreadId: 0,
          draftMessage: td.DraftMessage(
            replyToMessageId: message.id,
            inputMessageText: const td.InputMessageText(
              text: td.FormattedText(text: '', entities: []),
              disableWebPagePreview: false,
              clearDraft: false,
            ),
            date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
        ));
      },
      child: Padding(
        padding: EdgeInsets.only(
        top: isFirstInGroup ? 6 : 2,
        bottom: 2,
        left: isOutgoing ? 60 : 8,
        right: isOutgoing ? 8 : 60,
      ),
      child: Row(
        mainAxisAlignment:
            isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Sender avatar (incoming only, last message in group)
          if (!isOutgoing)
            _buildSenderAvatar(ref),

          const SizedBox(width: 4),

          // Bubble
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageMenu(context, ref),
              child: Column(
                crossAxisAlignment: isOutgoing
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isOutgoing
                          ? AppTheme.tgOutgoingBubble
                          : AppTheme.tgIncomingBubble,
                      borderRadius: _getBubbleRadius(),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.replyTo is td.MessageReplyToMessage)
                            _buildReplyPreview(context, ref, (message.replyTo as td.MessageReplyToMessage).messageId),
                          // Content
                          _buildContent(context, ref, content),
                          // Time + status row
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                _formatTime(message.date),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.tgGrey,
                                ),
                              ),
                              if (isOutgoing) ...[
                                const SizedBox(width: 4),
                                _buildStatusIcon(ref),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 4),
          if (isOutgoing) const SizedBox(width: 40),
        ],
      ),
    ));
  }

  Widget _buildSenderAvatar(WidgetRef ref) {
    if (!showAvatar) return const SizedBox(width: 36);
    // Get sender info
    return const SizedBox(
      width: 36,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppTheme.tgBlue,
        child: Icon(Icons.person, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, td.MessageContent content) {
    if (content is td.MessageText) {
      return Text(
        content.text.text,
        style: const TextStyle(fontSize: 15),
      );
    }

    if (content is td.MessagePhoto) {
      return _PhotoContent(photo: content, ref: ref);
    }

    if (content is td.MessageVoiceNote) {
      return _VoiceNoteContent(voiceNote: content, ref: ref);
    }

    if (content is td.MessageVideo) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_rounded, color: AppTheme.tgGrey),
          SizedBox(width: 8),
          Text('Video', style: TextStyle(color: AppTheme.tgGrey)),
        ],
      );
    }

    if (content is td.MessageDocument) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file_rounded, color: AppTheme.tgBlue),
          const SizedBox(width: 8),
          Flexible(child: Text(content.document.fileName, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      );
    }

    if (content is td.MessageAudio) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.music_note_rounded, color: AppTheme.tgBlue),
          const SizedBox(width: 8),
          Text(content.audio.title.isNotEmpty ? content.audio.title : 'Audio'),
        ],
      );
    }

    if (content is td.MessageSticker) {
      return Text(content.sticker.emoji, style: const TextStyle(fontSize: 48));
    }

    if (content is td.MessageCall) {
      final incoming = !message.isOutgoing;
      final missed = content.discardReason is td.CallDiscardReasonMissed;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            incoming ? Icons.call_received_rounded : Icons.call_made_rounded,
            color: missed ? AppTheme.tgRed : AppTheme.tgGreen,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(incoming ? (missed ? 'Missed call' : 'Incoming call') : 'Outgoing call'),
        ],
      );
    }

    if (content is td.MessageLocation) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, color: AppTheme.tgRed),
          SizedBox(width: 8),
          Text('Location'),
        ],
      );
    }

    if (content is td.MessageContact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_rounded, color: AppTheme.tgBlue),
          const SizedBox(width: 8),
          Text('${content.contact.firstName} ${content.contact.lastName}'),
        ],
      );
    }

    // Service messages
    if (content is td.MessagePinMessage) {
      return const _ServiceMessageText('📌 Pinned a message');
    }
    if (content is td.MessageChatAddMembers) {
      return const _ServiceMessageText('👤 Added members');
    }
    if (content is td.MessageChatDeleteMember) {
      return const _ServiceMessageText('👤 Left the group');
    }
    if (content is td.MessageChatChangeTitle) {
      return _ServiceMessageText('✏️ Changed title to "${content.title}"');
    }

    return Text(
      content.getConstructor(),
      style: const TextStyle(color: AppTheme.tgGrey, fontStyle: FontStyle.italic),
    );
  }

  Widget _buildStatusIcon(WidgetRef ref) {
    IconData iconData;
    Color iconColor = AppTheme.tgGrey;
    
    if (message.sendingState != null) {
      iconData = Icons.access_time_rounded;
    } else {
      final chat = ref.read(chatListNotifierProvider).chats[message.chatId];
      final lastRead = chat?.lastReadOutboxMessageId ?? 0;
      
      if (message.id <= lastRead) {
        iconData = Icons.done_all_rounded;
        iconColor = AppTheme.tgBlue;
      } else {
        iconData = Icons.check_rounded;
      }
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: Icon(
        iconData,
        key: ValueKey(iconData),
        size: 14,
        color: iconColor,
      ),
    );
  }

  BorderRadius _getBubbleRadius() {
    const double defaultRadius = 18.0;
    const double smallRadius = 4.0;
    const double tailRadius = 0.0;

    if (isOutgoing) {
      return BorderRadius.only(
        topLeft: const Radius.circular(defaultRadius),
        bottomLeft: const Radius.circular(defaultRadius),
        topRight: Radius.circular(isFirstInGroup ? defaultRadius : smallRadius),
        bottomRight: Radius.circular(isLastInGroup ? tailRadius : smallRadius),
      );
    } else {
      return BorderRadius.only(
        topRight: const Radius.circular(defaultRadius),
        bottomRight: const Radius.circular(defaultRadius),
        topLeft: Radius.circular(isFirstInGroup ? defaultRadius : smallRadius),
        bottomLeft: Radius.circular(isLastInGroup ? tailRadius : smallRadius),
      );
    }
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat.jm().format(dt);
  }

  void _showMessageMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          ListTile(
            leading: const Icon(Icons.reply_rounded, color: AppTheme.tgBlue),
            title: const Text('Reply'),
            onTap: () => Navigator.pop(context),
          ),
          if (message.content is td.MessageText)
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.pop(context);
                final text = (message.content as td.MessageText).text.text;
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.forward_rounded),
            title: const Text('Forward'),
            onTap: () => Navigator.pop(context),
          ),
          if (message.isOutgoing)
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppTheme.tgRed),
              title: const Text('Delete', style: TextStyle(color: AppTheme.tgRed)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Message'),
                    content: const Text('Delete this message for everyone?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(tdlibCoreProvider).send(td.DeleteMessages(
                            chatId: message.chatId,
                            messageIds: [message.id],
                            revoke: true,
                          ));
                        },
                        child: const Text('Delete', style: TextStyle(color: AppTheme.tgRed)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }


  Widget _buildReplyPreview(BuildContext context, WidgetRef ref, int replyToMessageId) {
    // Find replied message
    // Note: since this is just UI, if we don't have it loaded, we just show "Message".
    // A full implementation would fetch it if missing.
    final messages = ref.read(messagesNotifierProvider(message.chatId)).messages;
    final idx = messages.indexWhere((m) => m.id == replyToMessageId);
    
    String snippet = 'Message';
    if (idx != -1) {
      final content = messages[idx].content;
      if (content is td.MessageText) snippet = content.text.text;
      else if (content is td.MessagePhoto) snippet = 'Photo';
      else if (content is td.MessageVideo) snippet = 'Video';
      else if (content is td.MessageVoiceNote) snippet = 'Voice message';
      else if (content is td.MessageDocument) snippet = 'Document';
      else if (content is td.MessageSticker) snippet = 'Sticker';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.only(left: 8),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppTheme.tgBlue, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reply',
            style: TextStyle(color: AppTheme.tgBlue, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            snippet,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.tgGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Photo content ─────────────────────────────────────────────────────────
class _PhotoContent extends ConsumerWidget {
  final td.MessagePhoto photo;
  final WidgetRef ref;

  const _PhotoContent({required this.photo, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Best quality photo
    final sizes = photo.photo.sizes;
    if (sizes.isEmpty) return const Icon(Icons.image, size: 100);

    final best = sizes.last;
    final localPath = ref.watch(fileByIdProvider(best.photo.id))?.local.path;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: localPath != null && localPath.isNotEmpty
          ? Image.file(File(localPath), width: 200, height: 200, fit: BoxFit.cover)
          : Container(
              width: 200,
              height: 200,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
    );
  }
}

// ─── Voice note content ────────────────────────────────────────────────────
class _VoiceNoteContent extends StatelessWidget {
  final td.MessageVoiceNote voiceNote;
  final WidgetRef ref;

  const _VoiceNoteContent({required this.voiceNote, required this.ref});

  @override
  Widget build(BuildContext context) {
    final duration = voiceNote.voiceNote.duration;
    final mm = duration ~/ 60;
    final ss = (duration % 60).toString().padLeft(2, '0');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mic_rounded, color: AppTheme.tgBlue, size: 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 2,
              color: AppTheme.tgBlue.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 4),
            Text('$mm:$ss', style: const TextStyle(fontSize: 12, color: AppTheme.tgGrey)),
          ],
        ),
      ],
    );
  }
}

// ─── Service message ───────────────────────────────────────────────────────
class _ServiceMessageText extends StatelessWidget {
  final String text;
  const _ServiceMessageText(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.tgGrey)),
      ),
    );
  }
}
