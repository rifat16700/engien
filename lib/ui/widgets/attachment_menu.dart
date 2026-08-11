import 'package:flutter/material.dart';

class AttachmentMenu extends StatelessWidget {
  const AttachmentMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildIcon(Icons.image, 'Gallery', Colors.blue),
          _buildIcon(Icons.insert_drive_file, 'File', Colors.orange),
          _buildIcon(Icons.location_on, 'Location', Colors.green),
          _buildIcon(Icons.person, 'Contact', Colors.purple),
          _buildIcon(Icons.poll, 'Poll', Colors.amber),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
