import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;
import '../../../core/providers/chat_list_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/tdlib_event_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../chat/chat_screen.dart';
import '../profile/my_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../contacts/contacts_screen.dart';
import '../contacts/new_chat_screen.dart';
import '../calls/call_log_screen.dart';
import '../../widgets/chat_avatar.dart';
import '../../widgets/chat_list_tile.dart';
import '../../widgets/shimmer_loading.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  bool _isSearching = false;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _fabVisible = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    // Load more when near bottom — 20 chats at a time
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(chatListNotifierProvider.notifier).loadMore();
    }

    // FAB hide/show based on scroll direction
    final currentOffset = _scrollController.position.pixels;
    if ((currentOffset - _lastScrollOffset) > 10 && _fabVisible) {
      setState(() => _fabVisible = false);
    } else if ((currentOffset - _lastScrollOffset) < -10 && !_fabVisible) {
      setState(() => _fabVisible = true);
    }
    _lastScrollOffset = currentOffset;
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
      floatingActionButton: AnimatedScale(
        scale: _fabVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: FloatingActionButton(
          onPressed: _openNewChatSheet,
          backgroundColor: AppTheme.tgBlue,
          child: const Icon(Icons.edit_rounded, color: Colors.white),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() {
            _isSearching = false;
            _searchController.clear();
          }),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
          onChanged: _onSearchChanged,
        ),
      );
    }

    return AppBar(
      backgroundColor: AppTheme.tgBlue,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: const Text(
        'NCHAT',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => setState(() => _isSearching = true),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    final me = ref.watch(myUserProvider);
    final myPhoto = me?.profilePhoto?.small;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              color: AppTheme.tgBlue,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyProfileScreen()),
                          );
                        },
                        child: ChatAvatar(
                          file: myPhoto,
                          name: me != null ? '${me.firstName} ${me.lastName}' : 'Me',
                          radius: 32,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // Theme toggle — future implementation
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    me != null
                        ? '${me.firstName} ${me.lastName}'.trim()
                        : 'Loading...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (me?.phoneNumber != null)
                    Text(
                      '+${me!.phoneNumber}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                ],
              ),
            ),

            // ── Menu items ──────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(
                    icon: Icons.person_rounded,
                    label: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const MyProfileScreen()));
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.group_rounded,
                    label: 'New Group',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NewChatScreen()));
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.contacts_rounded,
                    label: 'Contacts',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen()));
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.bookmark_rounded,
                    label: 'Saved Messages',
                    onTap: () {
                      Navigator.pop(context);
                      _openSavedMessages();
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.call_rounded,
                    label: 'Calls',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CallLogScreen()));
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                  const Divider(),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Log Out',
                    color: AppTheme.tgRed,
                    onTap: () {
                      Navigator.pop(context);
                      _confirmLogout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer(
      builder: (context, ref, _) {
        final chatState = ref.watch(chatListNotifierProvider);
        final chats = chatState.mainChats;

        // Skeleton shimmer while loading
        if (chatState.isLoading && chats.isEmpty) {
          return ListView.separated(
            itemCount: 12,
            separatorBuilder: (_, __) => const Divider(height: 0, indent: 72),
            itemBuilder: (_, i) => const ChatListShimmerTile(),
          );
        }

        if (chats.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.tgGrey),
                SizedBox(height: 16),
                Text('No chats yet', style: TextStyle(color: AppTheme.tgGrey, fontSize: 16)),
              ],
            ),
          );
        }

        // Filter by search query
        final query = _searchController.text.toLowerCase().trim();
        final filtered = query.isEmpty
            ? chats
            : chats
                .where((c) => c.title.toLowerCase().contains(query))
                .toList();

        return ListView.separated(
          controller: _scrollController,
          itemCount: filtered.length + (chatState.hasMore ? 1 : 0),
          separatorBuilder: (_, __) => const Divider(height: 0, indent: 72),
          itemBuilder: (_, i) {
            // Trailing shimmer for pagination
            if (i == filtered.length) {
              return const ChatListShimmerTile();
            }
            final chat = filtered[i];
            return ChatListTile(
              chat: chat,
              onTap: () => _openChat(chat),
            );
          },
        );
      },
    );
  }

  void _openChat(td.Chat chat) {
    ref.read(tdlibCoreProvider).send(td.OpenChat(chatId: chat.id));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatId: chat.id, chatTitle: chat.title),
      ),
    ).then((_) {
      ref.read(tdlibCoreProvider).send(td.CloseChat(chatId: chat.id));
    });
  }

  void _openSavedMessages() {
    final myId = ref.read(userNotifierProvider).myUserId;
    if (myId == null) return;
    // createPrivateChat with yourself opens Saved Messages in Telegram
    ref.read(tdlibCoreProvider).sendRaw({
      '@type': 'createPrivateChat',
      'user_id': myId,
      'force': true,
    });
    // After TDLib creates it, we open via chat update — navigate to chat
    // For now show a snackbar guide
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening Saved Messages...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _openNewChatSheet() {
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
              leading: const CircleAvatar(
                backgroundColor: AppTheme.tgBlue,
                child: Icon(Icons.person_add_rounded, color: Colors.white),
              ),
              title: const Text('New Private Chat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen()));
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.lock_rounded, color: Colors.white),
              ),
              title: const Text('New Secret Chat'),
              subtitle: const Text('End-to-end encrypted', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen()));
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.group_add_rounded, color: Colors.white),
              ),
              title: const Text('New Group'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NewChatScreen()));
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.campaign_rounded, color: Colors.white),
              ),
              title: const Text('New Channel'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Channel creation coming soon!')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).logout();
            },
            child: const Text('Log Out', style: TextStyle(color: AppTheme.tgRed)),
          ),
        ],
      ),
    );
  }
}

// ─── Drawer Item Helper ───────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
      dense: true,
    );
  }
}
