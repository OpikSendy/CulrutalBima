// lib/views/screens/budaya_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../data/models/budaya_model.dart';
import '../../core/constants/app_strings.dart';

// ─── Model sederhana untuk media ─────────────────────────────────
class BudayaMedia {
  final String id;
  final String jenisMedia; // 'gambar', 'video', 'audio'
  final String urlMedia;
  final String? judul;
  final int urutan;

  BudayaMedia({
    required this.id,
    required this.jenisMedia,
    required this.urlMedia,
    this.judul,
    required this.urutan,
  });

  factory BudayaMedia.fromMap(Map<String, dynamic> map) {
    return BudayaMedia(
      id: map['id'] as String,
      jenisMedia: map['jenis_media'] as String,
      urlMedia: map['url_media'] as String,
      judul: map['judul'] as String?,
      urutan: (map['urutan'] as int?) ?? 0,
    );
  }
}

// ─── Main Screen ──────────────────────────────────────────────────
class BudayaDetailScreen extends StatefulWidget {
  final BudayaModel budaya;

  const BudayaDetailScreen({
    super.key,
    required this.budaya,
  });

  @override
  State<BudayaDetailScreen> createState() => _BudayaDetailScreenState();
}

class _BudayaDetailScreenState extends State<BudayaDetailScreen> {
  // ─── Media state ────────────────────────────────────────────────
  List<BudayaMedia> _mediaGambar = [];
  List<BudayaMedia> _mediaVideo  = [];
  List<BudayaMedia> _mediaAudio  = [];
  bool _mediaLoading = true;
  String? _mediaError;

  // ─── Video player ────────────────────────────────────────────────
  VideoPlayerController? _videoController;
  String? _activeVideoUrl;
  bool _videoInitializing = false;

