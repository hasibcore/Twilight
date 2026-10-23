import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/song.dart';
import '../../core/constants/app_colors.dart';
import '../providers/download_provider.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../screens/playlist/create_playlist_dialog.dart';

enum SongCardVariant { horizontalCard, listTile }

class SongCard extends StatelessWidget {
  final Song song;
  final SongCardVariant variant;
  final List<Song>? queueContext;
  final VoidCallback? onTap;

  const SongCard({
    super.key,
    required this.song,
    this.variant = SongCardVariant.horizontalCard,
    this.queueContext,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == SongCardVariant.horizontalCard) {
      return _buildHorizontalCard(context);
    }
    return _buildListTile(context);
  }

  Widget _buildHorizontalCard(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final isCurrent = player.currentSong?.id == song.id;

    return GestureDetector(
      onTap: onTap ??
          () {
            context
                .read<PlayerProvider>()
                .playSong(song, newQueue: queueContext);
          },
      child: Container(
        width: 145,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork with play badge overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: song.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: song.thumbnailUrl,
                          width: 145,
                          height: 145,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 145,
                            height: 145,
                            color: AppColors.surfaceVariantDark,
                            child: const Center(
                              child:
                                  Icon(Icons.music_note, color: Colors.white24),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 145,
                            height: 145,
                            color: AppColors.surfaceVariantDark,
                            child: const Icon(Icons.broken_image,
                                color: Colors.white24),
                          ),
                        )
                      : Container(
                          width: 145,
                          height: 145,
                          color: AppColors.surfaceVariantDark,
                          child: const Icon(Icons.music_note,
                              color: Colors.white24),
                        ),
                ),
                if (song.playCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFF97316).withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '${song.playCount} plays',
                        style: const TextStyle(
                          color: Color(0xFFFB923C),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (isCurrent)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.graphic_eq_rounded,
                          color: AppColors.primaryAccent,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Consumer<DownloadProvider>(
                    builder: (_, downloadProv, __) {
                      final isDownloaded = downloadProv.isDownloaded(song.id);
                      final isDownloading = downloadProv.isDownloading(song.id);
                      final progress = downloadProv.getProgress(song.id);

                      return Material(
                        color: Colors.black.withValues(alpha: 0.72),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: isDownloading
                              ? null
                              : () => _handleDownloadTap(
                                  context, downloadProv, isDownloaded),
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: Center(
                              child: isDownloading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        value: progress > 0.05 ? progress : null,
                                        strokeWidth: 2,
                                        color: AppColors.primaryAccent,
                                      ),
                                    )
                                  : Icon(
                                      isDownloaded
                                          ? Icons.download_done_rounded
                                          : Icons.download_rounded,
                                      size: 19,
                                      color: isDownloaded
                                          ? const Color(0xFF00E676)
                                          : Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              song.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isCurrent
                    ? AppColors.primaryAccent
                    : AppColors.textPrimary(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            // Artist
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final isCurrent = player.currentSong?.id == song.id;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: song.thumbnailUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: song.thumbnailUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 52,
                      height: 52,
                      color: AppColors.surfaceVariant(context),
                      child: Icon(Icons.music_note,
                          color: AppColors.iconMuted(context)),
                    ),
                  )
                : Container(
                    width: 52,
                    height: 52,
                    color: AppColors.surfaceVariant(context),
                    child: Icon(Icons.music_note,
                        color: AppColors.iconMuted(context)),
                  ),
          ),
          if (isCurrent)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.graphic_eq_rounded,
                  color: AppColors.primaryAccent, size: 24),
            ),
        ],
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isCurrent
              ? AppColors.primaryAccent
              : AppColors.textPrimary(context),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${song.artist} • ${song.durationFormatted}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.textSecondary(context),
          fontSize: 12,
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.more_vert, color: AppColors.textSecondary(context)),
        onPressed: () => _showContextMenu(context),
      ),
      onTap: onTap ??
          () {
            context
                .read<PlayerProvider>()
                .playSong(song, newQueue: queueContext);
          },
    );
  }

  Future<void> _handleDownloadTap(
    BuildContext context,
    DownloadProvider downloadProv,
    bool isDownloaded,
  ) async {
    if (isDownloaded) {
      await downloadProv.deleteDownload(song.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download removed')),
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading "${song.title}"...')),
    );
    final ok = await downloadProv.startDownload(song);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Downloaded "${song.title}" for offline playback!'
              : (downloadProv.lastError ?? 'Download failed'),
        ),
        backgroundColor: ok ? const Color(0xFF00E676) : Colors.redAccent,
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final playlistProv = sheetContext.watch<PlaylistProvider>();
        final isFav = playlistProv.isSongFavorite(song.id);

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: song.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: song.thumbnailUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 44,
                            height: 44,
                            color: AppColors.surfaceVariantDark,
                            child: const Icon(Icons.music_note,
                                color: Colors.white38),
                          ),
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          color: AppColors.surfaceVariantDark,
                          child: const Icon(Icons.music_note,
                              color: Colors.white38),
                        ),
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondaryDark),
                ),
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.queue_music, color: Colors.white),
                title: const Text('Play next'),
                onTap: () {
                  context.read<PlayerProvider>().playNext(song);
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playing next')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add, color: Colors.white),
                title: const Text('Add to queue'),
                onTap: () {
                  context.read<PlayerProvider>().addToQueue(song);
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to queue')),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? AppColors.primaryAccent : Colors.white,
                ),
                title:
                    Text(isFav ? 'Remove from Favorites' : 'Add to Favorites'),
                onTap: () {
                  playlistProv.toggleFavorite(song);
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_to_photos_outlined,
                    color: Colors.white),
                title: const Text('Add to Playlist'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showAddToPlaylistSheet(context);
                },
              ),
              Consumer<DownloadProvider>(
                builder: (_, downloadProv, __) {
                  final isDownloaded = downloadProv.isDownloaded(song.id);
                  final isDownloading = downloadProv.isDownloading(song.id);

                  return ListTile(
                    leading: isDownloading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryAccent,
                            ),
                          )
                        : Icon(
                            isDownloaded
                                ? Icons.delete_outline
                                : Icons.download_rounded,
                            color:
                                isDownloaded ? Colors.redAccent : Colors.white,
                          ),
                    title: Text(
                      isDownloaded
                          ? 'Remove from Downloads'
                          : (isDownloading
                              ? 'Downloading...'
                              : 'Download Song'),
                      style: TextStyle(
                        color: isDownloaded ? Colors.redAccent : Colors.white,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      if (isDownloaded) {
                        downloadProv.deleteDownload(song.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Download removed')),
                        );
                      } else if (!isDownloading) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Downloading "${song.title}"...')),
                        );
                        final ok = await downloadProv.startDownload(song);
                        if (context.mounted) {
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Downloaded "${song.title}" for offline playback!'),
                                backgroundColor: const Color(0xFF00E676),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(downloadProv.lastError ??
                                    'Download failed'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      }
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddToPlaylistSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Consumer<PlaylistProvider>(
          builder: (modalCtx, playlistProv, _) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add to playlist',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('New'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const CreatePlaylistDialog(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    if (playlistProv.playlists.isEmpty)
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.queue_music,
                                  size: 40, color: Colors.white30),
                              SizedBox(height: 8),
                              Text('No playlists yet',
                                  style: TextStyle(color: Colors.white70)),
                              SizedBox(height: 4),
                              Text(
                                'Tap "+ New" above to create your first playlist.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.textSecondaryDark,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: playlistProv.playlists.length,
                          itemBuilder: (_, index) {
                            final pl = playlistProv.playlists[index];
                            return ListTile(
                              leading: const Icon(Icons.queue_music,
                                  color: AppColors.primaryAccent),
                              title: Text(pl.title,
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text('${pl.songCount} songs',
                                  style: const TextStyle(
                                      color: AppColors.textSecondaryDark)),
                              onTap: () {
                                playlistProv.addSongToPlaylist(pl.id, song);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Added to ${pl.title}')),
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
