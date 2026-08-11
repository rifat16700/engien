import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tdlib/td_api.dart' as td;
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/tdlib_event_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/chat_avatar.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  
  void _editName(td.User? me) {
    if (me == null) return;
    final firstCtrl = TextEditingController(text: me.firstName);
    final lastCtrl = TextEditingController(text: me.lastName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstCtrl,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              controller: lastCtrl,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(tdlibCoreProvider).send(td.SetName(
                firstName: firstCtrl.text.trim(),
                lastName: lastCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editBio(td.User? me) {
    // We would need to fetch full info for bio, or assume we don't have it locally immediately.
    // However, TDLib getMe() doesn't return bio, getUserFullInfo does.
    // For simplicity, we just prompt to set bio.
    final bioCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Bio'),
        content: TextField(
          controller: bioCtrl,
          decoration: const InputDecoration(labelText: 'Bio', hintText: 'Any details about you'),
          maxLength: 70,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(tdlibCoreProvider).send(td.SetBio(
                bio: bioCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editUsername(td.User? me) {
    final usernameCtrl = TextEditingController(text: me?.usernames?.activeUsernames.firstOrNull ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Username'),
        content: TextField(
          controller: usernameCtrl,
          decoration: const InputDecoration(labelText: 'Username', prefixText: '@'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(tdlibCoreProvider).send(td.SetUsername(
                username: usernameCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      ref.read(tdlibCoreProvider).send(td.SetProfilePhoto(
        photo: td.InputChatPhotoStatic(
          photo: td.InputFileLocal(path: path),
        ),
        isPublic: true,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(myUserProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.tgBlue,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                me != null ? '${me.firstName} ${me.lastName}'.trim() : 'Profile',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                color: AppTheme.tgBlue,
                child: Stack(
                  children: [
                    Center(
                      child: me != null
                          ? ChatAvatar(
                              file: me.profilePhoto?.big,
                              name: '${me.firstName} ${me.lastName}',
                              radius: 70,
                            )
                          : const CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.person, size: 70, color: Colors.white),
                            ),
                    ),
                    Positioned(
                      bottom: 40,
                      right: MediaQuery.of(context).size.width / 2 - 80,
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.tgBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              ListTile(
                leading: const Icon(Icons.person_outline_rounded, color: AppTheme.tgBlue),
                title: Text(me != null ? '${me.firstName} ${me.lastName}'.trim() : 'Name'),
                subtitle: const Text('Name'),
                trailing: const Icon(Icons.edit_rounded, color: Colors.grey, size: 20),
                onTap: () => _editName(me),
              ),
              const Divider(indent: 72, height: 1),
              ListTile(
                leading: const Icon(Icons.phone_rounded, color: AppTheme.tgBlue),
                title: Text(me?.phoneNumber != null && me!.phoneNumber.isNotEmpty ? '+${me.phoneNumber}' : '—'),
                subtitle: const Text('Phone'),
              ),
              const Divider(indent: 72, height: 1),
              ListTile(
                leading: const Icon(Icons.alternate_email_rounded, color: AppTheme.tgBlue),
                title: Text(me?.usernames?.activeUsernames.isNotEmpty == true 
                    ? '@${me!.usernames!.activeUsernames.first}' 
                    : 'No username'),
                subtitle: const Text('Username'),
                trailing: const Icon(Icons.edit_rounded, color: Colors.grey, size: 20),
                onTap: () => _editUsername(me),
              ),
              const Divider(indent: 72, height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: AppTheme.tgBlue),
                title: const Text('Tap to set bio'), // Full user info needed for actual bio
                subtitle: const Text('Bio'),
                trailing: const Icon(Icons.edit_rounded, color: Colors.grey, size: 20),
                onTap: () => _editBio(me),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppTheme.tgRed),
                title: const Text('Log Out', style: TextStyle(color: AppTheme.tgRed)),
                onTap: () {
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
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
