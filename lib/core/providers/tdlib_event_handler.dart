import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;
import '../tdlib/tdlib_core.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_list_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/file_provider.dart';
import '../providers/user_provider.dart';
import '../providers/call_provider.dart';
import '../../ui/services/ptt_service.dart';

// ─── Global TDLib core instance ───────────────────────────────────────────
final tdlibCoreProvider = Provider<TdlibCore>((ref) {
  final core = TdlibCore();
  ref.onDispose(() => core.dispose());
  return core;
});

// ─── TDLib event handler ─────────────────────────────────────────────────
final tdlibEventHandlerProvider = Provider<TdlibEventHandler>((ref) {
  return TdlibEventHandler(ref);
});

class TdlibEventHandler {
  final Ref _ref;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  // Typing clear timers: chatId → timer
  final Map<int, Timer> _typingTimers = {};

  TdlibEventHandler(this._ref);

  void start() {
    final core = _ref.read(tdlibCoreProvider);
    _subscription = core.eventStream.listen(_handleEvent, onError: (e) {
      debugPrint('TdlibEventHandler error: $e');
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    for (final t in _typingTimers.values) { t.cancel(); }
    _typingTimers.clear();
  }

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['@type'] as String?;
    if (type == null) return;

    // debugPrint('TDLib ← $type');

    switch (type) {
      // ── Authorization & Options ──────────────────────────────────────────────
      case td.UpdateAuthorizationState.CONSTRUCTOR:
        _ref.read(authNotifierProvider.notifier).handleUpdate(event);
        break;

      case td.UpdateOption.CONSTRUCTOR:
        final name = event['name'] as String?;
        final valueMap = event['value'] as Map<String, dynamic>?;
        if (name == 'my_id' && valueMap != null) {
          final myIdStr = valueMap['value']?.toString();
          if (myIdStr != null) {
            final myId = int.tryParse(myIdStr);
            if (myId != null && myId != 0) {
              _ref.read(userNotifierProvider.notifier).setMyUserId(myId);
            }
          }
        }
        break;

      // ── Chats ──────────────────────────────────────────────────────
      case td.UpdateNewChat.CONSTRUCTOR:
        final chat = td.Chat.fromJson(event['chat'] as Map<String, dynamic>);
        _ref.read(chatListNotifierProvider.notifier).upsertChat(chat);
        // Avatar download with higher priority
        if (chat.photo?.small != null) {
          _ref.read(tdlibCoreProvider).downloadFile(chat.photo!.small.id, priority: 16);
        }
        // Initial muted state
        _updateMutedFromSettings(chat.id, chat.notificationSettings);
        break;

      case td.UpdateChatLastMessage.CONSTRUCTOR:
        final chatId = event['chat_id'] as int;
        final msg = event['last_message'];
        final positions = (event['positions'] as List?)
            ?.map((e) => td.ChatPosition.fromJson(e as Map<String, dynamic>))
            .toList();
        _ref.read(chatListNotifierProvider.notifier)
            .updateLastMessage(chatId, msg != null ? td.Message.fromJson(msg as Map<String, dynamic>) : null, positions);
        break;

      case td.UpdateChatPosition.CONSTRUCTOR:
        final chatId = event['chat_id'] as int;
        final pos = td.ChatPosition.fromJson(event['position'] as Map<String, dynamic>);
        _ref.read(chatListNotifierProvider.notifier).updatePosition(chatId, pos);
        break;

      case td.UpdateChatReadInbox.CONSTRUCTOR:
        final chatId = event['chat_id'] as int;
        final unreadCount = event['unread_count'] as int;
        _ref.read(chatListNotifierProvider.notifier).updateUnreadCount(chatId, unreadCount);
        break;

      case td.UpdateChatReadOutbox.CONSTRUCTOR:
        // Track last read outbox for double-tick (read receipt)
        final chatId = event['chat_id'] as int;
        final lastReadOutboxMessageId = event['last_read_outbox_message_id'] as int;
        _ref.read(chatListNotifierProvider.notifier)
            .updateLastReadOutbox(chatId, lastReadOutboxMessageId);
        break;

      case td.UpdateChatPhoto.CONSTRUCTOR:
        final chatId = event['chat_id'] as int;
        final photo = event['photo'];
        _ref.read(chatListNotifierProvider.notifier).updateChatPhoto(
            chatId, photo != null ? td.ChatPhotoInfo.fromJson(photo as Map<String, dynamic>) : null);
        break;

      case td.UpdateChatTitle.CONSTRUCTOR:
        final chatId = event['chat_id'] as int;
        final title = event['title'] as String;
        _ref.read(chatListNotifierProvider.notifier).updateChatTitle(chatId, title);
        break;

      case td.UpdateChatNotificationSettings.CONSTRUCTOR:
        final chatId = event['chat_id'] as int;
        final settings = event['notification_settings'] as Map<String, dynamic>?;
        if (settings != null) {
          final muteFor = settings['mute_for'] as int? ?? 0;
          _ref.read(chatListNotifierProvider.notifier)
              .updateMuted(chatId, muteFor > 0);
        }
        break;

      case td.UpdateChatIsMarkedAsUnread.CONSTRUCTOR:
        break;

      case td.UpdateChatDraftMessage.CONSTRUCTOR:
        final chatId = event['chat_id'] as int;
        final draftMessage = event['draft_message'];
        _ref.read(chatListNotifierProvider.notifier).updateDraftMessage(
          chatId,
          draftMessage != null ? td.DraftMessage.fromJson(draftMessage as Map<String, dynamic>) : null,
        );
        break;

      case 'updateChatPinnedMessage':
        break;

      // ── Typing indicators ──────────────────────────────────────────
      case 'updateUserChatAction':
      case td.UpdateChatAction.CONSTRUCTOR:
        _handleTypingAction(event);
        break;

      // ── Messages ───────────────────────────────────────────────────
      case td.UpdateNewMessage.CONSTRUCTOR:
        final m = td.Message.fromJson(event['message'] as Map<String, dynamic>);

        bool isPttChunk = false;
        if (m.content is td.MessageVoiceNote) {
          final vn = m.content as td.MessageVoiceNote;
          if (vn.caption.text.startsWith('#PTT_CHUNK_')) {
            isPttChunk = true;
            _ref.read(pttNotifierProvider.notifier).enqueueChunk(m);
            if (!m.isOutgoing) {
              _ref.read(tdlibCoreProvider).send(td.ViewMessages(
                chatId: m.chatId,
                messageIds: [m.id],
                forceRead: true,
              ));
            }
          }
        }

        _ref.read(messagesNotifierProvider(m.chatId).notifier).addNewMessage(m);

        if (!isPttChunk) {
          _ref.read(chatListNotifierProvider.notifier).bumpChat(m.chatId);
        }
        break;

      case td.UpdateMessageContent.CONSTRUCTOR:
        final chatId = event['chat_id'] as int;
        final messageId = event['message_id'] as int;
        final newContent = event['new_content'] as Map<String, dynamic>;
        _ref.read(messagesNotifierProvider(chatId).notifier)
            .updateContent(messageId, td.MessageContent.fromJson(newContent));
        break;

      case td.UpdateDeleteMessages.CONSTRUCTOR:
        final chatId = event['chat_id'] as int;
        final ids = (event['message_ids'] as List).cast<int>();
        final fromCache = event['from_cache'] as bool? ?? false;
        if (!fromCache) {
          _ref.read(messagesNotifierProvider(chatId).notifier).deleteMessages(ids);
        }
        break;

      case td.UpdateMessageSendSucceeded.CONSTRUCTOR:
        final m = td.Message.fromJson(event['message'] as Map<String, dynamic>);
        final oldId = event['old_message_id'] as int;
        _ref.read(messagesNotifierProvider(m.chatId).notifier).onSendSucceeded(m, oldId);
        break;

      case td.UpdateMessageSendFailed.CONSTRUCTOR:
        break;

      case td.UpdateMessageEdited.CONSTRUCTOR:
        break;

      // ── Messages bulk (GetChatHistory response) ────────────────────
      case td.Messages.CONSTRUCTOR:
        final msgs = td.Messages.fromJson(event);
        if (msgs.messages.isNotEmpty) {
          final chatId = msgs.messages.first.chatId;
          _ref.read(messagesNotifierProvider(chatId).notifier)
              .addHistoryMessages(msgs.messages);
        }
        break;

      // ── Files ──────────────────────────────────────────────────────
      case td.UpdateFile.CONSTRUCTOR:
        final file = td.File.fromJson(event['file'] as Map<String, dynamic>);
        _ref.read(fileNotifierProvider.notifier).updateFile(file);
        break;

      // ── Users ──────────────────────────────────────────────────────
      case td.UpdateUser.CONSTRUCTOR:
        final user = td.User.fromJson(event['user'] as Map<String, dynamic>);
        _ref.read(userNotifierProvider.notifier).upsertUser(user);
        break;

      case td.User.CONSTRUCTOR:
        final user = td.User.fromJson(event);
        _ref.read(userNotifierProvider.notifier).upsertUser(user);
        break;

      case td.UpdateUserStatus.CONSTRUCTOR:
        final userId = event['user_id'] as int;
        final status = td.UserStatus.fromJson(event['status'] as Map<String, dynamic>);
        _ref.read(userNotifierProvider.notifier).updateStatus(userId, status);
        break;

      case td.UpdateCall.CONSTRUCTOR:
        final update = td.UpdateCall.fromJson(event);
        _ref.read(callNotifierProvider.notifier).handleUpdateCall(update.call);
        break;

      // ── Groups / Supergroups ────────────────────────────────────────
      case td.UpdateBasicGroup.CONSTRUCTOR:
        break;

      case td.UpdateSupergroup.CONSTRUCTOR:
        break;

      // ── OK / Error ─────────────────────────────────────────────────
      case td.Ok.CONSTRUCTOR:
        break;

      case td.TdError.CONSTRUCTOR:
        debugPrint('TDLib Error: ${event['code']} — ${event['message']}');
        if (event['message'] != null) {
          _ref.read(authNotifierProvider.notifier).handleError(event);
        }
        break;

      default:
        debugPrint('Unhandled TDLib event: $type');
    }
  }

  // ── Typing indicator handler ────────────────────────────────────────────
  void _handleTypingAction(Map<String, dynamic> event) {
    final chatId = event['chat_id'] as int?;
    if (chatId == null) return;

    final actionMap = event['action'] as Map<String, dynamic>?;
    if (actionMap == null) return;

    final actionType = actionMap['@type'] as String?;
    if (actionType == null) return;

    // Get sender name
    final senderMap = event['sender_id'] as Map<String, dynamic>?;
    String senderName = 'typing...';
    if (senderMap != null && senderMap['@type'] == 'messageSenderUser') {
      final userId = senderMap['user_id'] as int?;
      if (userId != null) {
        final user = _ref.read(userNotifierProvider).users[userId];
        if (user != null) senderName = user.firstName;
      }
    }

    if (actionType == 'chatActionCancel') {
      _clearTyping(chatId);
    } else {
      // Show typing
      _ref.read(chatListNotifierProvider.notifier).setTyping(chatId, senderName);
      // Auto-clear after 6 seconds
      _typingTimers[chatId]?.cancel();
      _typingTimers[chatId] = Timer(const Duration(seconds: 6), () {
        _clearTyping(chatId);
      });
    }
  }

  void _clearTyping(int chatId) {
    _ref.read(chatListNotifierProvider.notifier).clearTyping(chatId);
    _typingTimers[chatId]?.cancel();
    _typingTimers.remove(chatId);
  }

  void _updateMutedFromSettings(int chatId, td.ChatNotificationSettings settings) {
    final isMuted = settings.muteFor > 0;
    _ref.read(chatListNotifierProvider.notifier).updateMuted(chatId, isMuted);
  }
}
