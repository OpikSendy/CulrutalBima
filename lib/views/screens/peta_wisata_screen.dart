// lib/views/screens/peta_wisata_screen.dart

import 'package:culturalbima/views/maps/peta_wisata_maps_screen.dart';
import 'package:culturalbima/views/widgets/common/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../viewmodels/wisata_viewmodel.dart';
import '../../data/models/wisata_model.dart';
import '../../core/constants/app_strings.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/wisata/wisata_card.dart';


// ─── Model media wisata ──────────────────────────────────────────
class WisataMedia {
  final String id;
  final String jenisMedia;
  final String urlMedia;
  final String? judul;
  final int urutan;

  WisataMedia({
    required this.id,
    required this.jenisMedia,
    required this.urlMedia,
    this.judul,
    required this.urutan,
  });

  factory WisataMedia.fromMap(Map<String, dynamic> m) => WisataMedia(
        id: m['id'] as String,
        jenisMedia: m['jenis_media'] as String,
        urlMedia: m['url_media'] as String,
        judul: m['judul'] as String?,
        urutan: (m['urutan'] as int?) ?? 0,
      );
}

class PetaWisataScreen extends StatefulWidget {
  const PetaWisataScreen({super.key});

  @override
  State<PetaWisataScreen> createState() => _PetaWisataScreenState();
}

class _PetaWisataScreenState extends State<PetaWisataScreen> {
  final TextEditingController _searchController = TextEditingController();

