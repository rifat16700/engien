import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class StoryViewerScreen extends StatelessWidget {
  const StoryViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Center(
            child: Text('Story Media Placeholder', style: TextStyle(color: Colors.white70)),
          ),
          Positioned(
            top: 40,
            left: 10,
            right: 10,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 50,
            left: 10,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.tgBlue,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: 10),
                Text('User Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(width: 10),
                Text('2h', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Positioned(
            top: 40,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
