import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/custom_cirular_indicator.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/services/video_compress_service.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../../core/theme/video_preview_player.dart';
import '../controllers/worker_feed_controller.dart';
import '../../../../core/models/community_feed_models.dart';
import 'comments_sheet.dart';
import 'worker_plans_view.dart';

// ═══════════════════════════════════════════════════════════════════
//  COMMUNITY HOME TAB (Worker + Vendor dono use karte hain — same feed)
// ═══════════════════════════════════════════════════════════════════
// Community feed dono roles pe identical hai (same /api/community APIs).
// Notification bell role ke hisaab se apni alerts-tab pe le jaata hai —
// isliye homeCtrl ki jagah simple [onNotificationTap] callback.
class WorkerHomeTab extends StatefulWidget {
  final VoidCallback onNotificationTap;
  // Premium/crown icon tap — null par default WorkerPlansView khulta hai.
  // Vendor apna VendorPlansView pass karta hai.
  final VoidCallback? onPremiumTap;
  const WorkerHomeTab(
      {super.key, required this.onNotificationTap, this.onPremiumTap});

  @override
  State<WorkerHomeTab> createState() => _WorkerHomeTabState();
}

class _WorkerHomeTabState extends State<WorkerHomeTab> {
  late final WorkerFeedController feedCtrl;
  final _searchCtrl      = TextEditingController();
  final _searchFocus     = FocusNode();
  final _scrollCtrl      = ScrollController();
  final _isSearchFocused = false.obs;
  final _searchQuery     = ''.obs;