  // ─── Audio player ────────────────────────────────────────────────
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _activeAudioId;
  PlayerState _audioState = PlayerState.stopped;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _fetchMedia();
    _setupAudioListeners();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ─── Setup audio listeners ───────────────────────────────────────
  void _setupAudioListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _audioState = state);
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _audioDuration = duration);
    });
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _audioPosition = position);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _audioState = PlayerState.stopped;
          _audioPosition = Duration.zero;
          _activeAudioId = null;
        });
      }
    });
  }

  // ─── Fetch media dari Supabase ───────────────────────────────────
  Future<void> _fetchMedia() async {
    setState(() { _mediaLoading = true; _mediaError = null; });
    try {
      final response = await Supabase.instance.client
          .from('budaya_media')
          .select()
          .eq('budaya_id', widget.budaya.id)
          .order('urutan')
          .order('created_at');

      final all = (response as List)
          .map((e) => BudayaMedia.fromMap(e as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _mediaGambar = all.where((m) => m.jenisMedia == 'gambar').toList();
          _mediaVideo  = all.where((m) => m.jenisMedia == 'video').toList();
          _mediaAudio  = all.where((m) => m.jenisMedia == 'audio').toList();
          _mediaLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mediaError = e.toString();
          _mediaLoading = false;
        });
      }
    }
  }

  // ─── Video player controls ───────────────────────────────────────
  Future<void> _playVideo(String url) async {
    if (_activeVideoUrl == url) {
      // Toggle play/pause
      if (_videoController?.value.isPlaying ?? false) {
        await _videoController?.pause();
      } else {
        await _videoController?.play();
      }
      setState(() {});
      return;
    }

    // Stop audio jika sedang main
    await _audioPlayer.stop();
    setState(() { _activeAudioId = null; });

    setState(() {
      _videoInitializing = true;
      _activeVideoUrl = url;
    });

    await _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      await _videoController!.initialize();
      await _videoController!.play();
      _videoController!.addListener(() {
        if (mounted) setState(() {});
      });
    } catch (_) {
      // error handled di UI
    } finally {
      if (mounted) setState(() => _videoInitializing = false);
    }
  }

  // ─── Audio player controls ───────────────────────────────────────
  Future<void> _toggleAudio(BudayaMedia audio) async {
    // Stop video jika sedang main
    if (_videoController?.value.isPlaying ?? false) {
      await _videoController?.pause();
      setState(() {});
    }

    if (_activeAudioId == audio.id) {
      // Toggle play/pause audio yang sama
      if (_audioState == PlayerState.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } else {
      // Play audio baru
      await _audioPlayer.stop();
      setState(() {
        _activeAudioId = audio.id;
        _audioPosition = Duration.zero;
      });
      await _audioPlayer.play(UrlSource(audio.urlMedia));
    }
  }

  Future<void> _seekAudio(double value) async {
    final position = Duration(milliseconds: value.toInt());
    await _audioPlayer.seek(position);
  }

  // ─── Share content ───────────────────────────────────────────────
  void _shareContent() {
    final text = '✨ ${widget.budaya.nama}\n'
        '📂 Kategori: ${widget.budaya.kategori}\n'
        '${widget.budaya.asalDaerah != null ? '📍 Asal Daerah: ${widget.budaya.asalDaerah}\n' : ''}'
        '\n${widget.budaya.deskripsi ?? ''}\n\n'
        '— Dibagikan dari Aplikasi Cultural Bima';
    Share.share(text, subject: widget.budaya.nama);
  }

  // ─── Format durasi ───────────────────────────────────────────────
  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1),
                ),
                _buildDeskripsiSection(),

                // ─── MULTIMEDIA SECTION ─────────────────────────
                _buildMultimediaSection(),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: _buildInfoCard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sliver AppBar ───────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: const Color(0xFF4A7C59),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
          ),
          onPressed: _shareContent,
          tooltip: 'Bagikan',
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.budaya.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFF5F5F0),
                child: const Icon(Icons.image_not_supported,
                    size: 80, color: Color(0xFF8A998B)),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: const Color(0xFFF0EDE6),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                      color: const Color(0xFF4A7C59),
                    ),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.75),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 20, left: 20, right: 20,
              child: Text(
                widget.budaya.nama,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  shadows: [Shadow(offset: Offset(0, 1),
                      blurRadius: 4, color: Colors.black45)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header Section ──────────────────────────────────────────────
  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildInfoChip(icon: Icons.category_rounded,
              label: widget.budaya.kategori,
              color: const Color(0xFF4A7C59)),
          if (widget.budaya.asalDaerah != null)
            _buildInfoChip(icon: Icons.location_on_rounded,
                label: widget.budaya.asalDaerah!,
                color: const Color(0xFF8B6F47)),
          _buildInfoChip(icon: Icons.calendar_today_rounded,
              label: _formatDate(widget.budaya.createdAt),
              color: const Color(0xFF6B8CAE)),
        ],
      ),
    );
  }

  // ─── Deskripsi Section ───────────────────────────────────────────
  Widget _buildDeskripsiSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(AppStrings.detailDeskripsi),
          const SizedBox(height: 16),
          if (widget.budaya.deskripsi != null &&
              widget.budaya.deskripsi!.isNotEmpty)
            Text(
              widget.budaya.deskripsi!,
              style: const TextStyle(
                color: Color(0xFF3D4F3E),
                height: 1.9,
                fontSize: 15.5,
                letterSpacing: 0.15,
              ),
              textAlign: TextAlign.justify,
            )
          else
            _buildEmptyText('Deskripsi tidak tersedia'),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // MULTIMEDIA SECTION
  // ════════════════════════════════════════════════════════════════
  Widget _buildMultimediaSection() {
    // Loading state
    if (_mediaLoading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Multimedia'),
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A7C59)),
            ),
          ],
        ),
      );
    }

    // Tidak ada media sama sekali
    final hasAnyMedia = _mediaGambar.isNotEmpty ||
        _mediaVideo.isNotEmpty ||
        _mediaAudio.isNotEmpty;

    if (!hasAnyMedia) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _buildSectionTitle('Multimedia'),
          ),

          // Gallery foto tambahan
          if (_mediaGambar.isNotEmpty) _buildGallerySection(),

          // Video section
          if (_mediaVideo.isNotEmpty) _buildVideoSection(),

          // Audio section
          if (_mediaAudio.isNotEmpty) _buildAudioSection(),
        ],
      ),
    );
  }

  // ─── Gallery Foto ────────────────────────────────────────────────
  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            children: [
              const Icon(Icons.photo_library_rounded,
                  size: 16, color: Color(0xFF4A7C59)),
              const SizedBox(width: 6),
              Text(
                'Galeri Foto (${_mediaGambar.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E2D),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 8),
            itemCount: _mediaGambar.length,
            itemBuilder: (context, index) {
              final media = _mediaGambar[index];
              return GestureDetector(
                onTap: () => _showImageFullscreen(media.urlMedia,
                    media.judul ?? 'Foto ${index + 1}'),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12, bottom: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          media.urlMedia,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: const Color(0xFFF0EDE6),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF4A7C59),
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF0EDE6),
                            child: const Icon(Icons.broken_image,
                                color: Color(0xFF8A998B)),
                          ),
                        ),
                        // Overlay gradient + judul
                        if (media.judul != null)
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.65),
                                  ],
                                ),
                              ),
                              child: Text(
                                media.judul!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        // Icon expand
                        Positioned(
                          top: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.fullscreen,
                                color: Colors.white, size: 14),
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
        const SizedBox(height: 20),
      ],
    );
  }

  // ─── Video Section ───────────────────────────────────────────────
  Widget _buildVideoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.videocam_rounded,
                  size: 16, color: Color(0xFF4A7C59)),
              const SizedBox(width: 6),
              Text(
                'Video (${_mediaVideo.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E2D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._mediaVideo.map((video) => _buildVideoCard(video)),
        ],
      ),
    );
  }

  Widget _buildVideoCard(BudayaMedia video) {
    final isActive = _activeVideoUrl == video.urlMedia;
    final isInitializing = isActive && _videoInitializing;
    final isPlaying = isActive &&
        (_videoController?.value.isPlaying ?? false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Video preview / player
            AspectRatio(
              aspectRatio: isActive &&
                      (_videoController?.value.isInitialized ?? false)
                  ? _videoController!.value.aspectRatio
                  : 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video player atau thumbnail placeholder
                  if (isActive &&
                      (_videoController?.value.isInitialized ?? false))
                    VideoPlayer(_videoController!)
                  else
                    Container(
                      color: const Color(0xFF1A1A2E),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 52,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            video.judul ?? 'Video',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Loading indicator
                  if (isInitializing)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white),
                      ),
                    ),

                  // Play/pause overlay
                  GestureDetector(
                    onTap: () => _playVideo(video.urlMedia),
                    child: Container(
                      color: Colors.transparent,
                      child: isActive &&
                              (_videoController?.value.isInitialized ?? false) &&
                              !isPlaying
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow,
                                    color: Colors.white, size: 32),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // Control bar
            if (isActive &&
                (_videoController?.value.isInitialized ?? false))
              Container(
                color: const Color(0xFF1A1A2E),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _playVideo(video.urlMedia),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: VideoProgressIndicator(
                        _videoController!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Color(0xFF4A7C59),
                          bufferedColor: Colors.white24,
                          backgroundColor: Colors.white12,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(
                          _videoController!.value.position),
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),

            // Label judul
            if (video.judul != null && !isActive)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                color: const Color(0xFF1A1A2E),
                child: Text(
                  video.judul!,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Audio Section ───────────────────────────────────────────────
  Widget _buildAudioSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.music_note_rounded,
                  size: 16, color: Color(0xFF4A7C59)),
              const SizedBox(width: 6),
              Text(
                'Audio (${_mediaAudio.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E2D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._mediaAudio.map((audio) => _buildAudioCard(audio)),
        ],
      ),
    );
  }

  Widget _buildAudioCard(BudayaMedia audio) {
    final isActive = _activeAudioId == audio.id;
    final isPlaying = isActive && _audioState == PlayerState.playing;
    final totalMs = _audioDuration.inMilliseconds.toDouble();
    final currentMs = isActive
        ? _audioPosition.inMilliseconds.toDouble().clamp(0.0,
            totalMs > 0 ? totalMs : 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF4A7C59).withOpacity(0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? const Color(0xFF4A7C59).withOpacity(0.4)
              : const Color(0xFF4A7C59).withOpacity(0.15),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Play/pause button
          GestureDetector(
            onTap: () => _toggleAudio(audio),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF4A7C59),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A7C59).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info + progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  audio.judul ?? 'Audio Tradisional',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? const Color(0xFF2C3E2D)
                        : const Color(0xFF5A6C5B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Slider progress
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbSize: isActive
                        ? const WidgetStatePropertyAll(Size(12, 12))
                        : const WidgetStatePropertyAll(Size(0, 0)),
                    // overlayColor: WidgetStatePropertyAll(
                    //     const Color(0xFF4A7C59).withOpacity(0.2)),
                    activeTrackColor: const Color(0xFF4A7C59),
                    inactiveTrackColor:
                        const Color(0xFF4A7C59).withOpacity(0.15),
                    thumbColor: const Color(0xFF4A7C59),
                  ),
                  child: Slider(
                    min: 0,
                    max: totalMs > 0 ? totalMs : 1.0,
                    value: currentMs,
                    onChanged: isActive ? _seekAudio : null,
                  ),
                ),

                // Durasi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isActive
                          ? _formatDuration(_audioPosition)
                          : '0:00',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF8A998B)),
                    ),
                    Text(
                      isActive && _audioDuration != Duration.zero
                          ? _formatDuration(_audioDuration)
                          : '--:--',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF8A998B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Fullscreen image viewer ─────────────────────────────────────
  void _showImageFullscreen(String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(title,
                style: const TextStyle(fontSize: 14, color: Colors.white)),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Info Card ───────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4A7C59).withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF4A7C59).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF4A7C59), size: 22),
              const SizedBox(width: 10),
              Text('Informasi Tambahan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF2C3E2D),
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(icon: Icons.category_rounded,
              label: 'Kategori', value: widget.budaya.kategori),
          if (widget.budaya.asalDaerah != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(icon: Icons.location_city_rounded,
                label: 'Asal Daerah', value: widget.budaya.asalDaerah!),
          ],
          const SizedBox(height: 12),
          _buildInfoRow(icon: Icons.calendar_today_rounded,
              label: 'Ditambahkan',
              value: _formatDate(widget.budaya.createdAt)),
        ],
      ),
    );
  }

  // ─── Reusable widgets ────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4, height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF4A7C59),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF2C3E2D),
                fontWeight: FontWeight.w700,
                fontSize: 18)),
      ],
    );
  }

  Widget _buildEmptyText(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8A998B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              color: Color(0xFF8A998B), size: 18),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(
                  color: Color(0xFF8A998B),
                  fontStyle: FontStyle.italic,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF4A7C59)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A998B),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2C3E2D),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}