  // ─── Audio Player (shared untuk wisata detail) ───────────────────
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _activeAudioId;
  PlayerState _audioState = PlayerState.stopped;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WisataViewModel>().fetchAllWisata();
    });
    _audioPlayer.onPlayerStateChanged
        .listen((s) { if (mounted) setState(() => _audioState = s); });
    _audioPlayer.onDurationChanged
        .listen((d) { if (mounted) setState(() => _audioDuration = d); });
    _audioPlayer.onPositionChanged
        .listen((p) { if (mounted) setState(() => _audioPosition = p); });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() {
        _audioState = PlayerState.stopped;
        _audioPosition = Duration.zero;
        _activeAudioId = null;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _openInteractiveMaps() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const PetaWisataMapsScreen()));
  }

  Future<void> _openAllInMaps(List<WisataModel> wisataList) async {
    if (wisataList.isEmpty) return;
    if (wisataList.length == 1) {
      final uri = Uri.parse(wisataList.first.googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    final coordinates =
        wisataList.map((w) => '${w.latitude},${w.longitude}').join('|');
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&waypoints=$coordinates');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Fetch wisata_media dari Supabase ────────────────────────────
  Future<List<WisataMedia>> _fetchWisataMedia(String wisataId) async {
    try {
      final res = await Supabase.instance.client
          .from('wisata_media')
          .select()
          .eq('wisata_id', wisataId)
          .order('urutan')
          .order('created_at');
      return (res as List)
          .map((e) => WisataMedia.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return []; // graceful: jika tabel belum ada, return kosong
    }
  }

  // ─── Show gallery fullscreen swipeable ───────────────────────────
  void _showGalleryViewer(List<WisataMedia> images, int initialIndex,
      {String? mainImageUrl}) {
    final allUrls = <Map<String, String?>>[];
    if (mainImageUrl != null) {
      allUrls.add({'url': mainImageUrl, 'judul': 'Foto Utama'});
    }
    allUrls.addAll(images.map((m) => {'url': m.urlMedia, 'judul': m.judul}));

    final startIndex = mainImageUrl != null ? initialIndex : initialIndex;
    final pageCtrl = PageController(initialPage: startIndex);

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) {
          int cur = startIndex;
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
              title: Text('${cur + 1} / ${allUrls.length}',
                  style: const TextStyle(fontSize: 14)),
              centerTitle: true,
            ),
            body: PageView.builder(
              controller: pageCtrl,
              itemCount: allUrls.length,
              onPageChanged: (i) => ss(() => cur = i),
              itemBuilder: (_, i) {
                final item = allUrls[i];
                return Stack(alignment: Alignment.bottomCenter, children: [
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.8, maxScale: 5.0,
                      child: Image.network(
                        item['url']!,
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, p) => p == null
                            ? child
                            : const Center(child: CircularProgressIndicator(
                                color: Color(0xFF8B6F47))),
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            color: Colors.white38, size: 64),
                      ),
                    ),
                  ),
                  if (item['judul'] != null)
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
                        child: Text(item['judul']!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
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

  // ─── Show video popup ────────────────────────────────────────────
  void _showVideoPopup(WisataMedia video) {
    VideoPlayerController? vc;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        if (vc == null) {
          vc = VideoPlayerController.networkUrl(Uri.parse(video.urlMedia));
          vc!.initialize().then((_) {
            vc!.play();
            vc!.addListener(() { if (ctx.mounted) ss(() {}); });
            ss(() {});
          });
        }
        final initialized = vc!.value.isInitialized;
        final playing = vc!.value.isPlaying;
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
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
              child: Row(children: [
                const Icon(Icons.videocam_rounded,
                    color: Color(0xFF8B6F47), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(video.judul ?? 'Video',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 15, fontWeight: FontWeight.w700))),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () { vc?.dispose(); Navigator.pop(ctx); },
                ),
              ]),
            ),
            Expanded(
              child: !initialized
                  ? const Center(child: CircularProgressIndicator(
                      color: Color(0xFF8B6F47)))
                  : GestureDetector(
                      onTap: () =>
                          playing ? vc!.pause() : vc!.play(),
                      child: Stack(alignment: Alignment.center, children: [
                        AspectRatio(
                            aspectRatio: vc!.value.aspectRatio,
                            child: VideoPlayer(vc!)),
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
                  VideoProgressIndicator(vc!, allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFF8B6F47),
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white12,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8)),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white70),
                      onPressed: () => vc!.seekTo(
                          vc!.value.position - const Duration(seconds: 10)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 52, height: 52,
                      decoration: const BoxDecoration(
                          color: Color(0xFF8B6F47), shape: BoxShape.circle),
                      child: IconButton(
                        icon: Icon(
                            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white, size: 28),
                        onPressed: () =>
                            playing ? vc!.pause() : vc!.play(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white70),
                      onPressed: () => vc!.seekTo(
                          vc!.value.position + const Duration(seconds: 10)),
                    ),
                  ]),
                ]),
              ),
          ]),
        );
      }),
    ).whenComplete(() => vc?.dispose());
  }

  // ─── Show audio popup ────────────────────────────────────────────
  void _showAudioPopup(WisataMedia audio) {
    // Toggle play
    if (_activeAudioId == audio.id) {
      if (_audioState == PlayerState.playing) {
        _audioPlayer.pause();
      } else {
        _audioPlayer.resume();
      }
    } else {
      _audioPlayer.stop();
      setState(() { _activeAudioId = audio.id; _audioPosition = Duration.zero; });
      _audioPlayer.play(UrlSource(audio.urlMedia));
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        _audioPlayer.onPlayerStateChanged
            .listen((_) { if (ctx.mounted) ss(() {}); });
        _audioPlayer.onPositionChanged
            .listen((_) { if (ctx.mounted) ss(() {}); });
        _audioPlayer.onDurationChanged
            .listen((_) { if (ctx.mounted) ss(() {}); });

        final isActive = _activeAudioId == audio.id;
        final isPlaying = isActive && _audioState == PlayerState.playing;
        final totalMs = _audioDuration.inMilliseconds.toDouble();
        final currMs = isActive
            ? _audioPosition.inMilliseconds
                .toDouble()
                .clamp(0.0, totalMs > 0 ? totalMs : 1.0)
            : 0.0;

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF3D2B1F), Color(0xFF1A100A)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF8B6F47), Color(0xFF5C4530)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF8B6F47).withOpacity(0.45),
                  blurRadius: 28, spreadRadius: 4,
                )],
              ),
              child: const Icon(Icons.music_note_rounded,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: 22),
            Text(audio.judul ?? 'Audio Wisata',
                style: const TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text('Audio Wisata Bima',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 28),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 5,
                activeTrackColor: const Color(0xFF8B6F47),
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayColor: const Color(0xFF8B6F47).withOpacity(0.2),
              ),
              child: Slider(
                min: 0, max: totalMs > 0 ? totalMs : 1.0, value: currMs,
                onChanged: isActive
                    ? (v) => _audioPlayer
                        .seek(Duration(milliseconds: v.toInt()))
                    : null,
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
                icon: const Icon(Icons.replay_10, color: Colors.white70),
                onPressed: () => _audioPlayer.seek(
                    _audioPosition - const Duration(seconds: 15)),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  if (_activeAudioId == audio.id) {
                    if (isPlaying) {
                      _audioPlayer.pause();
                    } else {
                      _audioPlayer.resume();
                    }
                  } else {
                    _audioPlayer.stop();
                    setState(() {
                      _activeAudioId = audio.id;
                      _audioPosition = Duration.zero;
                    });
                    _audioPlayer.play(UrlSource(audio.urlMedia));
                  }
                },
                child: Container(
                  width: 68, height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B6F47),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF8B6F47).withOpacity(0.5),
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
                icon: const Icon(Icons.replay_10, color: Colors.white70),
                onPressed: () => _audioPlayer.seek(
                    _audioPosition + const Duration(seconds: 15)),
              ),
            ]),
          ]),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.wisataTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: _openInteractiveMaps,
            tooltip: 'Peta Interaktif',
          ),
          Consumer<WisataViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.wisataList.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => _openAllInMaps(viewModel.wisataList),
                  tooltip: 'Buka di Google Maps',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<WisataViewModel>().refreshData();
            },
            tooltip: AppStrings.actionRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatsBar(),
          Expanded(
            child: Consumer<WisataViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return Column(
                    children: List.generate(
                        3, (index) => const ShimmerCard()),
                  );
                }
                if (viewModel.hasError) {
                  return ErrorStateWidget(
                    message: viewModel.errorMessage ?? AppStrings.errorLoadData,
                    onRetry: () => viewModel.fetchAllWisata(),
                  );
                }
                if (viewModel.isEmpty) {
                  return EmptyStateWidget(
                    title: AppStrings.wisataEmpty,
                    message: AppStrings.wisataEmptyDesc,
                    icon: Icons.location_off_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => viewModel.refreshData(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: viewModel.wisataList.length,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, index) {
                      final wisata = viewModel.wisataList[index];
                      return WisataCard(
                        wisata: wisata,
                        onTap: () {
                          _showWisataDetail(context, wisata);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<WisataViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.wisataList.isNotEmpty) {
            return FloatingActionButton.extended(
              onPressed: _openInteractiveMaps,
              backgroundColor: const Color(0xFF8B6F47),
              icon: const Icon(Icons.map),
              label: const Text('Lihat Peta'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          context.read<WisataViewModel>().searchWisata(value);
        },
        decoration: InputDecoration(
          hintText: AppStrings.wisataSearchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<WisataViewModel>().searchWisata('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: const Color(0xFF8A998B).withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: const Color(0xFF8A998B).withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFF8B6F47), width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFFFAF8F3),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Consumer<WisataViewModel>(
      builder: (context, viewModel, child) {
        return InkWell(
          onTap: viewModel.wisataList.isNotEmpty
              ? _openInteractiveMaps
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            color: const Color(0xFF8B6F47).withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 20,
                    color: const Color(0xFF8B6F47)),
                const SizedBox(width: 8),
                Text(
                  'Total ${viewModel.wisataList.length} Destinasi Wisata',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Color(0xFF8B6F47)),
                ),
                const Spacer(),
                if (viewModel.wisataList.isNotEmpty)
                  Row(
                    children: const [
                      Text('Lihat Peta',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF8B6F47))),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          size: 12, color: Color(0xFF8B6F47)),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWisataDetail(BuildContext context, WisataModel wisata) {
    List<WisataMedia> _wisataMedia = [];
    bool _mediaLoaded = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx2, scrollController) {
          return StatefulBuilder(builder: (ctx2, ss) {
            // Fetch media once
            if (!_mediaLoaded) {
              _mediaLoaded = true;
              _fetchWisataMedia(wisata.id).then((list) {
                if (ctx2.mounted) ss(() => _wisataMedia = list);
              });
            }

            final mediaGambar =
                _wisataMedia.where((m) => m.jenisMedia == 'gambar').toList();
            final mediaVideo =
                _wisataMedia.where((m) => m.jenisMedia == 'video').toList();
            final mediaAudio =
                _wisataMedia.where((m) => m.jenisMedia == 'audio').toList();

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFF8A998B).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── FOTO UTAMA (clickable) ─────────────
                          GestureDetector(
                            onTap: () {
                              // Buka gallery: foto utama + foto dari wisata_media
                              _showGalleryViewer(
                                mediaGambar,
                                0,
                                mainImageUrl: wisata.imageUrl,
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  Image.network(
                                    wisata.imageUrl,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: double.infinity, height: 200,
                                      color: const Color(0xFFF5F5F0),
                                      child: const Icon(
                                          Icons.image_not_supported,
                                          size: 60,
                                          color: Color(0xFF8A998B)),
                                    ),
                                  ),
                                  // Overlay fullscreen badge
                                  Positioned(
                                    top: 10, right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.45),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.fullscreen,
                                          color: Colors.white, size: 18),
                                    ),
                                  ),
                                  // Foto count badge
                                  if (mediaGambar.isNotEmpty)
                                    Positioned(
                                      bottom: 10, right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons.photo_library_rounded,
                                                color: Colors.white, size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              '+${mediaGambar.length} foto',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ─── NAMA ───────────────────────────────
                          Text(
                            wisata.nama,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E2D)),
                          ),
                          const SizedBox(height: 12),

                          // ─── ALAMAT ─────────────────────────────
                          Row(children: [
                            const Icon(Icons.location_on, size: 18,
                                color: Color(0xFF8B6F47)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                wisata.alamat ?? wisata.alamatSingkat,
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF5A6C5B)),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 8),

                          // ─── KOORDINAT ──────────────────────────
                          Row(children: [
                            const Icon(Icons.my_location, size: 16,
                                color: Color(0xFF8A998B)),
                            const SizedBox(width: 8),
                            Text(
                              wisata.koordinat,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF8A998B),
                                  fontFamily: 'monospace'),
                            ),
                          ]),

                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),

                          // ─── DESKRIPSI ──────────────────────────
                          if (wisata.deskripsi != null) ...[
                            const Text('Deskripsi',
                                style: TextStyle(fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C3E2D))),
                            const SizedBox(height: 10),
                            Text(
                              wisata.deskripsi!,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF5A6C5B),
                                  height: 1.6),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 20),
                          ],

                          // ─── MULTIMEDIA SECTION ─────────────────
                          if (_wisataMedia.isNotEmpty) ...[
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(children: [
                              Container(
                                width: 4, height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B6F47),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text('Multimedia',
                                  style: TextStyle(fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2C3E2D))),
                            ]),
                            const SizedBox(height: 16),

                            // Gallery tambahan
                            if (mediaGambar.isNotEmpty) ...[
                              Row(children: [
                                const Icon(Icons.photo_library_rounded,
                                    size: 14, color: Color(0xFF8B6F47)),
                                const SizedBox(width: 6),
                                Text('Galeri Foto (${mediaGambar.length})',
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600,
                                        color: Color(0xFF2C3E2D))),
                              ]),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 150,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: mediaGambar.length,
                                  itemBuilder: (_, i) {
                                    final img = mediaGambar[i];
                                    return GestureDetector(
                                      onTap: () => _showGalleryViewer(
                                          mediaGambar, i),
                                      child: Container(
                                        width: 140,
                                        margin: const EdgeInsets.only(right: 10),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                            Image.network(img.urlMedia,
                                                fit: BoxFit.cover),
                                            Positioned(
                                              top: 6, right: 6,
                                              child: Container(
                                                padding: const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                    color: Colors.black45,
                                                    shape: BoxShape.circle),
                                                child: const Icon(
                                                    Icons.fullscreen,
                                                    color: Colors.white,
                                                    size: 12),
                                              ),
                                            ),
                                          ]),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Video
                            if (mediaVideo.isNotEmpty) ...[
                              Row(children: [
                                const Icon(Icons.videocam_rounded,
                                    size: 14, color: Color(0xFF8B6F47)),
                                const SizedBox(width: 6),
                                Text('Video (${mediaVideo.length})',
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600,
                                        color: Color(0xFF2C3E2D))),
                              ]),
                              const SizedBox(height: 10),
                              ...mediaVideo.map((v) => GestureDetector(
                                    onTap: () => _showVideoPopup(v),
                                    child: Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 10),
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D1117),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                        Container(
                                          width: 52, height: 52,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8B6F47)
                                                .withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              Icons.play_arrow_rounded,
                                              color: Colors.white, size: 30),
                                        ),
                                        Positioned(
                                          bottom: 10, left: 14,
                                          child: Text(v.judul ?? 'Video',
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12)),
                                        ),
                                      ]),
                                    ),
                                  )),
                              const SizedBox(height: 8),
                            ],

                            // Audio
                            if (mediaAudio.isNotEmpty) ...[
                              Row(children: [
                                const Icon(Icons.music_note_rounded,
                                    size: 14, color: Color(0xFF8B6F47)),
                                const SizedBox(width: 6),
                                Text('Audio (${mediaAudio.length})',
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600,
                                        color: Color(0xFF2C3E2D))),
                              ]),
                              const SizedBox(height: 10),
                              ...mediaAudio.map((a) => GestureDetector(
                                    onTap: () => _showAudioPopup(a),
                                    child: Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B6F47)
                                            .withOpacity(0.06),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFF8B6F47)
                                                .withOpacity(0.2)),
                                      ),
                                      child: Row(children: [
                                        Container(
                                          width: 40, height: 40,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF8B6F47),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              Icons.headphones_rounded,
                                              color: Colors.white, size: 18),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(a.judul ?? 'Audio',
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Color(0xFF2C3E2D)),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                              const Text('Ketuk untuk memutar',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Color(0xFF8A998B))),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: Color(0xFF8B6F47),
                                            size: 12),
                                      ]),
                                    ),
                                  )),
                              const SizedBox(height: 8),
                            ],
                          ],

                          // ─── ACTION BUTTONS ─────────────────────
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final uri =
                                      Uri.parse(wisata.googleMapsUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  }
                                },
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Google Maps'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B6F47),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _openInteractiveMaps();
                                },
                                icon: const Icon(Icons.map),
                                label: const Text('Peta Lokal'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  side: const BorderSide(
                                      color: Color(0xFF8B6F47), width: 2),
                                  foregroundColor: const Color(0xFF8B6F47),
                                ),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        },
      ),
    );
  }
}


