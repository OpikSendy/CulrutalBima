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
                onTap: () => _showGalleryViewer(index),
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
                        // Badge jumlah foto jika ini foto pertama
                        if (index == 0 && _mediaGambar.length > 1)
                          Positioned(
                            top: 8, left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '1 / ${_mediaGambar.length}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
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
    return GestureDetector(
      onTap: () => _showVideoPopup(video),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
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
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Dark background
                Container(color: const Color(0xFF0D1117)),
                // Play icon
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A7C59).withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A7C59).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 36),
                  ),
                ),
                // Label bar
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.videocam_rounded,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            video.judul ?? 'Video',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.open_in_full_rounded,
                            color: Colors.white54, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    return GestureDetector(
      onTap: () => _showAudioPopup(audio),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF4A7C59).withOpacity(0.2)),
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
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A7C59), Color(0xFF2C5F3D)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A7C59).withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.headphones_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audio.judul ?? 'Audio Tradisional',
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E2D),
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text('Ketuk untuk memutar',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8A998B))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4A7C59).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF4A7C59), size: 12),
            ),
          ],
        ),
      ),
    );
  }


  // ─── Gallery Viewer — PageView swipeable ─────────────────────────
  void _showGalleryViewer(int initialIndex) {
    final pageCtrl = PageController(initialPage: initialIndex);
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) {
          int cur = initialIndex;
          return StatefulBuilder(builder: (ctx, ss) => Scaffold(
            backgroundColor: Colors.black,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.black45, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
              title: Text(
                '${cur + 1} / ${_mediaGambar.length}',
                style: const TextStyle(fontSize: 14),
              ),
              centerTitle: true,
            ),
            body: PageView.builder(
              controller: pageCtrl,
              itemCount: _mediaGambar.length,
              onPageChanged: (i) => ss(() => cur = i),
              itemBuilder: (_, i) {
                final img = _mediaGambar[i];
                return Stack(alignment: Alignment.bottomCenter, children: [
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 5.0,
                      child: Image.network(
                        img.urlMedia,
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, p) {
                          if (p == null) return child;
                          return const Center(child: CircularProgressIndicator(
                              color: Color(0xFF4A7C59)));
                        },
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image, color: Colors.white38, size: 64),
                      ),
                    ),
                  ),
                  if (img.judul != null)
                    Positioned(
                      bottom: 40,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(img.judul!,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            textAlign: TextAlign.center),
                      ),
                    ),
                ]);
              },
            ),
          ));
        },
      ),
    );
  }

  // ─── Video Pop-up Bottom Sheet ────────────────────────────────────
  void _showVideoPopup(BudayaMedia video) {
    VideoPlayerController? popupVc;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, ss) {
          if (popupVc == null) {
            popupVc = VideoPlayerController.networkUrl(
                Uri.parse(video.urlMedia));
            popupVc!.initialize().then((_) {
              popupVc!.play();
              popupVc!.addListener(() { if (ctx.mounted) ss(() {}); });
              ss(() {});
            });
          }
          final initialized = popupVc!.value.isInitialized;
          final playing = popupVc!.value.isPlaying;
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.72,
            decoration: const BoxDecoration(
              color: Color(0xFF0D1117),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                child: Row(children: [
                  const Icon(Icons.videocam_rounded,
                      color: Color(0xFF4A7C59), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(video.judul ?? 'Video',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () {
                      popupVc?.dispose();
                      Navigator.pop(ctx);
                    },
                  ),
                ]),
              ),
              Expanded(
                child: !initialized
                    ? const Center(child: CircularProgressIndicator(
                        color: Color(0xFF4A7C59)))
                    : GestureDetector(
                        onTap: () => playing
                            ? popupVc!.pause()
                            : popupVc!.play(),
                        child: Stack(alignment: Alignment.center, children: [
                          AspectRatio(
                            aspectRatio: popupVc!.value.aspectRatio,
                            child: VideoPlayer(popupVc!),
                          ),
                          if (!playing)
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 36),
                            ),
                        ]),
                      ),
              ),
              if (initialized)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Column(children: [
                    VideoProgressIndicator(
                      popupVc!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFF4A7C59),
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white12,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white70),
                        onPressed: () => popupVc!.seekTo(
                            popupVc!.value.position - const Duration(seconds: 10)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 52, height: 52,
                        decoration: const BoxDecoration(
                            color: Color(0xFF4A7C59), shape: BoxShape.circle),
                        child: IconButton(
                          icon: Icon(playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                              color: Colors.white, size: 28),
                          onPressed: () =>
                              playing ? popupVc!.pause() : popupVc!.play(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white70),
                        onPressed: () => popupVc!.seekTo(
                            popupVc!.value.position + const Duration(seconds: 10)),
                      ),
                    ]),
                  ]),
                ),
            ]),
          );
        });
      },
    ).whenComplete(() => popupVc?.dispose());
  }

  // ─── Audio Pop-up Bottom Sheet premium ───────────────────────────
  void _showAudioPopup(BudayaMedia audio) {
    _toggleAudio(audio);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        _audioPlayer.onPlayerStateChanged.listen((_) { if (ctx.mounted) ss(() {}); });
        _audioPlayer.onPositionChanged.listen((_) { if (ctx.mounted) ss(() {}); });
        _audioPlayer.onDurationChanged.listen((_) { if (ctx.mounted) ss(() {}); });

        final isActive = _activeAudioId == audio.id;
        final isPlaying = isActive && _audioState == PlayerState.playing;
        final totalMs = _audioDuration.inMilliseconds.toDouble();
        final currMs = isActive
            ? _audioPosition.inMilliseconds.toDouble().clamp(
                0.0, totalMs > 0 ? totalMs : 1.0)
            : 0.0;

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A27), Color(0xFF0F1E15)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF4A7C59), Color(0xFF2C5F3D)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF4A7C59).withOpacity(0.45),
                  blurRadius: 28, spreadRadius: 4,
                )],
              ),
              child: const Icon(Icons.music_note_rounded,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: 22),
            Text(audio.judul ?? 'Audio Tradisional',
                style: const TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text('Musik Tradisional Bima',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 28),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 5,
                activeTrackColor: const Color(0xFF4A7C59),
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayColor: const Color(0xFF4A7C59).withOpacity(0.2),
              ),
              child: Slider(
                min: 0, max: totalMs > 0 ? totalMs : 1.0, value: currMs,
                onChanged: isActive ? _seekAudio : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isActive ? _formatDuration(_audioPosition) : '0:00',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  Text(
                    isActive && _audioDuration != Duration.zero
                        ? _formatDuration(_audioDuration)
                        : '--:--',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.replay_15, color: Colors.white70),
                onPressed: () => _audioPlayer.seek(
                    _audioPosition - const Duration(seconds: 15)),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _toggleAudio(audio),
                child: Container(
                  width: 68, height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A7C59),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF4A7C59).withOpacity(0.5),
                      blurRadius: 22, spreadRadius: 4,
                    )],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white, size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.forward_15, color: Colors.white70),
                onPressed: () => _audioPlayer.seek(
                    _audioPosition + const Duration(seconds: 15)),
              ),
            ]),
          ]),
        );
      }),
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