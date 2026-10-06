import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../../core/constants/app_colors.dart';
import '../screens/player/full_player_screen.dart';
import '../screens/player/queue_screen.dart';

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final playlistProv = context.watch<PlaylistProvider>();
    final currentSong = player.currentSong;

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    final isFav = playlistProv.isFavorite(currentSong.id);

    // Calculate progress ratio
    double progress = 0.0;
    if (player.totalDuration.inSeconds > 0) {
      progress =
          (player.currentPosition.inSeconds / player.totalDuration.inSeconds)
              .clamp(0.0, 1.0);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = AppColors.textPrimary(context);
    final secondaryTextColor = AppColors.textSecondary(context);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, anim, secAnim) => const FullPlayerScreen(),
            transitionsBuilder: (context, anim, secAnim, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              final tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(position: anim.drive(tween), child: child);
            },
          ),
        );
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -300) {
            // Swipe up opens full player
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
            );
          } else if (details.primaryVelocity! > 300) {
            // Swipe down stops playback
            player.stop();
          }
        }
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -300) {
            player.next();
          } else if (details.primaryVelocity! > 300) {
            player.previous();
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xE60B0F19)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black12,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress Bar Line at top of mini player (Indigo gradient)
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryAccent),
                      minHeight: 2.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        // Thumbnail with playing equalizer badge overlay
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              currentSong.thumbnailUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: currentSong.thumbnailUrl,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        width: 44,
                                        height: 44,
                                        color: isDark
                                            ? Colors.grey.shade900
                                            : Colors.grey.shade200,
                                        child: Icon(Icons.music_note,
                                            color: secondaryTextColor),
                                      ),
                                    )
                                  : Container(
                                      width: 44,
                                      height: 44,
                                      color: isDark
                                          ? Colors.grey.shade900
                                          : Colors.grey.shade200,
                                      child: Icon(Icons.music_note,
                                          color: secondaryTextColor),
                                    ),
                              if (player.isPlaying)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    child: const Center(
                                      child: Icon(
                                        Icons.graphic_eq_rounded,
                                        color: AppColors.primaryAccent,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Title & Artist
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      currentSong.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primaryTextColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentSong.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Favorite Heart
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? const Color(0xFFEC4899) : (isDark ? Colors.white60 : Colors.black45),
                            size: 20,
                          ),
                          onPressed: () {
                            playlistProv.toggleFavorite(currentSong);
                          },
                        ),
                        // Prev Track Button
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 30, minHeight: 32),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.skip_previous_rounded,
                            color: isDark ? Colors.white70 : Colors.black87,
                            size: 22,
                          ),
                          onPressed: () => player.previous(),
                        ),
                        const SizedBox(width: 2),
                        // Circular White Play / Pause Button with Glowing Halo
                        GestureDetector(
                          onTap: () {
                            if (player.errorMessage != null) {
                              player.retryCurrentSong();
                            } else {
                              player.togglePlayPause();
                            }
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: player.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : Icon(
                                      player.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.black,
                                      size: 22,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        // Next Track Button
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 30, minHeight: 32),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.skip_next_rounded,
                            color: isDark ? Colors.white70 : Colors.black87,
                            size: 22,
                          ),
                          onPressed: () => player.next(),
                        ),
                        // Queue Button
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Queue',
                          icon: Icon(
                            Icons.queue_music_rounded,
                            color: isDark ? Colors.white70 : Colors.black87,
                            size: 20,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const QueueScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

