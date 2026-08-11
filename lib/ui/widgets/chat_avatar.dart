import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdlib/td_api.dart' as td;
import '../../core/providers/file_provider.dart';
import '../../core/theme/app_theme.dart';
import 'shimmer_loading.dart';

/// Telegram-like circular avatar।
/// Photo load হওয়ার আগে shimmer দেখাবে, তারপর আস্তে ফেইড করে আসবে।
class ChatAvatar extends ConsumerWidget {
  final td.File? file;
  final String name;
  final double radius;
  final bool showOnlineBadge;
  final String? heroTag;

  const ChatAvatar({
    super.key,
    required this.file,
    required this.name,
    this.radius = 27,
    this.showOnlineBadge = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileId = file?.id;

    // File provider থেকে real-time update
    final trackFile = fileId != null
        ? ref.watch(fileByIdProvider(fileId))
        : null;

    final effectiveFile = trackFile ?? file;
    final localPath = effectiveFile?.local.isDownloadingCompleted == true &&
            effectiveFile!.local.path.isNotEmpty
        ? effectiveFile.local.path
        : null;

    final isDownloading = effectiveFile?.local.isDownloadingActive == true;

    Widget avatar;

    if (localPath != null && File(localPath).existsSync()) {
      // Photo ready — fade in
      avatar = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 250),
        builder: (_, alpha, child) => Opacity(opacity: alpha, child: child),
        child: CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(File(localPath)),
        ),
      );
    } else if (isDownloading && fileId != null) {
      // Downloading — show shimmer
      avatar = ShimmerLoading(
        isLoading: true,
        child: CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFFE0E0E0),
        ),
      );
    } else {
      // No photo — initials with color
      final initials = _getInitials(name);
      final color = _getColor(name);
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: color,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.65,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (heroTag != null) {
      avatar = Hero(tag: heroTag!, child: avatar);
    }

    if (!showOnlineBadge) return avatar;

    // Online badge overlay
    return Stack(
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: radius * 0.5,
            height: radius * 0.5,
            decoration: BoxDecoration(
              color: AppTheme.tgGreen,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _getColor(String name) {
    const colors = [
      Color(0xFFFF5252),
      Color(0xFF448AFF),
      Color(0xFF69F0AE),
      Color(0xFFFFD740),
      Color(0xFFE040FB),
      Color(0xFF40C4FF),
      Color(0xFFFF6D00),
      Color(0xFF1DE9B6),
    ];
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[idx];
  }
}