  @override
  void initState() {
    super.initState();
    feedCtrl = Get.put(WorkerFeedController());

    _searchFocus.addListener(() {
      _isSearchFocused.value = _searchFocus.hasFocus;
    });

    // Infinite scroll: 300px se pehle trigger karo
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 300) {
        feedCtrl.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        top: true,
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
            _buildSliverAppBar(innerBoxIsScrolled),
            _buildStickySearchBar(),
            _buildFeedHeader(ctx),
          ],
          body: _buildFeedBody(),
        ),
      ),
    );
  }

  // ── Sliver App Bar ─────────────────────────────────────────────
  Widget _buildSliverAppBar(bool innerScrolled) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.surface,
      elevation: innerScrolled ? 0.5 : 0,
      shadowColor: Colors.black.withOpacity(0.08),
      surfaceTintColor: Colors.transparent,
      primary: false,
      title: Text(
        AppStrings.SiteLink,
        style: KTextStyle.poppins(
            fs: 19, fw: FontWeight.w700, c: AppColors.primary,
            letterSpacing: 0.2),
      ),
      centerTitle: false,
      actions: [
        // Premium — animated golden ring + crown
        _PremiumButton(onTap: widget.onPremiumTap),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: AppColors.textPrimary, size: 22),
              onPressed: widget.onNotificationTap,
            ),
            Positioned(
              right: 10, top: 10,
              child: Container(
                width: 15, height: 15,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: Center(
                  child: Text('1',
                      style: KTextStyle.poppins(
                          fs: 8, fw: FontWeight.bold, c: Colors.white)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppColors.divider),
      ),
    );
  }

  // ── Sticky Search Bar ──────────────────────────────────────────
  Widget _buildStickySearchBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SearchBarDelegate(
        child: Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Obx(() => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isSearchFocused.value
                  ? AppColors.surface
                  : AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isSearchFocused.value
                    ? AppColors.primary
                    : AppColors.divider,
                width: _isSearchFocused.value ? 1.5 : 1.0,
              ),
            ),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              style: KTextStyle.poppins(fs: 13, c: AppColors.textPrimary),
              onChanged: (v) => _searchQuery.value = v,
              decoration: InputDecoration(
                hintText: 'Search posts, workers, companies...',
                hintStyle:
                KTextStyle.poppins(fs: 13, c: AppColors.textHint),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: _isSearchFocused.value
                      ? AppColors.primary
                      : AppColors.textHint,
                ),
                suffixIcon: Obx(() => _searchQuery.value.isNotEmpty
                    ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    _searchQuery.value = '';
                    _searchFocus.unfocus();
                  },
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textHint),
                )
                    : const SizedBox.shrink()),
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          )),
        ),
      ),
    );
  }

  // ── Feed Header ────────────────────────────────────────────────
  Widget _buildFeedHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: Row(
          children: [
            Row(
              children: [
                Container(
                  width: 3, height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Community Feed',
                    style: KTextStyle.poppins(
                        fs: 13,
                        fw: FontWeight.w600,
                        c: AppColors.textPrimary)),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showCreatePostSheet(context),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_outlined,
                        size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Text('Post',
                        style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w600,
                            c: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Feed Body ──────────────────────────────────────────────────
  Widget _buildFeedBody() {
    return Obx(() {
      if (feedCtrl.isLoading.value) {
        return const Center(child: CustomCircularIndicator());
      }

      // Search filter
      final query    = _searchQuery.value.toLowerCase().trim();
      final filtered = query.isEmpty
          ? feedCtrl.posts
          : feedCtrl.posts.where((p) {
        return (p.content     ?? '').toLowerCase().contains(query) ||
            (p.posterName  ?? '').toLowerCase().contains(query) ||
            (p.companyName ?? '').toLowerCase().contains(query);
      }).toList();

      if (filtered.isEmpty) {
        return _EmptyFeed(
          isSearch: query.isNotEmpty,
          onRefresh: feedCtrl.refreshFeed,
        );
      }

      return RefreshIndicator(
        onRefresh: feedCtrl.refreshFeed,
        color: AppColors.primary,
        child: ListView.separated(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: filtered.length + (feedCtrl.hasMore.value ? 1 : 0),
          separatorBuilder: (_, __) =>
              Container(height: 6, color: AppColors.scaffoldBg),
          itemBuilder: (context, index) {
            // Load-more spinner at bottom
            if (index == filtered.length) {
              return Obx(() => feedCtrl.isLoadingMore.value
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CustomCircularIndicator()),
              )
                  : const SizedBox.shrink());
            }

            final post = filtered[index];
            return _FeedPostCard(
              post: post,
              isLikedByMe: feedCtrl.isLikedByMe(post),
              onLike: () => feedCtrl.toggleLike(post.id),
            );
          },
        ),
      );
    });
  }

  void _showCreatePostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _CreatePostSheet(feedCtrl: feedCtrl),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STICKY SEARCH DELEGATE
// ═══════════════════════════════════════════════════════════════════
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _SearchBarDelegate({required this.child});

  @override double get minExtent => 56;
  @override double get maxExtent => 56;
  @override Widget build(_, __, ___) => child;
  @override bool shouldRebuild(covariant _SearchBarDelegate old) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  FEED POST CARD  —  CommunityFeedModel
// ═══════════════════════════════════════════════════════════════════
class _FeedPostCard extends StatelessWidget {
  final CommunityFeedModel post;
  final bool isLikedByMe;
  final VoidCallback onLike;

  const _FeedPostCard({
    required this.post,
    required this.isLikedByMe,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final isVendor   = post.posterType == 'vendor';
    final isAdmin    = post.posterType == 'admin';
    final isVerified = post.verification == 'verified';

    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Author Row ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PostAvatar(
                  imageUrl: WorkerFeedController.fullUrl(post.posterImage),
                  name: post.posterName ?? '',
                  size: 42,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + verified tick
                      Row(children: [
                        Flexible(
                          child: Text(
                            post.posterName ?? 'Unknown',
                            style: KTextStyle.poppins(
                                fs: 13, fw: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              size: 14, color: AppColors.primary),
                        ],
                      ]),
                      const SizedBox(height: 3),
                      // Role badge + company
                      Row(children: [
                        _RoleBadge(
                            isVendor: isVendor, isAdmin: isAdmin),
                        if (post.companyName != null &&
                            post.companyName!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '· ${post.companyName}',
                              style: KTextStyle.poppins(
                                  fs: 11, c: AppColors.textHint),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Time + feeling
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _timeAgo(post.createdAt ?? DateTime.now()),
                      style: KTextStyle.poppins(
                          fs: 10, c: AppColors.textHint),
                    ),
                    if (post.feeling != null &&
                        post.feeling!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _FeelingBadge(feeling: post.feeling!),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Content text ───────────────────────────────────────
          if (post.content != null && post.content!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(
                post.content!,
                style: KTextStyle.poppins(
                    fs: 13, c: AppColors.textPrimary, height: 1.5),
              ),
            ),

          // ── Images ────────────────────────────────────────────
          if (post.images != null && post.images!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _PostImagesDisplay(images: post.images!),
          ],

          // ── Video ─────────────────────────────────────────────
          if (post.video != null && post.video!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _PostVideoThumb(
              videoUrl: WorkerFeedController.fullUrl(post.video),
            ),
          ],

          const SizedBox(height: 8),

          // ── Likes + comments count ─────────────────────────────
          if ((post.likesCount ?? 0) > 0 ||
              (post.commentsCount ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(children: [
                if ((post.likesCount ?? 0) > 0) ...[
                  const Icon(Icons.favorite_rounded,
                      size: 12, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text('${post.likesCount}',
                      style: KTextStyle.poppins(
                          fs: 11, c: AppColors.textHint)),
                  const SizedBox(width: 8),
                ],
                if ((post.commentsCount ?? 0) > 0)
                  Text('${post.commentsCount} comments',
                      style: KTextStyle.poppins(
                          fs: 11, c: AppColors.textHint)),
              ]),
            ),

          Container(height: 0.5, color: AppColors.divider),

          // ── Action Row ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              _ActionButton(
                icon: isLikedByMe
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: isLikedByMe ? 'Liked' : 'Like',
                color: isLikedByMe
                    ? AppColors.primary
                    : AppColors.textHint,
                onTap: onLike,
              ),
              _ActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Comment',
                color: AppColors.textHint,
                onTap: () => CommentsSheet.open(context, post.id ?? ''),
              ),
              _ActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                color: AppColors.textHint,
                onTap: () {},
              ),
            ]),
          ),

          Container(
              height: 0.5,
              margin: const EdgeInsets.only(top: 4),
              color: AppColors.divider),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1)  return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours   < 24) return '${d.inHours}h';
    if (d.inDays    < 7)  return '${d.inDays}d';
    return '${(d.inDays / 7).floor()}w';
  }
}

// ── Network avatar with initials fallback ────────────────────────
class _PostAvatar extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double size;

  const _PostAvatar({
    required this.imageUrl,
    required this.name,
    this.size = 42,
  });

  String get _initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final n = name.trim();
    return n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return AvatarCircle(initials: _initials, size: size);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.network(
        imageUrl,
        width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            AvatarCircle(initials: _initials, size: size),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return AvatarCircle(initials: _initials, size: size);
        },
      ),
    );
  }
}

