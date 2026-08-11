import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;

// ─── User State ───────────────────────────────────────────────────────────
class UserState {
  final Map<int, td.User> users;
  final Map<int, td.UserStatus> statuses;
  final int? myUserId;  // নিজের Telegram user ID

  const UserState({
    this.users = const {},
    this.statuses = const {},
    this.myUserId,
  });

  UserState copyWith({
    Map<int, td.User>? users,
    Map<int, td.UserStatus>? statuses,
    int? myUserId,
  }) {
    return UserState(
      users: users ?? this.users,
      statuses: statuses ?? this.statuses,
      myUserId: myUserId ?? this.myUserId,
    );
  }

  td.User? get me => myUserId != null ? users[myUserId!] : null;
  td.User? getUser(int id) => users[id];

  bool isOnline(int userId) {
    final status = statuses[userId] ?? users[userId]?.status;
    return status is td.UserStatusOnline;
  }
}

// ─── User Notifier ────────────────────────────────────────────────────────
class UserNotifier extends Notifier<UserState> {
  @override
  UserState build() => const UserState();

  void upsertUser(td.User user) {
    final updated = {...state.users, user.id: user};

    // যদি এটি আমার নিজের user হয়
    // GetMe() response এ @extra: 'getMe' পাঠানো হয়, তাই প্রথম user আসলে
    // আমরা assume করতে পারি এটা আমাদের নিজের — পরে @extra দিয়ে verify করা হবে
    final myId = state.myUserId ?? (state.users.isEmpty ? user.id : state.myUserId);

    state = state.copyWith(users: updated, myUserId: myId);
  }

  void setMyUserId(int id) {
    state = state.copyWith(myUserId: id);
  }

  void updateStatus(int userId, td.UserStatus status) {
    state = state.copyWith(statuses: {...state.statuses, userId: status});
  }

  bool isOnline(int userId) {
    final status = state.statuses[userId] ?? state.users[userId]?.status;
    return status is td.UserStatusOnline;
  }
}

final userNotifierProvider =
    NotifierProvider<UserNotifier, UserState>(UserNotifier.new);

// ─── Convenience providers ────────────────────────────────────────────────
final myUserProvider = Provider<td.User?>((ref) {
  return ref.watch(userNotifierProvider).me;
});

final userByIdProvider = Provider.family<td.User?, int>((ref, userId) {
  return ref.watch(userNotifierProvider).users[userId];
});
