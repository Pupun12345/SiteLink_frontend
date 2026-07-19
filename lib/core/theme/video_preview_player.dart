import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════
//  VIDEO PREVIEW PLAYER — local ya network video fullscreen play
// ═══════════════════════════════════════════════════════════════════
// Reusable: create-post preview (local file) + feed (network) dono ke liye.
class VideoPreviewPlayer extends StatefulWidget {
  final String path;
  final bool isNetwork;
  const VideoPreviewPlayer(
      {super.key, required this.path, this.isNetwork = false});

  /// Fullscreen dialog me kholo. Local file turant init hoti hai.
  static Future<void> open(String path, {bool isNetwork = false}) {
    if (path.isEmpty) return Future.value();
    return Get.dialog(
      VideoPreviewPlayer(path: path, isNetwork: isNetwork),
      barrierColor: Colors.black,
      useSafeArea: false,
    );
  }

  @override
  State<VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<VideoPreviewPlayer> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _video = widget.isNetwork
          ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
          : VideoPlayerController.file(File(widget.path));
      await _video!.initialize();
      final ar = _video!.value.aspectRatio;
      _chewie = ChewieController(
        videoPlayerController: _video!,
        autoPlay: true,
        looping: false,
        allowFullScreen: false,
        aspectRatio: ar > 0 ? ar : 16 / 9,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: Colors.white24,
        ),
      );
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _error = 'Video play nahi ho paaya.');
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _chewie != null && (_video?.value.isInitialized ?? false);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Center(
          child: _error != null
              ? Text(_error!, style: const TextStyle(color: Colors.white))
              : ready
                  ? Chewie(controller: _chewie!)
                  : const CircularProgressIndicator(color: Colors.white),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }
}