// import '../../viewmodels/wisata_viewmodel.dart';
// import '../../data/models/wisata_model.dart';
// import '../../core/constants/app_strings.dart';
// import '../widgets/common/loading_widget.dart';
// import '../widgets/common/error_widget.dart';
// import '../widgets/wisata/wisata_card.dart';
//
// class PetaWisataScreen extends StatefulWidget {
//   const PetaWisataScreen({super.key});
//
//   @override
//   State<PetaWisataScreen> createState() => _PetaWisataScreenState();
// }
//
// class _PetaWisataScreenState extends State<PetaWisataScreen> {
//   final TextEditingController _searchController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     // Fetch data saat screen pertama kali dibuka
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<WisataViewModel>().fetchAllWisata();
//     });
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   // Navigasi ke Interactive Maps Screen
//   void _openInteractiveMaps() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const PetaWisataMapsScreen(),
//       ),
//     );
//   }
//
//   Future<void> _openAllInMaps(List<WisataModel> wisataList) async {
//     if (wisataList.isEmpty) return;
//
//     // Jika hanya 1 wisata, buka langsung
//     if (wisataList.length == 1) {
//       final uri = Uri.parse(wisataList.first.googleMapsUrl);
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri, mode: LaunchMode.externalApplication);
//       }
//       return;
//     }
//
//     // Jika lebih dari 1, buka Google Maps dengan multiple markers
//     final coordinates = wisataList
//         .map((w) => '${w.latitude},${w.longitude}')
//         .join('|');
//
//     final mapsUrl = 'https://www.google.com/maps/dir/?api=1&waypoints=$coordinates';
//     final uri = Uri.parse(mapsUrl);
//
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(AppStrings.wisataTitle),
//         actions: [
//           // Button ke Interactive Maps
//           IconButton(
//             icon: const Icon(Icons.map),
//             onPressed: _openInteractiveMaps,
//             tooltip: 'Peta Interaktif',
//           ),
//           Consumer<WisataViewModel>(
//             builder: (context, viewModel, child) {
//               if (viewModel.wisataList.isNotEmpty) {
//                 return IconButton(
//                   icon: const Icon(Icons.open_in_new),
//                   onPressed: () => _openAllInMaps(viewModel.wisataList),
//                   tooltip: 'Buka di Google Maps',
//                 );
//               }
//               return const SizedBox.shrink();
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               context.read<WisataViewModel>().refreshData();
//             },
//             tooltip: AppStrings.actionRefresh,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Search Bar
//           _buildSearchBar(),
//
//           // Stats Bar with Maps Button
//           _buildStatsBar(),
//
//           // Content (List/Loading/Error/Empty)
//           Expanded(
//             child: Consumer<WisataViewModel>(
//               builder: (context, viewModel, child) {
//                 // Loading State
//                 if (viewModel.isLoading) {
//                   return Column(
//                     children: List.generate(
//                       3,
//                           (index) => const ShimmerCard(),
//                     ),
//                   );
//                 }
//
//                 // Error State
//                 if (viewModel.hasError) {
//                   return ErrorStateWidget(
//                     message: viewModel.errorMessage ?? AppStrings.errorLoadData,
//                     onRetry: () => viewModel.fetchAllWisata(),
//                   );
//                 }
//
//                 // Empty State
//                 if (viewModel.isEmpty) {
//                   return EmptyStateWidget(
//                     title: AppStrings.wisataEmpty,
//                     message: AppStrings.wisataEmptyDesc,
//                     icon: Icons.location_off_outlined,
//                   );
//                 }
//
//                 // Success - Show List
//                 return RefreshIndicator(
//                   onRefresh: () => viewModel.refreshData(),
//                   child: ListView.builder(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     itemCount: viewModel.wisataList.length,
//                     padding: const EdgeInsets.only(bottom: 16),
//                     itemBuilder: (context, index) {
//                       final wisata = viewModel.wisataList[index];
//                       return WisataCard(
//                         wisata: wisata,
//                         onTap: () {
//                           _showWisataDetail(context, wisata);
//                         },
//                       );
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       // Floating Action Button untuk Quick Access ke Maps
//       floatingActionButton: Consumer<WisataViewModel>(
//         builder: (context, viewModel, child) {
//           if (viewModel.wisataList.isNotEmpty) {
//             return FloatingActionButton.extended(
//               onPressed: _openInteractiveMaps,
//               backgroundColor: const Color(0xFF8B6F47),
//               icon: const Icon(Icons.map),
//               label: const Text('Lihat Peta'),
//             );
//           }
//           return const SizedBox.shrink();
//         },
//       ),
//     );
//   }
//
//   Widget _buildSearchBar() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       color: Colors.white,
//       child: TextField(
//         controller: _searchController,
//         onChanged: (value) {
//           context.read<WisataViewModel>().searchWisata(value);
//         },
//         decoration: InputDecoration(
//           hintText: AppStrings.wisataSearchHint,
//           prefixIcon: const Icon(Icons.search),
//           suffixIcon: _searchController.text.isNotEmpty
//               ? IconButton(
//             icon: const Icon(Icons.clear),
//             onPressed: () {
//               _searchController.clear();
//               context.read<WisataViewModel>().searchWisata('');
//             },
//           )
//               : null,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(
//               color: const Color(0xFF8A998B).withOpacity(0.3),
//             ),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(
//               color: const Color(0xFF8A998B).withOpacity(0.3),
//             ),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(
//               color: Color(0xFF8B6F47),
//               width: 2,
//             ),
//           ),
//           filled: true,
//           fillColor: const Color(0xFFFAF8F3),
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: 14,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatsBar() {
//     return Consumer<WisataViewModel>(
//       builder: (context, viewModel, child) {
//         return InkWell(
//           onTap: viewModel.wisataList.isNotEmpty ? _openInteractiveMaps : null,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             color: const Color(0xFF8B6F47).withOpacity(0.1),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.location_on,
//                   size: 20,
//                   color: const Color(0xFF8B6F47),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Total ${viewModel.wisataList.length} Destinasi Wisata',
//                   style: const TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF8B6F47),
//                   ),
//                 ),
//                 const Spacer(),
//                 if (viewModel.wisataList.isNotEmpty)
//                   Row(
//                     children: const [
//                       Text(
//                         'Lihat Peta',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Color(0xFF8B6F47),
//                         ),
//                       ),
//                       SizedBox(width: 4),
//                       Icon(
//                         Icons.arrow_forward_ios,
//                         size: 12,
//                         color: Color(0xFF8B6F47),
//                       ),
//                     ],
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   void _showWisataDetail(BuildContext context, WisataModel wisata) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => DraggableScrollableSheet(
//         initialChildSize: 0.7,
//         minChildSize: 0.5,
//         maxChildSize: 0.9,
//         builder: (context, scrollController) {
//           return Container(
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(24),
//                 topRight: Radius.circular(24),
//               ),
//             ),
//             child: Column(
//               children: [
//                 // Handle bar
//                 Container(
//                   margin: const EdgeInsets.only(top: 12, bottom: 8),
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF8A998B).withOpacity(0.5),
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//
//                 // Content
//                 Expanded(
//                   child: SingleChildScrollView(
//                     controller: scrollController,
//                     padding: const EdgeInsets.all(20),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Image
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(16),
//                           child: Image.network(
//                             wisata.imageUrl,
//                             width: double.infinity,
//                             height: 200,
//                             fit: BoxFit.cover,
//                             errorBuilder: (context, error, stackTrace) {
//                               return Container(
//                                 width: double.infinity,
//                                 height: 200,
//                                 color: const Color(0xFFF5F5F0),
//                                 child: const Icon(
//                                   Icons.image_not_supported,
//                                   size: 60,
//                                   color: Color(0xFF8A998B),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//
//                         // Nama
//                         Text(
//                           wisata.nama,
//                           style: const TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.w700,
//                             color: Color(0xFF2C3E2D),
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//
//                         // Alamat
//                         Row(
//                           children: [
//                             const Icon(
//                               Icons.location_on,
//                               size: 18,
//                               color: Color(0xFF8B6F47),
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 wisata.alamat ?? wisata.alamatSingkat,
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   color: Color(0xFF5A6C5B),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//
//                         // Koordinat
//                         Row(
//                           children: [
//                             const Icon(
//                               Icons.my_location,
//                               size: 16,
//                               color: Color(0xFF8A998B),
//                             ),
//                             const SizedBox(width: 8),
//                             Text(
//                               wisata.koordinat,
//                               style: const TextStyle(
//                                 fontSize: 13,
//                                 color: Color(0xFF8A998B),
//                                 fontFamily: 'monospace',
//                               ),
//                             ),
//                           ],
//                         ),
//
//                         const SizedBox(height: 20),
//                         const Divider(),
//                         const SizedBox(height: 20),
//
//                         // Deskripsi
//                         if (wisata.deskripsi != null) ...[
//                           const Text(
//                             'Deskripsi',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Color(0xFF2C3E2D),
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           Text(
//                             wisata.deskripsi!,
//                             style: const TextStyle(
//                               fontSize: 14,
//                               color: Color(0xFF5A6C5B),
//                               height: 1.6,
//                             ),
//                             textAlign: TextAlign.justify,
//                           ),
//                           const SizedBox(height: 24),
//                         ],
//
//                         // Action Buttons
//                         Row(
//                           children: [
//                             // Google Maps Button
//                             Expanded(
//                               child: ElevatedButton.icon(
//                                 onPressed: () async {
//                                   final uri = Uri.parse(wisata.googleMapsUrl);
//                                   if (await canLaunchUrl(uri)) {
//                                     await launchUrl(
//                                       uri,
//                                       mode: LaunchMode.externalApplication,
//                                     );
//                                   }
//                                 },
//                                 icon: const Icon(Icons.open_in_new),
//                                 label: const Text('Google Maps'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color(0xFF8B6F47),
//                                   padding: const EdgeInsets.symmetric(vertical: 16),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//
//                             // Interactive Map Button
//                             Expanded(
//                               child: OutlinedButton.icon(
//                                 onPressed: () {
//                                   Navigator.pop(context);
//                                   _openInteractiveMaps();
//                                 },
//                                 icon: const Icon(Icons.map),
//                                 label: const Text('Peta Lokal'),
//                                 style: OutlinedButton.styleFrom(
//                                   padding: const EdgeInsets.symmetric(vertical: 16),
//                                   side: const BorderSide(
//                                     color: Color(0xFF8B6F47),
//                                     width: 2,
//                                   ),
//                                   foregroundColor: const Color(0xFF8B6F47),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }