import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../../core/constants/app_colors.dart';
import '../screens/player/full_player_screen.dart';

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
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xF50B0F19)
              : Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0x1AFFFFFF) : Colors.black12,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
              blurRadius: 16,
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
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: currentSong.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: currentSong.thumbnailUrl,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 46,
                              height: 46,
                              color: isDark
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade200,
                              child: Icon(Icons.music_note,
                                  color: secondaryTextColor),
                            ),
                          )
                        : Container(
                            width: 46,
                            height: 46,
                            color: isDark
                                ? Colors.grey.shade900
                                : Colors.grey.shade200,
                            child: Icon(Icons.music_note,
                                color: secondaryTextColor),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Title & Artist
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentSong.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentSong.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Favorite Heart
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? const Color(0xFFEC4899) : (isDark ? Colors.white60 : Colors.black45),
                      size: 22,
                    ),
                    onPressed: () {
                      playlistProv.toggleFavorite(currentSong);
                    },
                  ),
                  // Prev Track Button
                  IconButton(
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      color: isDark ? Colors.white70 : Colors.black87,
                      size: 24,
                    ),
                    onPressed: () => player.previous(),
                  ),
                  const SizedBox(width: 2),
                  // Circular White Play / Pause Button (Matching Image 1)
                  GestureDetector(
                    onTap: () {
                      if (player.errorMessage != null) {
                        player.retryCurrentSong();
                      } else {
                        player.togglePlayPause();
                      }
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: player.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
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
                                size: 24,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Next Track Button
                  IconButton(
                    icon: Icon(
                      Icons.skip_next_rounded,
                      color: isDark ? Colors.white70 : Colors.black87,
                      size: 24,
                    ),
                    onPressed: () => player.next(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
