import 'package:flutter/material.dart';

class MediaViewerScreen extends StatelessWidget {
  final String mediaUrl;
  const MediaViewerScreen({super.key, required this.mediaUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Center(
        child: Text('Media Viewer Placeholder\n$mediaUrl', 
          textAlign: TextAlign.center, 
          style: const TextStyle(color: Colors.white)
        ),
      ),
    );
  }
}
