import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/tdlib_event_handler.dart';
import '../../../core/providers/user_provider.dart';
import '../../widgets/chat_avatar.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  List<int> _contactIds = [];
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: AppTheme.tgBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {}, // TODO: search contacts
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _buildContactsList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.tgBlue,
        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        onPressed: () {}, // TODO: Add contact
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.builder(
      itemCount: _contactIds.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return ListTile(
            leading: const Icon(Icons.location_on_rounded, color: AppTheme.tgBlue),
            title: const Text('Find People Nearby'),
            onTap: () {},
          );
        } else if (index == 1) {
          return ListTile(
            leading: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.tgBlue),
            title: const Text('Invite Friends'),
            onTap: () {},
          );
        }
        
        final userId = _contactIds[index - 2];
        final user = ref.watch(userByIdProvider(userId));
        
        if (user == null) {
          // fetch user if missing
          ref.read(tdlibCoreProvider).send(td.GetUser(userId: userId));
          return const ListTile(title: Text('Loading...'));
        }

        return ListTile(
          leading: ChatAvatar(
            file: user.profilePhoto?.small,
            name: '${user.firstName} ${user.lastName}',
            radius: 20,
          ),
          title: Text('${user.firstName} ${user.lastName}'.trim()),
          subtitle: Text(
            user.status is td.UserStatusOnline ? 'Online' : 'last seen recently',
            style: TextStyle(
              color: user.status is td.UserStatusOnline ? AppTheme.tgBlue : Colors.grey,
            ),
          ),
          onTap: () {
            // TODO: Open chat with contact
          },
        );
      },
    );
  }
}
