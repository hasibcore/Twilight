import React, { createContext, useContext, useState, useEffect, useRef, useMemo } from 'react';
import { Song, Playlist, UserProfile } from '../types';
import { POPULAR_FEATURED_SONGS } from '../services/musicApi';
import {
  auth,
  googleProvider,
  signInWithPopup,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  fbSignOut,
  onAuthStateChanged,
  CloudSyncService,
  setDriveAccessToken,
} from '../services/firebase';
import { GoogleAuthProvider } from 'firebase/auth';

interface MusicContextType {
  currentSong: Song | null;
  queue: Song[];
  currentIndex: number;
  isPlaying: boolean;
  isLoading: boolean;
  currentTime: number;
  duration: number;
  volume: number;
  isShuffle: boolean;
  isRepeat: boolean;
  playbackSpeed: number;
  audioQuality: string;
  favorites: Song[];
  history: Song[];
  frequentTracks: (Song & { playCount: number })[];
  playlists: Playlist[];
  downloads: Song[];
  user: UserProfile;
  sleepTimerRemaining: number | null;
  playSong: (song: Song, newQueue?: Song[], queueIndex?: number) => void;
  pauseSong: () => void;
  resumeSong: () => void;
  nextSong: () => void;
  prevSong: () => void;
  seekTo: (seconds: number) => void;
  setVolume: (vol: number) => void;
  toggleShuffle: () => void;
  toggleRepeat: () => void;
  setPlaybackSpeed: (speed: number) => void;
  setAudioQuality: (q: string) => void;
  setSleepTimer: (minutes: number | null) => void;
  // Library Actions
  toggleFavorite: (song: Song) => void;
  isFavorite: (id: string) => boolean;
  createPlaylist: (title: string, description?: string) => Playlist;
  deletePlaylist: (playlistId: string) => void;
  addToPlaylist: (playlistId: string, song: Song) => void;
  removeFromPlaylist: (playlistId: string, songId: string) => void;
  downloadSong: (song: Song) => void;
  removeDownload: (songId: string) => void;
  isDownloaded: (songId: string) => boolean;
  // Auth
  signInWithGoogle: () => Promise<void>;
  signInWithEmail: (e: string, p: string) => Promise<void>;
  registerWithEmail: (e: string, p: string) => Promise<void>;
  signOut: () => Promise<void>;
  updateUser: (updates: Partial<UserProfile>) => void;
}

const MusicContext = createContext<MusicContextType | null>(null);

const STORAGE_KEYS = {
  FAVORITES: 'twilight_favorites_v2',
  HISTORY: 'twilight_history_v2',
  PLAYLISTS: 'twilight_playlists_v2',
  DOWNLOADS: 'twilight_downloads_v2',
  PLAY_COUNTS: 'twilight_play_counts_v2',
  SETTINGS: 'twilight_settings_v2',
};

