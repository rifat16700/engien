import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:tdlib/td_api.dart' as td;
import 'tdlib_event_handler.dart';

// ─── Chat List State ──────────────────────────────────────────────────────
class ChatListState {
  final Map<int, td.Chat> chats;          // chatId → Chat
  final List<int> orderedIds;             // sorted by order
  final bool isLoading;
  final bool hasMore;
  // Typing: chatId → sender name/text
  final Map<int, String> typingUsers;
  // Muted: chatId → true if muted
  final Map<int, bool> mutedChats;
  // Last read outbox: chatId → lastReadOutboxMessageId
  final Map<int, int> lastReadOutbox;

  const ChatListState({
    this.chats = const {},
    this.orderedIds = const [],
    this.isLoading = true,
    this.hasMore = true,
    this.typingUsers = const {},
    this.mutedChats = const {},
    this.lastReadOutbox = const {},
  });

  ChatListState copyWith({
    Map<int, td.Chat>? chats,
    List<int>? orderedIds,
    bool? isLoading,
    bool? hasMore,
    Map<int, String>? typingUsers,
    Map<int, bool>? mutedChats,
    Map<int, int>? lastReadOutbox,
  }) {
    return ChatListState(
      chats: chats ?? this.chats,
      orderedIds: orderedIds ?? this.orderedIds,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      typingUsers: typingUsers ?? this.typingUsers,
      mutedChats: mutedChats ?? this.mutedChats,
      lastReadOutbox: lastReadOutbox ?? this.lastReadOutbox,
    );
  }

  List<td.Chat> get mainChats =>
      orderedIds.map((id) => chats[id]).nonNulls.where((c) =>
          c.positions.any((p) => p.list is td.ChatListMain)).toList();

  bool isMuted(int chatId) => mutedChats[chatId] ?? false;
  bool isTyping(int chatId) => typingUsers.containsKey(chatId);
  String typingText(int chatId) => typingUsers[chatId] ?? 'typing...';
  int getLastReadOutbox(int chatId) => lastReadOutbox[chatId] ?? 0;
}

// ─── Chat List Notifier ───────────────────────────────────────────────────
class ChatListNotifier extends Notifier<ChatListState> {
  @override
  ChatListState build() => const ChatListState();

  void upsertChat(td.Chat chat) {
    final updated = Map<int, td.Chat>.from(state.chats);
    updated[chat.id] = chat;

    final ids = List<int>.from(state.orderedIds);
    if (!ids.contains(chat.id)) ids.add(chat.id);

    state = state.copyWith(
      chats: updated,
      orderedIds: _sortedIds(updated, ids),
      isLoading: false,
    );
  }

  void updatePosition(int chatId, td.ChatPosition pos) {
    final chat = state.chats[chatId];
    if (chat == null) return;

    final positions = List<td.ChatPosition>.from(chat.positions);
    final idx = positions.indexWhere(
        (p) => p.list.getConstructor() == pos.list.getConstructor());
    if (idx != -1) {
      positions[idx] = pos;
    } else {
      positions.add(pos);
    }

    final updatedChat = chat.copyWith(positions: positions);
    final updated = Map<int, td.Chat>.from(state.chats);
    updated[chatId] = updatedChat;

    state = state.copyWith(
      chats: updated,
      orderedIds: _sortedIds(updated, state.orderedIds),
    );
  }

  void updateLastMessage(int chatId, td.Message? lastMessage,
      List<td.ChatPosition>? positions) {
    final chat = state.chats[chatId];
    if (chat == null) return;

    final updated = Map<int, td.Chat>.from(state.chats);
    updated[chatId] = chat.copyWith(
      lastMessage: lastMessage,
      positions: positions ?? chat.positions,
    );

    state = state.copyWith(
      chats: updated,
      orderedIds: _sortedIds(updated, state.orderedIds),
    );
  }

  void updateUnreadCount(int chatId, int count) {
    final chat = state.chats[chatId];
    if (chat == null) return;
    final updated = Map<int, td.Chat>.from(state.chats);
    updated[chatId] = chat.copyWith(unreadCount: count);
    state = state.copyWith(chats: updated);
  }

  void updateChatPhoto(int chatId, td.ChatPhotoInfo? photo) {
    final chat = state.chats[chatId];
    if (chat == null) return;
    final updated = Map<int, td.Chat>.from(state.chats);
    updated[chatId] = chat.copyWith(photo: photo);
    state = state.copyWith(chats: updated);
  }

  void updateChatTitle(int chatId, String title) {
    final chat = state.chats[chatId];
    if (chat == null) return;
    final updated = Map<int, td.Chat>.from(state.chats);
    updated[chatId] = chat.copyWith(title: title);
    state = state.copyWith(chats: updated);
  }

  void updateDraftMessage(int chatId, td.DraftMessage? draftMessage) {
    final chat = state.chats[chatId];
    if (chat == null) return;
    final updated = Map<int, td.Chat>.from(state.chats);
    updated[chatId] = chat.copyWith(draftMessage: draftMessage);
    state = state.copyWith(chats: updated);
  }

  void bumpChat(int chatId) {
    final ids = List<int>.from(state.orderedIds);
    if (ids.contains(chatId)) {
      ids.remove(chatId);
      ids.insert(0, chatId);
    }
    state = state.copyWith(orderedIds: ids);
  }

  // ── Typing indicator ────────────────────────────────────────────────────
  void setTyping(int chatId, String senderName) {
    final updated = Map<int, String>.from(state.typingUsers);
    updated[chatId] = senderName;
    state = state.copyWith(typingUsers: updated);
  }

  void clearTyping(int chatId) {
    final updated = Map<int, String>.from(state.typingUsers);
    updated.remove(chatId);
    state = state.copyWith(typingUsers: updated);
  }

  // ── Muted ────────────────────────────────────────────────────────────────
  void updateMuted(int chatId, bool isMuted) {
    final updated = Map<int, bool>.from(state.mutedChats);
    updated[chatId] = isMuted;
    state = state.copyWith(mutedChats: updated);
  }

  // ── Read receipts ────────────────────────────────────────────────────────
  void updateLastReadOutbox(int chatId, int messageId) {
    final updated = Map<int, int>.from(state.lastReadOutbox);
    updated[chatId] = messageId;
    state = state.copyWith(lastReadOutbox: updated);
  }

  // ── Pagination: 20 chats at a time ──────────────────────────────────────
  void loadMore() {
    if (!state.hasMore) return;
    ref.read(tdlibCoreProvider).loadChats(limit: 20);
  }

  void markNoMore() {
    state = state.copyWith(hasMore: false);
  }

  List<int> _sortedIds(Map<int, td.Chat> chats, List<int> ids) {
    final sorted = List<int>.from(ids);
    sorted.sort((a, b) {
      final ca = chats[a];
      final cb = chats[b];
      if (ca == null || cb == null) return 0;

      final oa = ca.positions
          .where((p) => p.list is td.ChatListMain)
          .map((p) => p.order)
          .firstOrNull ?? 0;
      final ob = cb.positions
          .where((p) => p.list is td.ChatListMain)
          .map((p) => p.order)
          .firstOrNull ?? 0;
      return ob.compareTo(oa);
    });
    return sorted;
  }
}

final chatListNotifierProvider =
    NotifierProvider<ChatListNotifier, ChatListState>(
  ChatListNotifier.new,
);