// ── Role badge ────────────────────────────────────────────────────
class _RoleBadge extends StatelessWidget {
  final bool isVendor;
  final bool isAdmin;
  const _RoleBadge({required this.isVendor, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final Color bg   = isAdmin
        ? Colors.purple.withOpacity(0.12)
        : isVendor
        ? AppColors.primary.withOpacity(0.10)
        : Colors.green.withOpacity(0.10);
    final Color text = isAdmin
        ? Colors.purple.shade700
        : isVendor
        ? AppColors.primary
        : Colors.green.shade700;
    final String label =
    isAdmin ? 'Admin' : isVendor ? 'Vendor' : 'Worker';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: KTextStyle.poppins(
              fs: 10, fw: FontWeight.w600, c: text)),
    );
  }
}

// ── Feeling badge ─────────────────────────────────────────────────
class _FeelingBadge extends StatelessWidget {
  final String feeling;
  const _FeelingBadge({required this.feeling});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('😊', style: TextStyle(fontSize: 9)),
        const SizedBox(width: 3),
        Text(feeling,
            style: KTextStyle.poppins(fs: 9, c: Colors.amber.shade800)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  POST IMAGES DISPLAY — adaptive single + 2 / 3+ grid, tap = gallery
// ═══════════════════════════════════════════════════════════════════
// Single image apne REAL aspect-ratio me dikhti hai (vertical lambi,
// horizontal wide). Extreme sizes pe blur background + poori image.
class _PostImagesDisplay extends StatelessWidget {
  final List<String> images;
  const _PostImagesDisplay({required this.images});

  @override
  Widget build(BuildContext context) {
    final urls  = images.map(WorkerFeedController.fullUrl).toList();
    final count = urls.length;

    if (count == 1) {
      return _AdaptiveNetImg(
        url: urls[0],
        onTap: () => _openImageGallery(urls, 0),
      );
    }

    if (count == 2) {
      return Row(children: [
        Expanded(
            child: GestureDetector(
                onTap: () => _openImageGallery(urls, 0),
                child: _NetImg(url: urls[0], height: 200))),
        const SizedBox(width: 2),
        Expanded(
            child: GestureDetector(
                onTap: () => _openImageGallery(urls, 1),
                child: _NetImg(url: urls[1], height: 200))),
      ]);
    }

    return Column(children: [
      GestureDetector(
        onTap: () => _openImageGallery(urls, 0),
        child: _NetImg(url: urls[0], height: 210, width: double.infinity),
      ),
      const SizedBox(height: 2),
      Row(children: [
        for (int i = 1; i < count && i < 4; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => _openImageGallery(urls, i),
              child: Stack(children: [
                _NetImg(url: urls[i], height: 110),
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
class _AdaptiveNetImg extends StatefulWidget {
  final String url;
  final VoidCallback? onTap;
  const _AdaptiveNetImg({required this.url, this.onTap});

  @override
  State<_AdaptiveNetImg> createState() => _AdaptiveNetImgState();
}

class _AdaptiveNetImgState extends State<_AdaptiveNetImg> {
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

// ── Fullscreen gallery — swipe (multi) + pinch-zoom + counter ──────
void _openImageGallery(List<String> urls, int initialIndex) {
  if (urls.isEmpty) return;
  Get.dialog(
    _ImageGalleryViewer(urls: urls, initialIndex: initialIndex),
    barrierColor: Colors.black,
    useSafeArea: false,
  );
}

class _ImageGalleryViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _ImageGalleryViewer({required this.urls, required this.initialIndex});

  @override
  State<_ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<_ImageGalleryViewer> {
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

class _NetImg extends StatelessWidget {
  final String url;
  final double height;
  final double? width;
  const _NetImg({required this.url, required this.height, this.width});

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

// ── Inline feed video — usi jagah play hoti hai (koi page nahi) ────
class _PostVideoThumb extends StatefulWidget {
  final String videoUrl;
  const _PostVideoThumb({required this.videoUrl});

  @override
  State<_PostVideoThumb> createState() => _PostVideoThumbState();
}

class _PostVideoThumbState extends State<_PostVideoThumb> {
  // Ek waqt me sirf ek video chale — nayi chale to purani pause
  static _PostVideoThumbState? _playingNow;

  // Session-global mute (LinkedIn jaisa): app me first time = muted;
  // user ek baar unmute kare to baaki feed videos bhi sound ke saath.
  static bool _feedMuted = true;

  VideoPlayerController? _ctrl;
  bool _initializing = false;
  bool _failed = false;

  // ── Advanced controls state ──
  bool _showControls = true; // overlay dikh raha hai?
  double _speed = 1.0;       // playback speed (1x default)
  int _seekFlash = 0;        // -1 = «10s flash, +1 = 10s» flash
  bool _userPaused = false;  // user ne khud pause kiya (autoplay override na kare)
  Timer? _hideTimer;
  Timer? _flashTimer;

  bool get _ready => _ctrl?.value.isInitialized ?? false;
  bool get _ended =>
      _ready && _ctrl!.value.position >= _ctrl!.value.duration;

  /// [auto] = scroll-autoplay (FB-style): muted start + controls hidden.
  /// Manual tap = sound ke saath + controls dikhte hain.
  Future<void> _start({bool auto = false}) async {
    if (_initializing || _ready) return;
    setState(() {
      _initializing = true;
      _failed = false;
    });
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await c.initialize();
      if (!mounted) {
        c.dispose();
        return;
      }
      // Doosri chal rahi video pause karo
      if (_playingNow != null && _playingNow != this) {
        _playingNow!._ctrl?.pause();
      }
      _playingNow = this;
      _ctrl = c..addListener(_onTick);
      // Session mute state apply (first time muted, unmute ke baad sound)
      await c.setVolume(_feedMuted ? 0 : 1);
      _showControls = !auto; // autoplay = clean look, manual = controls
      await c.play();
      _scheduleHide();
    } catch (_) {
      _failed = true;
    }
    if (mounted) setState(() => _initializing = false);
  }

  // ── Scroll-based autoplay (Facebook jaisa) ────────────────────────
  // ≥60% dikhe → play (pehli baar muted-autoplay), ≤40% → pause.
  void _onVisibility(VisibilityInfo info) {
    if (!mounted) return;
    final f = info.visibleFraction;
    if (f >= 0.6) {
      if (!_ready) {
        if (!_initializing && !_failed) _start(auto: true);
        return;
      }
      final c = _ctrl!;
      if (!c.value.isPlaying && !_userPaused && !_ended) {
        if (_playingNow != null && _playingNow != this) {
          _playingNow!._ctrl?.pause();
        }
        _playingNow = this;
        c.setVolume(_feedMuted ? 0 : 1); // latest session state apply
        c.play();
      }
    } else if (f <= 0.4) {
      // Screen se bahar → pause (position yaad rehti hai)
      if (_ready && _ctrl!.value.isPlaying) _ctrl!.pause();
      _userPaused = false; // wapas aane par autoplay phir chale
    }
  }

  void _onTick() {
    if (mounted) setState(() {}); // progress / ended state update
  }

  void _togglePlay() {
    final c = _ctrl;
    if (c == null) return;
    if (_ended) {
      c.seekTo(Duration.zero);
      c.play();
      _playingNow = this;
      _userPaused = false;
    } else if (c.value.isPlaying) {
      c.pause();
      _userPaused = true; // user ka pause — autoplay override nahi karega
    } else {
      if (_playingNow != null && _playingNow != this) {
        _playingNow!._ctrl?.pause();
      }
      _playingNow = this;
      c.play();
      _userPaused = false;
    }
    _scheduleHide();
  }

  void _toggleMute() {
    _feedMuted = !_feedMuted; // global — agli videos pe bhi apply hoga
    _ctrl?.setVolume(_feedMuted ? 0 : 1);
    setState(() {});
    _scheduleHide();
  }

  // ── ±10s seek (buttons + double-tap) ──────────────────────────────
  void _seekBy(int seconds) {
    final c = _ctrl;
    if (c == null || !_ready) return;
    final target = c.value.position + Duration(seconds: seconds);
    final max = c.value.duration;
    c.seekTo(target < Duration.zero
        ? Duration.zero
        : (target > max ? max : target));
    // Flash indicator («10s / 10s»)
    _flashTimer?.cancel();
    setState(() => _seekFlash = seconds.sign);
    _flashTimer = Timer(const Duration(milliseconds: 550), () {
      if (mounted) setState(() => _seekFlash = 0);
    });
    _scheduleHide();
  }

  // Double-tap: left half = -10s, right half = +10s (YouTube jaisa)
  void _onDoubleTapDown(TapDownDetails d, double width) {
    _seekBy(d.localPosition.dx < width / 2 ? -10 : 10);
  }

  // ── Playback speed cycle: 1x → 1.5x → 2x → 0.5x → 1x ─────────────
  void _cycleSpeed() {
    const speeds = [1.0, 1.5, 2.0, 0.5];
    _speed = speeds[(speeds.indexOf(_speed) + 1) % speeds.length];
    _ctrl?.setPlaybackSpeed(_speed);
    setState(() {});
    _scheduleHide();
  }

  // ── Controls auto-hide (chalte waqt 2.5s baad chhup jaate hain) ───
  void _scheduleHide() {
    _hideTimer?.cancel();
    if (_ctrl?.value.isPlaying ?? false) {
      _hideTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted && (_ctrl?.value.isPlaying ?? false)) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _tapVideo() {
    setState(() => _showControls = !_showControls);
    _scheduleHide();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    if (_playingNow == this) _playingNow = null;
    _hideTimer?.cancel();
    _flashTimer?.cancel();
    _ctrl?.removeListener(_onTick);
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Video ke REAL aspect-ratio ke hisaab se box:
    //  • horizontal (16:9) → wide box
    //  • vertical (9:16)   → lamba box (cap 0.72 taaki feed me balanced rahe)
    // Init se pehle neutral 16:9; init ke baad smooth resize.
    // VisibilityDetector = scroll autoplay/pause (FB-style).
    final child = !_ready
        ? AspectRatio(aspectRatio: 16 / 9, child: _placeholder())
        : AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: AspectRatio(
              aspectRatio: (_ctrl!.value.aspectRatio > 0
                      ? _ctrl!.value.aspectRatio
                      : 16 / 9)
                  .clamp(0.72, 1.91)
                  .toDouble(),
              child: _player(),
            ),
          );
    return VisibilityDetector(
      key: Key('feed-video-${widget.videoUrl}'),
      onVisibilityChanged: _onVisibility,
      child: child,
    );
  }

  // ── Play hone se pehle: thumbnail + play button ──────────────────
  Widget _placeholder() {
    return GestureDetector(
      onTap: _start,
      child: Container(
        color: Colors.black87,
        child: Center(
          child: _initializing
              ? const SizedBox(
                  width: 34, height: 34,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : _failed
                  ? Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.refresh_rounded,
                          color: Colors.white70, size: 36),
                      const SizedBox(height: 6),
                      Text('Load nahi hua — retry',
                          style: KTextStyle.poppins(
                              fs: 11, c: Colors.white70)),
                    ])
                  : const Icon(Icons.play_circle_fill_rounded,
                      color: Colors.white, size: 54),
        ),
      ),
    );
  }

  // ── Inline player: advanced controls (seek/speed/time/auto-hide) ──
  Widget _player() {
    final c = _ctrl!;
    final playing   = c.value.isPlaying;
    final buffering = c.value.isBuffering;
    final controlsVisible = _showControls || !playing;

    return LayoutBuilder(builder: (context, box) {
      return GestureDetector(
        onTap: _tapVideo,
        onDoubleTapDown: (d) => _onDoubleTapDown(d, box.maxWidth),
        onDoubleTap: () {}, // double-tap register hone ke liye zaroori
        child: Container(
          color: Colors.black,
          child: Stack(alignment: Alignment.center, children: [
            // Video (real aspect ratio me)
            Center(
              child: AspectRatio(
                aspectRatio:
                    c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9,
                child: VideoPlayer(c),
              ),
            ),

            // Buffering spinner
            if (buffering && playing)
              const SizedBox(
                width: 38, height: 38,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white70),
              ),

            // ── Double-tap seek flash («10s / 10s») ────────────────
            if (_seekFlash != 0)
              Positioned(
                left: _seekFlash < 0 ? 24 : null,
                right: _seekFlash > 0 ? 24 : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      _seekFlash < 0
                          ? Icons.fast_rewind_rounded
                          : Icons.fast_forward_rounded,
                      color: Colors.white, size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text('10s',
                        style: KTextStyle.poppins(
                            fs: 12, fw: FontWeight.w600, c: Colors.white)),
                  ]),
                ),
              ),

            // ── LinkedIn-style persistent mini bar (controls hidden par) ──
            // Remaining time + mute — autoplay ke dauran hamesha visible.
            if (!controlsVisible)
              Positioned(
                right: 8,
                bottom: 8,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _fmt(c.value.duration - c.value.position),
                      style: KTextStyle.poppins(
                          fs: 10.5, fw: FontWeight.w600, c: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _muteButton(),
                ]),
              ),

            // ── Controls overlay (auto-hide) — poore player pe fill ──
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !controlsVisible,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.60),
                        ],
                      ),
                    ),
                    child: Stack(children: [
                      // Center: -10s | play/pause | +10s
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ctrlBtn(Icons.replay_10_rounded, 24,
                                () => _seekBy(-10)),
                            const SizedBox(width: 28),
                            _ctrlBtn(
                              _ended
                                  ? Icons.replay_rounded
                                  : playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                              34,
                              _togglePlay,
                              big: true,
                            ),
                            const SizedBox(width: 28),
                            _ctrlBtn(Icons.forward_10_rounded, 24,
                                () => _seekBy(10)),
                          ],
                        ),
                      ),

                      // Top-right: speed
                      Positioned(
                        top: 8, right: 10,
                        child: GestureDetector(
                          onTap: _cycleSpeed,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _speed == 1.0
                                  ? '1x'
                                  : '${_speed.toStringAsFixed(_speed % 1 == 0 ? 0 : 1)}x',
                              style: KTextStyle.poppins(
                                  fs: 11.5,
                                  fw: FontWeight.w600,
                                  c: Colors.white),
                            ),
                          ),
                        ),
                      ),

                      // ── Bottom bar (FIXED at bottom) ──────────────
                      //  "00:12 / 01:30" + progress bar (mute corner me)
                      Positioned(
                        left: 12, right: 50, bottom: 6,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_fmt(c.value.position)} / ${_fmt(c.value.duration)}',
                              style: KTextStyle.poppins(
                                  fs: 11, c: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: VideoProgressIndicator(
                                c,
                                allowScrubbing: true,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6),
                                colors: const VideoProgressColors(
                                  playedColor: AppColors.primary,
                                  bufferedColor: Colors.white38,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Mute — hamesha wahi corner (LinkedIn jaisa)
                      Positioned(
                        right: 8, bottom: 8,
                        child: _muteButton(),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }

  // Mute/unmute button — dono states me same corner, same look
  Widget _muteButton() {
    return GestureDetector(
      onTap: _toggleMute,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(
          _feedMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  // Round control button (center row)
  Widget _ctrlBtn(IconData icon, double size, VoidCallback onTap,
      {bool big = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: big ? 56 : 42,
        height: big ? 56 : 42,
        decoration: const BoxDecoration(
            color: Colors.black45, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: KTextStyle.poppins(
                      fs: 12, fw: FontWeight.w500, c: color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CREATE POST SHEET
//  ✅ Real API: POST /api/community/posts (form-data)
//  Fields: content (text), feeling (text), images (files), video (file)
// ═══════════════════════════════════════════════════════════════════
class _CreatePostSheet extends StatefulWidget {
  final WorkerFeedController feedCtrl;
  const _CreatePostSheet({required this.feedCtrl});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _textCtrl        = TextEditingController();
  final _picker          = ImagePicker();
  final _mediaItems      = <Map<String, String>>[].obs;
  final _selectedFeeling = RxnString(); // null = no feeling selected

  // Feeling options
  static const _feelings = [
    '😊 Good', '😄 Happy', '🎉 Excited', '💪 Motivated',
    '🙏 Grateful', '😎 Proud', '✨ Blessed', '😤 Determined',
  ];

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(
        imageQuality: 80, maxWidth: 1600, maxHeight: 1600);
    for (final img in picked) {
      if (_mediaItems.length < 9) {
        _mediaItems.add({'path': img.path, 'type': 'image'});
      }
    }
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null || _mediaItems.length >= 9) return; // cancel / full

    // 2 min se badi video allow nahi — pick karte hi rok do
    double durationSec = 0;
    try {
      final info = await VideoCompress.getMediaInfo(picked.path);
      durationSec = (info.duration ?? 0) / 1000.0; // ms → sec
    } catch (_) {/* duration na mile to aage badhne do */}

    if (durationSec > VideoCompressService.maxDurationSec) {
      _showVideoTooLongDialog();
      return;
    }
    _mediaItems.add({'path': picked.path, 'type': 'video'});
  }

  // ── 2 min se badi video — accha sa popup ──────────────────────────
  void _showVideoTooLongDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  shape: BoxShape.circle),
              child: const Icon(Icons.timer_off_outlined,
                  color: AppColors.error, size: 38),
            ),
            const SizedBox(height: 16),
            Text('Video Too Long',
                style: KTextStyle.poppins(fs: 18, fw: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Aap 2 minute se badi video upload nahi kar sakte.\n'
              'Kripya 2 minute se choti video select karein.',
              textAlign: TextAlign.center,
              style: KTextStyle.poppins(
                  fs: 13, c: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CustomButton(label: 'OK', onTap: () => Get.back()),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600);
    if (picked != null && _mediaItems.length < 9) {
      _mediaItems.add({'path': picked.path, 'type': 'image'});
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  // ── Submit ──────────────────────────────────────────────────────
  Future<void> _submit() async {
    // Multiple attempts guard (compress/upload chal raha ho to ignore)
    if (widget.feedCtrl.isPosting.value) return;
    final text = _textCtrl.text;
    if (text.trim().isEmpty && _mediaItems.isEmpty) return;

    // Separate images and video
    final imagePaths = _mediaItems
        .where((m) => m['type'] == 'image')
        .map((m) => m['path']!)
        .toList();
    final videoPath = _mediaItems
        .firstWhereOrNull((m) => m['type'] == 'video')?['path'];

    // Strip emoji from feeling label — "😊 Good" → "Good"
    String? cleanFeeling;
    if (_selectedFeeling.value != null) {
      cleanFeeling = _selectedFeeling.value!
          .replaceAll(RegExp(r'[^\x00-\x7F]+\s*'), '')
          .trim();
    }

    // API call — video ho to pehle compress hoga (progress Post button par).
    final message = await widget.feedCtrl.submitPost(
      description: text,
      feeling:     cleanFeeling,
      imagePaths:  imagePaths,
      videoPath:   videoPath,
    );

    // Success par hi sheet band karo. Fail (video bada / compress fail /
    // network) par sheet open rehti hai taaki user chhoti video choose kare —
    // error snackbar submitPost/compress service dikha chuki hoti hai.
    if (message != null) {
      if (mounted) Get.back();
      await Future.delayed(const Duration(milliseconds: 300));
      Get.snackbar(
        'Posted! 🎉',
        message, // API se aaya hua: "Post created successfully"
        snackPosition:   SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText:       Colors.white,
        duration:        const Duration(seconds: 3),
        margin:          const EdgeInsets.all(12),
        borderRadius:    12,
        icon: const Icon(Icons.check_circle_rounded,
            color: Colors.white, size: 22),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Sheet max height — keyboard + status bar chhodkar (overflow se bachao)
    final maxSheetH =
        media.size.height - media.viewInsets.bottom - media.padding.top - 12;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetH),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ────────────────────────────────────────
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),

              // ── Header ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(children: [
                  Text('Create Post',
                      style: KTextStyle.poppins(
                          fs: 15, fw: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                          color: AppColors.scaffoldBg,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded,
                          size: 16,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ]),
              ),
              Container(height: 0.5, color: AppColors.divider),

              // ── Scrollable middle (text + feeling + media) ────
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
              // ── Text input ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _textCtrl,
                  maxLines: 4,
                  minLines: 3,
                  style: KTextStyle.poppins(
                      fs: 13, c: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText:
                    'Share something with the community...',
                    hintStyle: KTextStyle.poppins(
                        fs: 13, c: AppColors.textHint),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                    isDense: true,
                  ),
                ),
              ),

              // ── Feeling Picker ────────────────────────────────
              SizedBox(
                height: 38,
                child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _feelings.map((f) {
                    final selected = _selectedFeeling.value == f;
                    return GestureDetector(
                      onTap: () => _selectedFeeling.value =
                      selected ? null : f,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.scaffoldBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          f,
                          style: KTextStyle.poppins(
                            fs: 11,
                            fw: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            c: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )),
              ),

              const SizedBox(height: 8),

              // ── Media preview ─────────────────────────────────
              Obx(() {
                if (_mediaItems.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _MediaPreviewGrid(
                    items: _mediaItems,
                    onRemove: (i) => _mediaItems.removeAt(i),
                  ),
                );
              }),
                    ],
                  ),
                ),
              ),

              Container(height: 0.5, color: AppColors.divider),

              // ── Compression progress bar (video ke waqt full-width) ─
              Obx(() {
                if (!widget.feedCtrl.isCompressing.value) {
                  return const SizedBox.shrink();
                }
                final progress = widget.feedCtrl.compressProgress.value;
                final pct = (progress * 100).round();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.movie_creation_outlined,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text('Compressing video… $pct%',
                            style: KTextStyle.poppins(
                                fs: 12,
                                fw: FontWeight.w600,
                                c: AppColors.primary)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress > 0 ? progress : null,
                          minHeight: 5,
                          backgroundColor: AppColors.divider,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // ── Media buttons + Post button ───────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(children: [
                  // Media buttons — Expanded + horizontal scroll (no overflow)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        _MediaActionBtn(
                            icon: Icons.camera_alt_outlined,
                            label: 'Camera',
                            onTap: _pickFromCamera),
                        const SizedBox(width: 6),
                        _MediaActionBtn(
                            icon: Icons.photo_library_outlined,
                            label: 'Photo',
                            onTap: _pickImages),
                        const SizedBox(width: 6),
                        _MediaActionBtn(
                            icon: Icons.videocam_outlined,
                            label: 'Video',
                            onTap: _pickVideo),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Post button — busy me sirf spinner (narrow, no overflow)
                  Obx(() {
                    final busy = widget.feedCtrl.isPosting.value;
                    return GestureDetector(
                      onTap: busy ? null : _submit,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: busy
                              ? AppColors.primary.withValues(alpha: 0.6)
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: busy
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text('Post',
                                style: KTextStyle.poppins(
                                    fs: 13,
                                    fw: FontWeight.w600,
                                    c: Colors.white)),
                      ),
                    );
                  }),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Media Preview Grid (create sheet) ────────────────────────────
class _MediaPreviewGrid extends StatelessWidget {
  final RxList<Map<String, String>> items;
  final void Function(int) onRemove;
  const _MediaPreviewGrid(
      {required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final count = items.length;
    if (count == 1) {
      return _MediaThumb(
          item: items[0],
          onRemove: () => onRemove(0),
          height: 180,
          width: double.infinity);
    }
    if (count == 2) {
      return Row(children: [
        Expanded(
            child: _MediaThumb(
                item: items[0],
                onRemove: () => onRemove(0),
                height: 130)),
        const SizedBox(width: 4),
        Expanded(
            child: _MediaThumb(
                item: items[1],
                onRemove: () => onRemove(1),
                height: 130)),
      ]);
    }
    return Column(children: [
      _MediaThumb(
          item: items[0],
          onRemove: () => onRemove(0),
          height: 140,
          width: double.infinity),
      const SizedBox(height: 4),
      Row(children: [
        for (int i = 1; i < count && i < 4; i++) ...[
          Expanded(
            child: Stack(children: [
              _MediaThumb(
                  item: items[i],
                  onRemove: () => onRemove(i),
                  height: 80),
              if (i == 3 && count > 4)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6)),
                    child: Center(
                      child: Text('+${count - 3}',
                          style: KTextStyle.poppins(
                              fs: 15,
                              fw: FontWeight.bold,
                              c: Colors.white)),
                    ),
                  ),
                ),
            ]),
          ),
          if (i < count - 1 && i < 3) const SizedBox(width: 4),
        ],
      ]),
    ]);
  }
}

class _MediaThumb extends StatelessWidget {
  final Map<String, String> item;
  final VoidCallback onRemove;
  final double height;
  final double? width;
  const _MediaThumb({
    required this.item,
    required this.onRemove,
    required this.height,
    this.width,
  });

  bool get _isVideo => item['type'] == 'video';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width, height: height,
      child: Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _isVideo
              ? _VideoThumb(
                  path: item['path']!,
                  height: height,
                  width: width,
                )
              : Image.file(
            File(item['path']!),
            fit: BoxFit.cover,
            width: width ?? double.infinity,
            height: height,
          ),
        ),
        Positioned(
          top: 5, right: 5,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 13),
            ),
          ),
        ),
        if (_isVideo)
          Positioned(
            bottom: 5, left: 6,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(4)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.videocam_outlined,
                    color: Colors.white, size: 11),
                const SizedBox(width: 3),
                Text('Video',
                    style:
                    KTextStyle.poppins(fs: 9, c: Colors.white)),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ── Video thumbnail (real frame) + tap-to-play ───────────────────
class _VideoThumb extends StatefulWidget {
  final String path;
  final double height;
  final double? width;
  const _VideoThumb({required this.path, required this.height, this.width});

  @override
  State<_VideoThumb> createState() => _VideoThumbState();
}

class _VideoThumbState extends State<_VideoThumb> {
  Uint8List? _frame;

  @override
  void initState() {
    super.initState();
    _loadFrame();
  }

  Future<void> _loadFrame() async {
    try {
      final bytes =
          await VideoCompress.getByteThumbnail(widget.path, quality: 40);
      if (mounted) setState(() => _frame = bytes);
    } catch (_) {/* frame na mile to black bg + play icon */}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => VideoPreviewPlayer.open(widget.path), // tap → play
      child: Container(
        color: Colors.black,
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: Stack(fit: StackFit.expand, children: [
          if (_frame != null) Image.memory(_frame!, fit: BoxFit.cover),
          const Center(
            child: Icon(Icons.play_circle_fill_rounded,
                color: Colors.white, size: 40),
          ),
        ]),
      ),
    );
  }
}

class _MediaActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MediaActionBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: AppColors.scaffoldBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(label,
              style: KTextStyle.poppins(
                  fs: 11,
                  fw: FontWeight.w500,
                  c: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PREMIUM BUTTON — 👑 + ghoomti golden ring (app bar)
// ═══════════════════════════════════════════════════════════════════
class _PremiumButton extends StatefulWidget {
  final VoidCallback? onTap;
  const _PremiumButton({this.onTap});

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    // Ring continuously ghoomti hai (3s / rotation)
    _spin = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? () => Get.to(() => const WorkerPlansView()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Stack(alignment: Alignment.center, children: [
                // Ghoomti hui golden gradient ring
                RotationTransition(
                  turns: _spin,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Color(0xFFF5A623),
                          Color(0xFFFFE9B8),
                          Color(0xFFF5A623),
                          Color(0xFFB97700),
                          Color(0xFFF5A623),
                        ],
                      ),
                    ),
                  ),
                ),
                // Inner circle + crown (ye ghoomta nahi)
                Container(
                  width: 27,
                  height: 27,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF8EA),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('👑', style: TextStyle(fontSize: 14)),
                ),
              ]),
            ),
            const SizedBox(width: 3),
            Text('Plan',
                style: KTextStyle.poppins(
                    fs: 11, fw: FontWeight.w700, c: const Color(0xFFB97700))),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  EMPTY FEED
// ═══════════════════════════════════════════════════════════════════
class _EmptyFeed extends StatelessWidget {
  final bool isSearch;
  final Future<void> Function() onRefresh;
  const _EmptyFeed({this.isSearch = false, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSearch
                      ? Icons.search_off_rounded
                      : Icons.dynamic_feed_outlined,
                  size: 52, color: Colors.grey.shade300,
                ),
                const SizedBox(height: 14),
                Text(
                  isSearch ? 'No results found' : 'No posts yet',
                  style: KTextStyle.poppins(
                      fs: 14,
                      fw: FontWeight.w500,
                      c: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  isSearch
                      ? 'Try different keywords'
                      : 'Pull down to refresh',
                  style: KTextStyle.poppins(
                      fs: 12, c: AppColors.textHint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}