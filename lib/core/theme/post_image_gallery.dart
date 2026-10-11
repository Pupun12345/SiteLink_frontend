import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/k_text_style.dart';

// ═══════════════════════════════════════════════════════════════════
//  POST IMAGE GALLERY — shared by community feed aur My Posts dono
// ═══════════════════════════════════════════════════════════════════
// Pehle ye sab worker_home_tab.dart ke andar file-private tha, isliye
// My Posts card sirf pehli image dikha pata tha aur baaki images kabhi
// khulti hi nahi thi. Ab yahan shared/public hai — dono jagah same
// adaptive grid + swipe/pinch-zoom fullscreen viewer milta hai.

// ── Post images display — adaptive single + 2 / 3+ grid, tap = gallery
class PostImagesDisplay extends StatelessWidget {
  final List<String> urls;
  const PostImagesDisplay({super.key, required this.urls});

  @override
  Widget build(BuildContext context) {
    final count = urls.length;
    if (count == 0) return const SizedBox.shrink();

    if (count == 1) {
      return AdaptiveNetImg(
        url: urls[0],
        onTap: () => openImageGallery(urls, 0),
      );
    }

    if (count == 2) {
      return Row(children: [
        Expanded(
            child: GestureDetector(
                onTap: () => openImageGallery(urls, 0),
                child: NetImg(url: urls[0], height: 200))),
        const SizedBox(width: 2),
        Expanded(
            child: GestureDetector(
                onTap: () => openImageGallery(urls, 1),
                child: NetImg(url: urls[1], height: 200))),
      ]);
    }

    return Column(children: [
      GestureDetector(
        onTap: () => openImageGallery(urls, 0),
        child: NetImg(url: urls[0], height: 210, width: double.infinity),
      ),
      const SizedBox(height: 2),
      Row(children: [
        for (int i = 1; i < count && i < 4; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => openImageGallery(urls, i),
              child: Stack(children: [
                NetImg(url: urls[i], height: 110),
                if (i == 3 && count > 4)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Center(
                        child: Text('+${count - 3}',
                            style: KTextStyle.poppins(
                                fs: 16,
                                fw: FontWeight.bold,
                                c: Colors.white)),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          if (i < count - 1 && i < 3) const SizedBox(width: 2),
        ],
      ]),
    ]);
  }
}

// ── Adaptive single image — real aspect ratio ke hisaab se ─────────
// AR caps (Instagram jaise): landscape max 1.91:1, portrait max 4:5.
// Caps ke bahar wali image crop NAHI hoti — blur bg + poori image (contain).
class AdaptiveNetImg extends StatefulWidget {
  final String url;
  final VoidCallback? onTap;
  const AdaptiveNetImg({super.key, required this.url, this.onTap});

  @override
  State<AdaptiveNetImg> createState() => _AdaptiveNetImgState();
}

class _AdaptiveNetImgState extends State<AdaptiveNetImg> {
  static const double _maxLandscapeAr = 1.91; // 1.91:1
  static const double _maxPortraitAr  = 0.75; // 3:4 se zyada lambi → blur bg

  double? _ar; // image ka real aspect ratio
  bool _failed = false;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  // Image ke intrinsic dimensions nikaalo (bina layout jump ke)
  void _resolve() {
    final provider = NetworkImage(widget.url);
    _stream = provider.resolve(const ImageConfiguration());
    _listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        setState(() => _ar = h > 0 ? w / h : 1);
      },
      onError: (_, __) {
        if (mounted) setState(() => _failed = true);
      },
    );
    _stream!.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: AppColors.scaffoldBg,
          child: Icon(Icons.image_outlined,
              size: 32, color: Colors.grey.shade400),
        ),
      );
    }

    // Dimensions aane tak neutral 16:9 shimmer-placeholder
    if (_ar == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: AppColors.scaffoldBg,
          child: const Center(
            child: SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
          ),
        ),
      );
    }

    final ar = _ar!;
    final displayAr =
        ar.clamp(_maxPortraitAr, _maxLandscapeAr).toDouble();
    final withinCaps = (ar - displayAr).abs() < 0.01;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: AspectRatio(
          aspectRatio: displayAr,
          child: withinCaps
              // AR caps ke andar → poori image pixel-perfect bharti hai
              ? Image.network(widget.url,
                  fit: BoxFit.cover, width: double.infinity)
              // Extreme vertical/horizontal → blur bg + POORI image
              : Stack(fit: StackFit.expand, children: [
                  ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Image.network(widget.url, fit: BoxFit.cover),
                  ),
                  Container(color: Colors.black.withValues(alpha: 0.25)),
                  Image.network(widget.url, fit: BoxFit.contain),
                ]),
        ),
      ),
    );
  }
}

class NetImg extends StatelessWidget {
  final String url;
  final double height;
  final double? width;
  const NetImg({super.key, required this.url, required this.height, this.width});

  @override
  Widget build(BuildContext context) => Image.network(
    url,
    width: width ?? double.infinity,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => Container(
      width: width ?? double.infinity,
      height: height,
      color: AppColors.scaffoldBg,
      child: Icon(Icons.image_outlined,
          size: 32, color: Colors.grey.shade400),
    ),
  );
}

// ── Fullscreen gallery — swipe (multi) + pinch-zoom + counter ──────
void openImageGallery(List<String> urls, int initialIndex) {
  if (urls.isEmpty) return;
  Get.dialog(
    ImageGalleryViewer(urls: urls, initialIndex: initialIndex),
    barrierColor: Colors.black,
    useSafeArea: false,
  );
}

class ImageGalleryViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const ImageGalleryViewer({super.key, required this.urls, required this.initialIndex});

  @override
  State<ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<ImageGalleryViewer> {
  late final PageController _page =
      PageController(initialPage: widget.initialIndex);
  late int _current = widget.initialIndex;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _page,
          itemCount: widget.urls.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) => InteractiveViewer(
            maxScale: 4,
            child: Center(
              child: Image.network(
                widget.urls[i],
                fit: BoxFit.contain,
                loadingBuilder: (_, child, p) => p == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white54, strokeWidth: 2)),
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white38,
                    size: 54),
              ),
            ),
          ),
        ),
        // Close
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ),
        // Counter (1/4)
        if (widget.urls.length > 1)
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_current + 1}/${widget.urls.length}',
                    style: KTextStyle.poppins(fs: 12, c: Colors.white)),
              ),
            ),
          ),
      ]),
    );
  }
}
