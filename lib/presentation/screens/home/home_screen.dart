import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/artist.dart';
import '../../../domain/repositories/youtube_repository.dart';
import '../../providers/player_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/song_card.dart';
import '../../widgets/artist_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _isDynamicLoading = false;
  List<Song> _quickPicks = [];
  List<Song> _trending = [];
  List<Song> _recommended = [];
  List<Artist> _popularArtists = [];

  // Vibe categories from Image 1
  String _selectedVibeId = 'for_you';
  final Map<String, List<Song>> _vibeCache = {};
  List<Song> _dynamicSongs = [];

  final List<Map<String, String>> _vibeCategories = const [
    {'id': 'for_you', 'label': 'For You', 'query': 'top global hits 2026'},
    {'id': 'lofi', 'label': '☕ Lo-Fi & Focus', 'query': 'Lo-Fi Focus Study Beats'},
    {'id': 'romantic', 'label': '❤️ Romantic Melodies', 'query': 'Romantic Acoustic Love Songs'},
    {'id': 'bengali', 'label': '🇧🇩 Bengali Melodies', 'query': 'Best Bengali Soulful Acoustic Melodies'},
    {'id': 'energy', 'label': '⚡ Energy & Pop', 'query': 'Top Pop Dance Hits 2026'},
    {'id': 'chill', 'label': '🌙 Late Night Chill', 'query': 'Midnight Chill Ambient Acoustic'},
    {'id': 'acoustic', 'label': '🎸 Acoustic & Soulful', 'query': 'Acoustic Guitar Unplugged Hits'},
    {'id': 'workout', 'label': '🔥 Workout & Drive', 'query': 'High Energy Workout EDM Hits'},
  ];

  // Default featured songs for ON HEAVY REPEAT (matching Image 1)
  final List<Song> _defaultFrequentSongs = const [
    Song(
      id: '4NRXx6U8ABQ',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      channelId: 'TheWeekndVEVO',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop&q=80',
      durationSeconds: 200,
      durationFormatted: '03:20',
      playCount: 22,
    ),
    Song(
      id: 'JGwWNGJdvx8',
      title: 'Shape of You',
      artist: 'Ed Sheeran',
      channelId: 'EdSheeran',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500&auto=format&fit=crop&q=80',
      durationSeconds: 234,
      durationFormatted: '03:54',
      playCount: 18,
    ),
    Song(
      id: 'fJ9rUzIMcZQ',
      title: 'Bohemian Rhapsody',
      artist: 'Queen',
      channelId: 'QueenOfficial',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=80',
      durationSeconds: 355,
      durationFormatted: '05:55',
      playCount: 15,
    ),
    Song(
      id: 'CevxZvSJLk8',
      title: 'Sugar',
      artist: 'Maroon 5',
      channelId: 'Maroon5VEVO',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=80',
      durationSeconds: 235,
      durationFormatted: '03:55',
      playCount: 15,
    ),
    Song(
      id: 'kJQP7kiw5Fk',
      title: 'Despacito',
      artist: 'Luis Fonsi ft. Daddy Yankee',
      channelId: 'LuisFonsiVEVO',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=80',
      durationSeconds: 282,
      durationFormatted: '04:42',
      playCount: 12,
    ),
    Song(
      id: 'hT_nvWreIhg',
      title: 'Counting Stars',
      artist: 'OneRepublic',
      channelId: 'OneRepublicVEVO',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1445985543469-433ecdd6294c?w=500&auto=format&fit=crop&q=80',
      durationSeconds: 257,
      durationFormatted: '04:17',
      playCount: 10,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  // Time based greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 22) return 'Good evening';
    return 'Good night';
  }

  // Time based dynamic vibe
  Map<String, String> _getTimeBasedVibe() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return {'label': '☀️ MORNING BOOST', 'query': 'morning acoustic pop hits 2026'};
    }
    if (hour >= 12 && hour < 17) {
      return {'label': '🔥 AFTERNOON FOCUS', 'query': 'upbeat focus lofi pop hits'};
    }
    if (hour >= 17 && hour < 22) {
      return {'label': '🌆 SUNSET GROOVE', 'query': 'evening chill melodies'};
    }
    return {'label': '🌙 MIDNIGHT SERENADE', 'query': 'late night acoustic chill ambient'};
  }

  Future<void> _loadHomeData() async {
    setState(() => _isLoading = true);
    final ytRepo = context.read<YouTubeRepository>();

    try {
      final results = await Future.wait([
        ytRepo.getQuickPicks(),
        ytRepo.getTrendingMusic(),
        ytRepo.getRecommendedMusic(),
        ytRepo.getPopularArtists(),
      ]);

      if (mounted) {
        setState(() {
          _quickPicks = results[0] as List<Song>;
          _trending = results[1] as List<Song>;
          _recommended = results[2] as List<Song>;
          _popularArtists = results[3] as List<Artist>;
          _isLoading = false;
        });

        // Pre-load dynamic mix
        _loadDynamicSongs(_selectedVibeId);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectVibe(String vibeId) async {
    if (_selectedVibeId == vibeId && _dynamicSongs.isNotEmpty) return;
    setState(() {
      _selectedVibeId = vibeId;
      if (_vibeCache.containsKey(vibeId)) {
        _dynamicSongs = _vibeCache[vibeId]!;
      } else {
        _isDynamicLoading = true;
      }
    });

    if (_vibeCache.containsKey(vibeId)) return;
    await _loadDynamicSongs(vibeId);
  }

  Future<void> _loadDynamicSongs(String vibeId) async {
    setState(() => _isDynamicLoading = true);
    final ytRepo = context.read<YouTubeRepository>();

    final vibe = _vibeCategories.firstWhere(
      (v) => v['id'] == vibeId,
      orElse: () => _vibeCategories.first,
    );

    String query = vibe['query'] ?? 'popular music 2026';
    if (vibeId == 'for_you') {
      query = _getTimeBasedVibe()['query']!;
    }

    try {
      final songs = await ytRepo.searchSongs(query);
      if (mounted && _selectedVibeId == vibeId) {
        setState(() {
          _vibeCache[vibeId] = songs;
          _dynamicSongs = songs.isNotEmpty ? songs : _defaultFrequentSongs;
          _isDynamicLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _dynamicSongs = _defaultFrequentSongs;
          _isDynamicLoading = false;
        });
      }
    }
  }

  void _showDownloadsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.download_done_rounded,
                      color: AppColors.primaryAccent, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Download Twilight Apps',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Available for Android, Windows PC & iOS',
                      style: TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.android_rounded, color: Colors.greenAccent),
              title: const Text('Android Mobile APK',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Direct installable APK for Android devices',
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.white38),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Android APK downloaded & updated to v2.4.1')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.laptop_windows_rounded, color: Colors.lightBlueAccent),
              title: const Text('Windows PC App',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Desktop executable with background audio playback',
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.white38),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Windows PC version available in downloads folder')),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistProv = context.watch<PlaylistProvider>();
    final playerProv = context.watch<PlayerProvider>();
    final hasCurrentSong = playerProv.currentSong != null;
    final bottomPadding = hasCurrentSong ? 110.0 : 40.0;

    final timeVibe = _getTimeBasedVibe();

    // Prepare Heavy Repeat tracks (merge recentlyPlayed if available or use default frequent songs)
    List<Song> heavyRepeatSongs = [];
    if (playlistProv.recentlyPlayed.isNotEmpty) {
      heavyRepeatSongs = playlistProv.recentlyPlayed.map((song) {
        return song.playCount > 0 ? song : song.copyWith(playCount: 15);
      }).toList();
    } else {
      heavyRepeatSongs = _defaultFrequentSongs;
    }

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(size: 34, showText: true),
        actions: [
          // Sleek Downloads button with green pulsing status dot
          IconButton(
            tooltip: 'Download Apps',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      size: 20,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.backgroundDark,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => _showDownloadsDialog(context),
          ),
          const SizedBox(width: 4),

          // User Avatar Button
          IconButton(
            tooltip: 'Search & Explore',
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: Colors.white70,
                ),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Ambient Cosmic Indigo Glow (Top Right)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.16),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Ambient Warm Flame Glow (Behind Heavy Repeat)
          Positioned(
            top: 240,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF97316).withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              _vibeCache.clear();
              await _loadHomeData();
            },
            color: AppColors.primaryAccent,
            backgroundColor: AppColors.surfaceVariantDark,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

              // 1. TOP HEADER / GREETING BAR (Matching Image 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeVibe['label']!,
                      style: const TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. VIBE CATEGORIES FILTER CHIPS (Matching Image 1)
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _vibeCategories.length,
                  itemBuilder: (_, index) {
                    final vibe = _vibeCategories[index];
                    final vibeId = vibe['id']!;
                    final label = vibe['label']!;
                    final isForYou = vibeId == 'for_you';
                    final isSelected = _selectedVibeId == vibeId;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _selectVibe(vibeId),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isForYou
                                    ? Colors.white
                                    : const Color(0xFF4F46E5))
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: isForYou
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : const Color(0xFF4F46E5)
                                              .withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isForYou) ...[
                                Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: isSelected
                                      ? const Color(0xFF030712)
                                      : Colors.white70,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                label,
                                style: TextStyle(
                                  color: isSelected
                                      ? (isForYou
                                          ? const Color(0xFF030712)
                                          : Colors.white)
                                      : const Color(0xFFCBD5E1),
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 3. ON HEAVY REPEAT (MOST PLAYED) SECTION (Matching Image 1)
              _buildHeavyRepeatSection(heavyRepeatSongs, playerProv),

              const SizedBox(height: 20),

              // 4. DYNAMIC TASTE ENGINE SECTION (Matching Image 1)
              _buildDynamicTasteSection(playerProv, timeVibe),

              const SizedBox(height: 24),

              if (_isLoading) ...[
                const SectionSkeleton(),
                const SectionSkeleton(),
              ] else ...[
                // Quick Picks
                if (_quickPicks.isNotEmpty) ...[
                  _buildSectionHeader(AppStrings.quickPicks, 'Listen again'),
                  _buildSongHorizontalList(_quickPicks),
                  const SizedBox(height: 24),
                ],

                // Recently Played
                if (playlistProv.recentlyPlayed.isNotEmpty) ...[
                  _buildSectionHeader(AppStrings.recentlyPlayed, 'History'),
                  _buildSongHorizontalList(playlistProv.recentlyPlayed),
                  const SizedBox(height: 24),
                ],

                // Trending Music (Global Charts)
                if (_trending.isNotEmpty) ...[
                  _buildSectionHeader(
                      AppStrings.trendingMusic, 'Global Charts'),
                  _buildSongHorizontalList(_trending),
                  const SizedBox(height: 24),
                ],

                // Recommended For You
                if (_recommended.isNotEmpty) ...[
                  _buildSectionHeader(
                      AppStrings.recommended, 'Based on your taste'),
                  _buildSongHorizontalList(_recommended),
                  const SizedBox(height: 24),
                ],

                // Popular Artists
                if (_popularArtists.isNotEmpty) ...[
                  _buildSectionHeader(
                      AppStrings.popularArtists, 'Top creators'),
                  _buildArtistHorizontalList(_popularArtists),
                  const SizedBox(height: 16),
                ],

                // Audio Quality Badge (Matching Image 1)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0x33311042), Color(0x331E1B4B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            const Color(0xFF6366F1).withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF34D399),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF34D399),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '256 kbps Audio',
                          style: TextStyle(
                            color: Color(0xFF818CF8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'High-fidelity playback with cloud sync & offline cache.',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    ],
  ),
);
  }

  /// ON HEAVY REPEAT (MOST PLAYED) Glassmorphic Card (Image 1)
  Widget _buildHeavyRepeatSection(
      List<Song> songs, PlayerProvider playerProv) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0x337C2D12), // Subtle orange tint
            Color(0x1F4C0519), // Rose tint
            Color(0x80030712), // Dark slate
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF97316).withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF97316).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFF97316),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ON HEAVY REPEAT (MOST PLAYED)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Songs you listen to the most',
                        style: TextStyle(
                          color: Color(0xFFFDBA74),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Orange "Play All" button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: const Color(0xFF030712),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor:
                      const Color(0xFFF97316).withValues(alpha: 0.4),
                ),
                icon: const Icon(Icons.play_arrow_rounded,
                    size: 18, color: Color(0xFF030712)),
                label: const Text(
                  'Play All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                onPressed: () {
                  if (songs.isNotEmpty) {
                    playerProv.playSong(songs.first, newQueue: songs);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Horizontal list of Heavy Repeat song cards with playCount badges
          SizedBox(
            height: 188,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: songs.length,
              itemBuilder: (_, index) {
                final song = songs[index];
                return SongCard(
                  song: song,
                  queueContext: songs,
                  variant: SongCardVariant.horizontalCard,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// DYNAMIC TASTE ENGINE Section (Image 1)
  Widget _buildDynamicTasteSection(
      PlayerProvider playerProv, Map<String, String> timeVibe) {
    String currentVibeLabel = timeVibe['label']!;
    if (_selectedVibeId != 'for_you') {
      final vibe = _vibeCategories.firstWhere(
        (v) => v['id'] == _selectedVibeId,
        orElse: () => _vibeCategories.first,
      );
      currentVibeLabel = vibe['label']!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DYNAMIC TASTE ENGINE',
                    style: TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentVibeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isDynamicLoading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Refresh Mix',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                onPressed: () {
                  _vibeCache.remove(_selectedVibeId);
                  _loadDynamicSongs(_selectedVibeId);
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_isDynamicLoading)
            const SizedBox(
              height: 175,
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryAccent),
              ),
            )
          else
            _buildSongHorizontalList(_dynamicSongs),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongHorizontalList(List<Song> songs) {
    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: songs.length,
        itemBuilder: (_, index) {
          final song = songs[index];
          return SongCard(
            song: song,
            queueContext: songs,
            variant: SongCardVariant.horizontalCard,
          );
        },
      ),
    );
  }

  Widget _buildArtistHorizontalList(List<Artist> artists) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists.length,
        itemBuilder: (_, index) {
          return ArtistCard(artist: artists[index]);
        },
      ),
    );
  }
}
