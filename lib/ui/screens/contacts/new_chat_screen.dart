import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/tdlib_event_handler.dart';
import '../../../core/providers/user_provider.dart';
import '../../widgets/chat_avatar.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  List<int> _contactIds = [];
  bool _isLoading = true;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
    ref.read(tdlibCoreProvider).send(const td.GetContacts());
    setState(() {
      _isLoading = false;
    });
  }

  void _toggleSelection(int userId) {
    setState(() {
      if (_selectedIds.contains(userId)) {
        _selectedIds.remove(userId);
      } else {
        _selectedIds.add(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Group', style: TextStyle(fontSize: 18)),
            Text(
              '${_selectedIds.length} / 200000',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppTheme.tgBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContactsList(),
      floatingActionButton: _selectedIds.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: AppTheme.tgBlue,
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              onPressed: () {
                // TODO: Proceed to Group Name / Avatar input screen
              },
            )
          : null,
    );
  }

  Widget _buildContactsList() {
    return ListView.builder(
      itemCount: _contactIds.length,
      itemBuilder: (context, index) {
        final userId = _contactIds[index];
        final user = ref.watch(userByIdProvider(userId));
        
        if (user == null) {
          ref.read(tdlibCoreProvider).send(td.GetUser(userId: userId));
          return const ListTile(title: Text('Loading...'));
        }

        final isSelected = _selectedIds.contains(userId);

        return ListTile(
          leading: Stack(
            children: [
              ChatAvatar(
                file: user.profilePhoto?.small,
                name: '${user.firstName} ${user.lastName}',
                radius: 20,
              ),
              if (isSelected)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.tgBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
          title: Text('${user.firstName} ${user.lastName}'.trim()),
          subtitle: Text(
            user.status is td.UserStatusOnline ? 'Online' : 'last seen recently',
            style: TextStyle(
              color: user.status is td.UserStatusOnline ? AppTheme.tgBlue : Colors.grey,
            ),
          ),
          onTap: () => _toggleSelection(userId),
        );
      },
    );
  }
}
