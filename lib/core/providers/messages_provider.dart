import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;
import 'tdlib_event_handler.dart';

// ─── Messages State ───────────────────────────────────────────────────────
class MessagesState {
  final List<td.Message> messages;  // sorted: newest first (index 0 = newest)
  final bool isLoadingHistory;
  final bool hasMore;               // আরো পুরনো মেসেজ আছে কিনা
  final bool isInitialLoading;      // প্রথমবার খোলার সময় skeleton দেখাবে

  const MessagesState({
    this.messages = const [],
    this.isLoadingHistory = false,
    this.hasMore = true,
    this.isInitialLoading = true,
  });

  MessagesState copyWith({
    List<td.Message>? messages,
    bool? isLoadingHistory,
    bool? hasMore,
    bool? isInitialLoading,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
    );
  }
}

// ─── Messages Notifier ────────────────────────────────────────────────────
class MessagesNotifier extends FamilyNotifier<MessagesState, int> {
  int get chatId => arg;

  @override
  MessagesState build(int arg) => const MessagesState();

  // নতুন মেসেজ আসলে (real-time)
  void addNewMessage(td.Message message) {
    final list = List<td.Message>.from(state.messages);
    if (list.any((m) => m.id == message.id)) {
      _updateMessage(message, list);
      return;
    }
    list.insert(0, message);  // newest first
    state = state.copyWith(messages: list, isInitialLoading: false);
  }

  // History load (GetChatHistory response)
  void addHistoryMessages(List<td.Message> incoming) {
    if (incoming.isEmpty) return;

    final list = List<td.Message>.from(state.messages);
    bool added = false;
    for (final m in incoming) {
      if (!list.any((e) => e.id == m.id)) {
        list.add(m);
        added = true;
      }
    }
    
    // Only sort if we actually added something
    if (added) {
      list.sort((a, b) => b.id.compareTo(a.id));
    }

    state = state.copyWith(
      messages: list,
      isLoadingHistory: false,
      isInitialLoading: false,
      hasMore: incoming.length >= 20,
    );
  }

  void updateContent(int messageId, td.MessageContent newContent) {
    final list = List<td.Message>.from(state.messages);
    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(content: newContent);
      state = state.copyWith(messages: list);
    }
  }

  void deleteMessages(List<int> ids) {
    final list = state.messages.where((m) => !ids.contains(m.id)).toList();
    state = state.copyWith(messages: list);
  }

  void onSendSucceeded(td.Message newMessage, int oldId) {
    final list = List<td.Message>.from(state.messages);
    final idx = list.indexWhere((m) => m.id == oldId);
    if (idx != -1) {
      list[idx] = newMessage;
    } else {
      list.insert(0, newMessage);
    }
    state = state.copyWith(messages: list);
  }

  void setLoadingHistory(bool loading) {
    state = state.copyWith(isLoadingHistory: loading);
  }

  // পুরনো মেসেজ লোড (scroll করলে) — 20 chunk
  void loadHistory() {
    if (state.isLoadingHistory || !state.hasMore) return;
    state = state.copyWith(isLoadingHistory: true);

    final fromMessageId = state.messages.isNotEmpty
        ? state.messages.last.id
        : 0;

    ref.read(tdlibCoreProvider).send(td.GetChatHistory(
      chatId: chatId,
      fromMessageId: fromMessageId,
      offset: 0,
      limit: 20,
      onlyLocal: false,
    ));
  }

  // চ্যাটে প্রথম ঢুকলে
  void loadInitial() {
    // Only query server/local mixed natively via TDLib.
    // TDLib is extremely fast and returns local cache immediately if onlyLocal is false.
    ref.read(tdlibCoreProvider).send(td.GetChatHistory(
      chatId: chatId,
      fromMessageId: 0,
      offset: 0,
      limit: 20, // Strict 20 limit to speed up parsing
      onlyLocal: false,
    ));
  }

  void _updateMessage(td.Message message, List<td.Message> list) {
    final idx = list.indexWhere((m) => m.id == message.id);
    if (idx != -1) {
      list[idx] = message;
      state = state.copyWith(messages: list);
    }
  }
}

final messagesNotifierProvider =
    NotifierProviderFamily<MessagesNotifier, MessagesState, int>(
  MessagesNotifier.new,
);