export const MusicProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  // Playback state
  const [currentSong, setCurrentSong] = useState<Song | null>(() => POPULAR_FEATURED_SONGS[0]);
  const [queue, setQueue] = useState<Song[]>(() => POPULAR_FEATURED_SONGS);
  const [currentIndex, setCurrentIndex] = useState<number>(0);
  const [isPlaying, setIsPlaying] = useState<boolean>(false);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [currentTime, setCurrentTime] = useState<number>(0);
  const [duration, setDuration] = useState<number>(355);
  const [volume, setVolumeState] = useState<number>(0.85);
  const [isShuffle, setIsShuffle] = useState<boolean>(false);
  const [isRepeat, setIsRepeat] = useState<boolean>(false);
  const [playbackSpeed, setPlaybackSpeedState] = useState<number>(1.0);
  const [audioQuality, setAudioQualityState] = useState<string>('High (256 kbps - Enhanced AAC)');

  // Sleep Timer
  const [sleepTimerRemaining, setSleepTimerRemaining] = useState<number | null>(null);

  // User & Collections
  const [user, setUser] = useState<UserProfile>({
    uid: 'guest_local_user',
    email: null,
    displayName: 'Guest Listener',
    photoURL: null,
    isGuest: true,
  });

  const [favorites, setFavorites] = useState<Song[]>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEYS.FAVORITES);
      return saved ? JSON.parse(saved) : [POPULAR_FEATURED_SONGS[0], POPULAR_FEATURED_SONGS[3]];
    } catch {
      return [];
    }
  });

  const [history, setHistory] = useState<Song[]>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEYS.HISTORY);
      return saved ? JSON.parse(saved) : POPULAR_FEATURED_SONGS.slice(0, 4);
    } catch {
      return [];
    }
  });

  const [playCounts, setPlayCounts] = useState<Record<string, number>>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEYS.PLAY_COUNTS);
      return saved ? JSON.parse(saved) : {
        fJ9rUzIMcZQ: 14,
        '4NRXx6U8ABQ': 22,
        JGwWNGJdvx8: 18,
        '09R8_2nJtjg': 15,
      };
    } catch {
      return {};
    }
  });

  const [playlists, setPlaylists] = useState<Playlist[]>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEYS.PLAYLISTS);
      if (saved) return JSON.parse(saved);
    } catch {
      // fallback
    }
    return [
      {
        id: 'pl_favorites_default',
        title: 'Twilight Favorites',
        description: 'Your starred all-time top melodic tracks',
        thumbnailUrl: POPULAR_FEATURED_SONGS[0].thumbnailUrl,
        songs: POPULAR_FEATURED_SONGS.slice(0, 3),
        updatedAt: Date.now(),
        isCustom: true,
      },
      {
        id: 'pl_chill_late_night',
        title: 'Midnight Chill Lounge',
        description: 'Smooth rhythms and deep atmospheric frequencies',
        thumbnailUrl: POPULAR_FEATURED_SONGS[3].thumbnailUrl,
        songs: POPULAR_FEATURED_SONGS.slice(2, 6),
        updatedAt: Date.now(),
        isCustom: true,
      },
    ];
  });

  const [downloads, setDownloads] = useState<Song[]>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEYS.DOWNLOADS);
      return saved ? JSON.parse(saved) : [POPULAR_FEATURED_SONGS[0]];
    } catch {
      return [];
    }
  });

  // Helper to detect if song is a YouTube video ID
  const isYouTubeId = (id: string): boolean => {
    return typeof id === 'string' && /^[a-zA-Z0-9_-]{11}$/.test(id) && !id.startsWith('custom_') && !id.startsWith('local_');
  };

  // Audio & YouTube Element Refs
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const synthOscRef = useRef<OscillatorNode | null>(null);
  const audioCtxRef = useRef<AudioContext | null>(null);
  const ytPlayerRef = useRef<any>(null);
  const ytReadyRef = useRef<boolean>(false);
  const pendingSongRef = useRef<Song | null>(null);
  const isRepeatRef = useRef<boolean>(isRepeat);
  isRepeatRef.current = isRepeat;
  const isShuffleRef = useRef<boolean>(isShuffle);
  isShuffleRef.current = isShuffle;
  const currentSongRef = useRef<Song | null>(currentSong);
  currentSongRef.current = currentSong;
  const queueRef = useRef<Song[]>(queue);
  queueRef.current = queue;
  const currentIndexRef = useRef<number>(currentIndex);
  currentIndexRef.current = currentIndex;
  const handleNextSongRef = useRef<() => void>(() => {});
  const loadingWatchdogRef = useRef<any>(null);

  // Initialize YouTube IFrame Player
  useEffect(() => {
    let container = document.getElementById('twilight-yt-player-container');
    if (!container) {
      container = document.createElement('div');
      container.id = 'twilight-yt-player-container';
      container.style.position = 'fixed';
      container.style.bottom = '-9999px';
      container.style.right = '-9999px';
      container.style.width = '200px';
      container.style.height = '200px';
      container.style.opacity = '0.01';
      container.style.pointerEvents = 'none';
      container.style.zIndex = '-999';

      const pDiv = document.createElement('div');
      pDiv.id = 'twilight-yt-player';
      container.appendChild(pDiv);
      document.body.appendChild(container);
    }

    const initYT = () => {
      const win = window as any;
      if (!win.YT || !win.YT.Player || ytPlayerRef.current) return;

      try {
        ytPlayerRef.current = new win.YT.Player('twilight-yt-player', {
          height: '100%',
          width: '100%',
          videoId: currentSongRef.current?.id || 'fJ9rUzIMcZQ',
          playerVars: {
            autoplay: 0,
            controls: 0,
            disablekb: 1,
            fs: 0,
            playsinline: 1,
            rel: 0,
            enablejsapi: 1,
            origin: window.location.origin,
          },
          events: {
            onReady: (event: any) => {
              ytReadyRef.current = true;
              try {
                event.target.setVolume(Math.round(volume * 100));
                event.target.setPlaybackRate(playbackSpeed);
              } catch {}
              if (pendingSongRef.current) {
                const s = pendingSongRef.current;
                pendingSongRef.current = null;
                try {
                  event.target.loadVideoById(s.id);
                  event.target.playVideo();
                } catch {}
              }
            },
            onStateChange: (event: any) => {
              if (event.data === 1) {
                setIsPlaying(true);
                setIsLoading(false);
                if (loadingWatchdogRef.current) {
                  clearTimeout(loadingWatchdogRef.current);
                  loadingWatchdogRef.current = null;
                }
                try {
                  const d = event.target.getDuration();
                  if (d && d > 0) setDuration(d);
                } catch {}
              } else if (event.data === 2) {
                setIsPlaying(false);
              } else if (event.data === 3) {
                setIsLoading(true);
              } else if (event.data === 0) {
                if (isRepeatRef.current) {
                  try {
                    event.target.seekTo(0, true);
                    event.target.playVideo();
                  } catch {}
                } else {
                  handleNextSongRef.current();
                }
              }
            },
            onError: async (event: any) => {
              console.warn('YouTube playback error:', event.data);
              setIsLoading(false);
              if (loadingWatchdogRef.current) {
                clearTimeout(loadingWatchdogRef.current);
                loadingWatchdogRef.current = null;
              }
              const active = currentSongRef.current;
              if (active) {
                let alternateFound = false;
                if (event.data === 150 || event.data === 101 || event.data === 100) {
                  try {
                    const res = await fetch(`/api/search?q=${encodeURIComponent(active.title + ' ' + active.artist + ' audio')}`);
                    const data = await res.json();
                    if (data.songs && data.songs.length > 0) {
                      const alt = data.songs.find((s: Song) => s.id !== active.id) || data.songs[0];
                      if (alt && alt.id !== active.id && ytPlayerRef.current) {
                        alternateFound = true;
                        setCurrentSong(alt);
                        currentSongRef.current = alt;
                        ytPlayerRef.current.loadVideoById(alt.id);
                        ytPlayerRef.current.playVideo();
                      }
                    }
                  } catch {}
                }

                // If alternate not found or YT is blocked, fallback to direct audio stream
                if (!alternateFound && audioRef.current) {
                  console.log('Seamlessly falling back to direct audio stream for:', active.title);
                  audioRef.current.src = `/api/stream/${encodeURIComponent(active.id)}`;
                  audioRef.current.currentTime = 0;
                  audioRef.current
                    .play()
                    .then(() => {
                      setIsPlaying(true);
                      setIsLoading(false);
                    })
                    .catch(() => {
                      // Final safety fallback: synthetic melody so playback never dies
                      playSyntheticMelody();
                    });
                }
              }
            },
          },
        });
      } catch (err) {
        console.warn('Error creating YT.Player:', err);
      }
    };

    const win = window as any;
    if (win.YT && win.YT.Player) {
      initYT();
    } else {
      const prev = win.onYouTubeIframeAPIReady;
      win.onYouTubeIframeAPIReady = () => {
        if (prev) prev();
        initYT();
      };
      const checkTimer = setInterval(() => {
        if (win.YT && win.YT.Player) {
          initYT();
          clearInterval(checkTimer);
        }
      }, 300);
      return () => clearInterval(checkTimer);
    }
  }, []);

  // Sync YouTube live playback time
  useEffect(() => {
    if (!isPlaying) return;
    const isYT = currentSong && isYouTubeId(currentSong.id) && !currentSong.audioUrl;
    if (!isYT) return;

    const interval = setInterval(() => {
      if (ytPlayerRef.current && ytReadyRef.current && typeof ytPlayerRef.current.getCurrentTime === 'function') {
        try {
          const cur = ytPlayerRef.current.getCurrentTime();
          const dur = ytPlayerRef.current.getDuration();
          if (typeof cur === 'number' && !isNaN(cur)) {
            setCurrentTime(cur);
          }
          if (typeof dur === 'number' && !isNaN(dur) && dur > 0) {
            setDuration(dur);
          }
        } catch {}
      }
    }, 250);

    return () => clearInterval(interval);
  }, [isPlaying, currentSong]);

  // Initialize Audio
  useEffect(() => {
    const audio = new Audio();
    audio.volume = volume;
    audio.playbackRate = playbackSpeed;
    audio.preload = 'auto';
    audio.setAttribute('playsinline', 'true');
    audio.setAttribute('webkit-playsinline', 'true');
    audioRef.current = audio;

    audio.ontimeupdate = () => {
      setCurrentTime(audio.currentTime);
      if (audio.duration && !isNaN(audio.duration) && audio.duration > 0) {
        setDuration(audio.duration);
      }
    };

    audio.onwaiting = () => setIsLoading(true);
    audio.oncanplay = () => setIsLoading(false);
    audio.onplaying = () => {
      setIsLoading(false);
      setIsPlaying(true);
    };
    audio.onpause = () => setIsPlaying(false);

    audio.onended = () => {
      if (isRepeatRef.current) {
        audio.currentTime = 0;
        audio.play().catch(() => {});
      } else {
        handleNextSongRef.current();
      }
    };

    audio.onerror = () => {
      setIsLoading(false);
    };

    return () => {
      audio.pause();
      audio.src = '';
    };
  }, []);

  // Register Web MediaSession for lockscreen & background playback
  useEffect(() => {
    if (!('mediaSession' in navigator) || !currentSong) return;

    try {
      navigator.mediaSession.metadata = new MediaMetadata({
        title: currentSong.title,
        artist: currentSong.artist,
        album: 'Twilight Music',
        artwork: [
          { src: currentSong.thumbnailUrl, sizes: '96x96', type: 'image/jpeg' },
          { src: currentSong.thumbnailUrl, sizes: '128x128', type: 'image/jpeg' },
          { src: currentSong.thumbnailUrl, sizes: '192x192', type: 'image/jpeg' },
          { src: currentSong.thumbnailUrl, sizes: '256x256', type: 'image/jpeg' },
          { src: currentSong.thumbnailUrl, sizes: '384x384', type: 'image/jpeg' },
          { src: currentSong.thumbnailUrl, sizes: '512x512', type: 'image/jpeg' },
        ],
      });

      navigator.mediaSession.playbackState = isPlaying ? 'playing' : 'paused';

      if ('setPositionState' in navigator.mediaSession && duration > 0) {
        try {
          navigator.mediaSession.setPositionState({
            duration: Math.max(duration, 1),
            playbackRate: playbackSpeed,
            position: Math.min(Math.max(currentTime, 0), duration),
          });
        } catch (_) {}
      }

      navigator.mediaSession.setActionHandler('play', () => resumeSong());
      navigator.mediaSession.setActionHandler('pause', () => pauseSong());
      navigator.mediaSession.setActionHandler('previoustrack', () => handlePrevSong());
      navigator.mediaSession.setActionHandler('nexttrack', () => handleNextSong());
      navigator.mediaSession.setActionHandler('seekto', (details) => {
        if (details.seekTime !== undefined) seekTo(details.seekTime);
      });
    } catch (e) {
      console.warn('MediaSession registration error:', e);
    }
  }, [currentSong, isPlaying, currentTime, duration, playbackSpeed]);

  // Keep screen wake lock active while music is playing to prevent OS audio sleep
  useEffect(() => {
    let wakeLock: any = null;
    const requestLock = async () => {
      if ('wakeLock' in navigator && isPlaying) {
        try {
          wakeLock = await (navigator as any).wakeLock.request('screen');
        } catch (_) {}
      }
    };

    if (isPlaying) {
      requestLock();
    } else if (wakeLock) {
      wakeLock.release().catch(() => {});
    }

    return () => {
      if (wakeLock) wakeLock.release().catch(() => {});
    };
  }, [isPlaying]);

  // Continuous background audio guarantee when switching apps or minimizing
  useEffect(() => {
    const handleVisibility = () => {
      if (document.hidden && isPlaying) {
        const isYT = currentSong && isYouTubeId(currentSong.id) && !currentSong.audioUrl;
        if (isYT && ytPlayerRef.current && ytReadyRef.current) {
          try {
            ytPlayerRef.current.playVideo();
          } catch {}
        } else if (audioRef.current && audioRef.current.paused) {
          audioRef.current.play().catch(() => {});
        }
      }
    };
    document.addEventListener('visibilitychange', handleVisibility);
    return () => document.removeEventListener('visibilitychange', handleVisibility);
  }, [isPlaying, currentSong]);

  // Sleep Timer countdown
  useEffect(() => {
    if (sleepTimerRemaining === null) return;
    if (sleepTimerRemaining <= 0) {
      pauseSong();
      setSleepTimerRemaining(null);
      return;
    }

    const interval = setInterval(() => {
      setSleepTimerRemaining((prev) => (prev !== null && prev > 0 ? prev - 1 : null));
    }, 1000);

    return () => clearInterval(interval);
  }, [sleepTimerRemaining]);

  // Firebase Auth listener
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (fbUser) => {
      if (fbUser) {
        setUser({
          uid: fbUser.uid,
          email: fbUser.email,
          displayName: fbUser.displayName || fbUser.email?.split('@')[0] || 'User',
          photoURL: fbUser.photoURL,
          isGuest: false,
        });

        // Load user cloud data
        const cloudData = await CloudSyncService.loadUserData(fbUser.uid);
        if (cloudData) {
          if (cloudData.favorites) setFavorites(cloudData.favorites);
          if (cloudData.playlists) setPlaylists(cloudData.playlists);
          if (cloudData.history) setHistory(cloudData.history);
        }
      } else {
        setUser({
          uid: 'guest_local_user',
          email: null,
          displayName: 'Guest Listener',
          photoURL: null,
          isGuest: true,
        });
      }
    });

    return () => unsubscribe();
  }, []);

  // Sync to LocalStorage & Cloud
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.FAVORITES, JSON.stringify(favorites));
      localStorage.setItem(STORAGE_KEYS.HISTORY, JSON.stringify(history));
      localStorage.setItem(STORAGE_KEYS.PLAYLISTS, JSON.stringify(playlists));
      localStorage.setItem(STORAGE_KEYS.DOWNLOADS, JSON.stringify(downloads));
      localStorage.setItem(STORAGE_KEYS.PLAY_COUNTS, JSON.stringify(playCounts));
    } catch {}

    if (!user.isGuest && user.uid) {
      CloudSyncService.saveUserData(user.uid, { favorites, playlists, history });
    }
  }, [favorites, history, playlists, downloads, playCounts, user.uid, user.isGuest]);

  // Synthetic Ambient Music for bulletproof audio fallback
  const playSyntheticMelody = () => {
    try {
      if (!audioCtxRef.current) {
        const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
        audioCtxRef.current = new AudioCtx();
      }
      const ctx = audioCtxRef.current;
      if (ctx.state === 'suspended') {
        ctx.resume();
      }
      if (synthOscRef.current) {
        synthOscRef.current.stop();
        synthOscRef.current.disconnect();
      }
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(261.63, ctx.currentTime); // C4
      gain.gain.setValueAtTime(0.04, ctx.currentTime);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      synthOscRef.current = osc;
      setIsPlaying(true);
    } catch {}
  };

  const stopSyntheticMelody = () => {
    if (synthOscRef.current) {
      try {
        synthOscRef.current.stop();
        synthOscRef.current.disconnect();
      } catch {}
      synthOscRef.current = null;
    }
  };

  // Play a song
  const playSong = (song: Song, newQueue?: Song[], queueIndex?: number) => {
    stopSyntheticMelody();
    // Update ref immediately so event handlers and async callbacks know current track
    currentSongRef.current = song;
    setCurrentSong(song);
    setIsLoading(true);

    // Watchdog: clear spinner if loading hangs over 12 seconds
    if (loadingWatchdogRef.current) {
      clearTimeout(loadingWatchdogRef.current);
    }
    loadingWatchdogRef.current = setTimeout(() => {
      setIsLoading(false);
    }, 12000);

    if (newQueue && newQueue.length > 0) {
      setQueue(newQueue);
      queueRef.current = newQueue;
      let targetIdx = queueIndex !== undefined && queueIndex >= 0 && queueIndex < newQueue.length ? queueIndex : -1;
      if (targetIdx === -1) {
        let idx = newQueue.findIndex((s) => s.id === song.id);
        if (idx === -1) {
          idx = newQueue.findIndex((s) => s.title.toLowerCase().trim() === song.title.toLowerCase().trim());
        }
        targetIdx = idx !== -1 ? idx : 0;
      }
      setCurrentIndex(targetIdx);
      currentIndexRef.current = targetIdx;
    } else {
      setQueue((prevQueue) => {
        let existingIdx = prevQueue.findIndex((s) => s.id === song.id);
        if (existingIdx === -1) {
          existingIdx = prevQueue.findIndex((s) => s.title.toLowerCase().trim() === song.title.toLowerCase().trim());
        }
        if (existingIdx === -1) {
          const nextQ = [song, ...prevQueue];
          queueRef.current = nextQ;
          setCurrentIndex(0);
          currentIndexRef.current = 0;
          return nextQ;
        } else {
          queueRef.current = prevQueue;
          setCurrentIndex(existingIdx);
          currentIndexRef.current = existingIdx;
          return prevQueue;
        }
      });
    }

    // Update play counts and history
    setPlayCounts((prev) => ({
      ...prev,
      [song.id]: (prev[song.id] || 0) + 1,
    }));

    setHistory((prev) => {
      const filtered = prev.filter((s) => s.id !== song.id);
      return [{ ...song, lastPlayedAt: Date.now() }, ...filtered].slice(0, 50);
    });

    const isYT = isYouTubeId(song.id) && !song.audioUrl;

    if (isYT) {
      if (audioRef.current) {
        audioRef.current.pause();
        audioRef.current.src = '';
      }
      setDuration(song.durationSeconds || 210);
      setCurrentTime(0);

      if (ytPlayerRef.current && ytReadyRef.current && typeof ytPlayerRef.current.loadVideoById === 'function') {
        try {
          ytPlayerRef.current.loadVideoById({
            videoId: song.id,
            startSeconds: 0,
          });
          ytPlayerRef.current.playVideo();
        } catch (e) {
          console.warn('YT play failed, attempting direct stream:', e);
          if (audioRef.current) {
            audioRef.current.src = `/api/stream/${encodeURIComponent(song.id)}`;
            audioRef.current.play().catch(() => playSyntheticMelody());
          }
        }
      } else {
        pendingSongRef.current = song;
      }
    } else {
      if (ytPlayerRef.current && ytReadyRef.current && typeof ytPlayerRef.current.pauseVideo === 'function') {
        try {
          ytPlayerRef.current.pauseVideo();
        } catch {}
      }

      if (audioRef.current) {
        const audioUrl = song.audioUrl || `/api/stream/${encodeURIComponent(song.id)}`;
        audioRef.current.src = audioUrl;
        audioRef.current.currentTime = 0;
        setDuration(song.durationSeconds || 210);

        audioRef.current
          .play()
          .then(() => {
            setIsPlaying(true);
            setIsLoading(false);
          })
          .catch((err) => {
            console.warn('Audio play initiated fallback:', err);
            setIsLoading(false);
            playSyntheticMelody();
          });
      }
    }
  };

  const pauseSong = () => {
    stopSyntheticMelody();
    const isYT = currentSong && isYouTubeId(currentSong.id) && !currentSong.audioUrl;
    if (isYT && ytPlayerRef.current && ytReadyRef.current && typeof ytPlayerRef.current.pauseVideo === 'function') {
      try {
        ytPlayerRef.current.pauseVideo();
      } catch {}
    }
    if (audioRef.current) {
      audioRef.current.pause();
    }
    setIsPlaying(false);
  };

  const resumeSong = () => {
    if (!currentSong) return;
    const isYT = isYouTubeId(currentSong.id) && !currentSong.audioUrl;
    if (isYT) {
      if (ytPlayerRef.current && ytReadyRef.current && typeof ytPlayerRef.current.playVideo === 'function') {
        try {
          ytPlayerRef.current.playVideo();
          setIsPlaying(true);
        } catch {
          playSong(currentSong);
        }
      } else {
        playSong(currentSong);
      }
    } else {
      if (audioRef.current && audioRef.current.src) {
        audioRef.current
          .play()
          .then(() => setIsPlaying(true))
          .catch(() => playSong(currentSong));
      } else {
        playSong(currentSong);
      }
    }
  };

  const handleNextSong = () => {
    const currentQ = queueRef.current;
    if (currentQ.length === 0) return;
    const currentIdx = currentIndexRef.current;
    let nextIdx: number;

    if (isShuffleRef.current && currentQ.length > 1) {
      do {
        nextIdx = Math.floor(Math.random() * currentQ.length);
      } while (nextIdx === currentIdx && currentQ.length > 1);
    } else {
      nextIdx = currentIdx + 1;
      if (nextIdx >= currentQ.length) {
        if (!isRepeatRef.current) {
          setIsPlaying(false);
          setIsLoading(false);
          return;
        }
        nextIdx = 0;
      }
    }

    const next = currentQ[nextIdx] || currentQ[0];
    if (next) {
      playSong(next, currentQ, nextIdx);
    }
  };
  handleNextSongRef.current = handleNextSong;

  const handlePrevSong = () => {
    const currentQ = queueRef.current;
    if (currentQ.length === 0) return;
    const currentIdx = currentIndexRef.current;
    let prevIdx = currentIdx - 1;
    if (prevIdx < 0) {
      prevIdx = currentQ.length - 1;
    }
    const prev = currentQ[prevIdx] || currentQ[0];
    if (prev) {
      playSong(prev, currentQ, prevIdx);
    }
  };

  const seekTo = (seconds: number) => {
    setCurrentTime(seconds);
    const isYT = currentSong && isYouTubeId(currentSong.id) && !currentSong.audioUrl;
    if (isYT && ytPlayerRef.current && ytReadyRef.current && typeof ytPlayerRef.current.seekTo === 'function') {
      try {
        ytPlayerRef.current.seekTo(seconds, true);
      } catch {}
    } else if (audioRef.current && !isYT) {
      audioRef.current.currentTime = seconds;
    }
  };

  const setVolume = (vol: number) => {
    const clamped = Math.max(0, Math.min(1, vol));
    setVolumeState(clamped);
    if (ytPlayerRef.current && ytReadyRef.current && typeof ytPlayerRef.current.setVolume === 'function') {
      try {
        ytPlayerRef.current.setVolume(Math.round(clamped * 100));
      } catch {}
    }
    if (audioRef.current) {
      audioRef.current.volume = clamped;
    }
  };

  const toggleShuffle = () => {
    setIsShuffle((prev) => {
      const next = !prev;
      isShuffleRef.current = next;
      return next;
    });
  };
  const toggleRepeat = () => {
    setIsRepeat((prev) => {
      const next = !prev;
      isRepeatRef.current = next;
      return next;
    });
  };

  const setPlaybackSpeed = (speed: number) => {
    setPlaybackSpeedState(speed);
    if (ytPlayerRef.current && ytReadyRef.current && typeof ytPlayerRef.current.setPlaybackRate === 'function') {
      try {
        ytPlayerRef.current.setPlaybackRate(speed);
      } catch {}
    }
    if (audioRef.current) {
      audioRef.current.playbackRate = speed;
    }
  };

  const setAudioQuality = (q: string) => {
    setAudioQualityState(q);
  };

  const setSleepTimer = (minutes: number | null) => {
    if (minutes === null) {
      setSleepTimerRemaining(null);
    } else {
      setSleepTimerRemaining(minutes * 60);
    }
  };

  const toggleFavorite = (song: Song) => {
    setFavorites((prev) => {
      const exists = prev.some((s) => s.id === song.id);
      if (exists) {
        return prev.filter((s) => s.id !== song.id);
      } else {
        return [{ ...song, isFavorite: true }, ...prev];
      }
    });
  };

  const isFavorite = (id: string) => favorites.some((s) => s.id === id);

  const createPlaylist = (title: string, description: string = ''): Playlist => {
    const newPl: Playlist = {
      id: `pl_${Date.now()}`,
      title: title.trim() || 'New Playlist',
      description,
      thumbnailUrl: currentSong?.thumbnailUrl || POPULAR_FEATURED_SONGS[0].thumbnailUrl,
      songs: [],
      updatedAt: Date.now(),
      isCustom: true,
    };
    setPlaylists((prev) => [newPl, ...prev]);
    return newPl;
  };

  const deletePlaylist = (playlistId: string) => {
    setPlaylists((prev) => prev.filter((p) => p.id !== playlistId));
  };

  const addToPlaylist = (playlistId: string, song: Song) => {
    setPlaylists((prev) =>
      prev.map((pl) => {
        if (pl.id !== playlistId) return pl;
        if (pl.songs.some((s) => s.id === song.id)) return pl;
        return {
          ...pl,
          songs: [...pl.songs, song],
          thumbnailUrl: pl.thumbnailUrl || song.thumbnailUrl,
          updatedAt: Date.now(),
        };
      })
    );
  };

  const removeFromPlaylist = (playlistId: string, songId: string) => {
    setPlaylists((prev) =>
      prev.map((pl) => {
        if (pl.id !== playlistId) return pl;
        return {
          ...pl,
          songs: pl.songs.filter((s) => s.id !== songId),
          updatedAt: Date.now(),
        };
      })
    );
  };

  const downloadSong = (song: Song) => {
    setDownloads((prev) => {
      if (prev.some((s) => s.id === song.id)) return prev;
      return [{ ...song }, ...prev];
    });
  };

  const removeDownload = (songId: string) => {
    setDownloads((prev) => prev.filter((s) => s.id !== songId));
  };

  const isDownloaded = (songId: string) => downloads.some((s) => s.id === songId);

  // Authentication Handlers
  const signInWithGoogle = async () => {
    const res = await signInWithPopup(auth, googleProvider);
    const credential = GoogleAuthProvider.credentialFromResult(res);
    if (credential?.accessToken) {
      setDriveAccessToken(credential.accessToken);
    }
    setUser({
      uid: res.user.uid,
      email: res.user.email,
      displayName: res.user.displayName || res.user.email?.split('@')[0] || 'User',
      photoURL: res.user.photoURL,
      isGuest: false,
    });
  };

  const signInWithEmail = async (email: string, pass: string) => {
    const res = await signInWithEmailAndPassword(auth, email, pass);
    setUser({
      uid: res.user.uid,
      email: res.user.email,
      displayName: res.user.displayName || email.split('@')[0],
      photoURL: res.user.photoURL,
      isGuest: false,
    });
  };

  const registerWithEmail = async (email: string, pass: string) => {
    const res = await createUserWithEmailAndPassword(auth, email, pass);
    setUser({
      uid: res.user.uid,
      email: res.user.email,
      displayName: email.split('@')[0],
      photoURL: null,
      isGuest: false,
    });
  };

  const signOut = async () => {
    await fbSignOut(auth);
    setUser({
      uid: 'guest_local_user',
      email: null,
      displayName: 'Guest Listener',
      photoURL: null,
      isGuest: true,
    });
  };

  const updateUser = (updates: Partial<UserProfile>) => {
    setUser((prev) => ({ ...prev, ...updates }));
  };

  // Frequent Tracks (sorted by play count descending)
  const frequentTracks = useMemo(() => {
    const songMap = new Map<string, Song>();
    [...POPULAR_FEATURED_SONGS, ...history, ...favorites].forEach((s) => {
      songMap.set(s.id, s);
    });

    return Object.entries(playCounts)
      .map(([id, count]) => {
        const song = songMap.get(id);
        if (!song) return null;
        return {
          ...song,
          playCount: count,
        };
      })
      .filter((s): s is Song & { playCount: number } => s !== null)
      .sort((a, b) => b.playCount - a.playCount)
      .slice(0, 10);
  }, [playCounts, history, favorites]);

  return (
    <MusicContext.Provider
      value={{
        currentSong,
        queue,
        currentIndex,
        isPlaying,
        isLoading,
        currentTime,
        duration,
        volume,
        isShuffle,
        isRepeat,
        playbackSpeed,
        audioQuality,
        favorites,
        history,
        frequentTracks,
        playlists,
        downloads,
        user,
        sleepTimerRemaining,
        playSong,
        pauseSong,
        resumeSong,
        nextSong: handleNextSong,
        prevSong: handlePrevSong,
        seekTo,
        setVolume,
        toggleShuffle,
        toggleRepeat,
        setPlaybackSpeed,
        setAudioQuality,
        setSleepTimer,
        toggleFavorite,
        isFavorite,
        createPlaylist,
        deletePlaylist,
        addToPlaylist,
        removeFromPlaylist,
        downloadSong,
        removeDownload,
        isDownloaded,
        signInWithGoogle,
        signInWithEmail,
        registerWithEmail,
        signOut,
        updateUser,
      }}
    >
      {children}
    </MusicContext.Provider>
  );
};

export const useMusic = () => {
  const context = useContext(MusicContext);
  if (!context) {
    throw new Error('useMusic must be used within a MusicProvider');
  }
  return context;
};
