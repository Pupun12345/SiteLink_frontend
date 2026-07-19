import 'dart:convert';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import '../../../../core/models/community_feed_models.dart'; // apna path adjust karo
import '../../../../core/services/session_service.dart';
import '../../../../core/services/video_compress_service.dart';
import 'worker_profile_controller.dart';

// ─────────────────────────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────────────────────────
const String _kHost = "https://sitelink-backend-4.onrender.com";

class _Ep {
  static const String feed       = "$_kHost/api/community/feed";
  static const String posts      = "$_kHost/api/community/posts";
  static String like  (String id) => "$_kHost/api/community/posts/$id/like";
  static String delete(String id) => "$_kHost/api/community/posts/$id";
}

/// File extension se sahi MIME type (multipart Content-Type ke liye).
MediaType _mediaTypeFor(String path) {
  final ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return MediaType('image', 'jpeg');
    case 'png':
      return MediaType('image', 'png');
    case 'gif':
      return MediaType('image', 'gif');
    case 'webp':
      return MediaType('image', 'webp');
    case 'heic':
      return MediaType('image', 'heic');
    case 'mp4':
      return MediaType('video', 'mp4');
    case 'mov':
      return MediaType('video', 'quicktime');
    case 'avi':
      return MediaType('video', 'x-msvideo');
    case 'mkv':
      return MediaType('video', 'x-matroska');
    default:
      return MediaType('application', 'octet-stream');
  }
}

/// Path se file ka naam (multipart filename ke liye).
String _basename(String path) => path.split(RegExp(r'[/\\]')).last;

// ═══════════════════════════════════════════════════════════════════
//  WORKER FEED CONTROLLER
// ═══════════════════════════════════════════════════════════════════
class WorkerFeedController extends GetxController {
  // ── Observables ─────────────────────────────────────────────────
  final posts         = <CommunityFeedModel>[].obs;
  final isLoading     = false.obs;
  final isPosting     = false.obs;
  final isLoadingMore = false.obs;
  final hasMore       = true.obs;

  // ── Video compression state (create-post UI observe karta hai) ──
  final isCompressing    = false.obs;
  final compressProgress = 0.0.obs; // 0.0 – 1.0
  final _videoCompressor = VideoCompressService();

  // ── Pagination ──────────────────────────────────────────────────
  int _page       = 1;
  int _totalPages = 1;

  // ── Session (SessionService = single source) ────────────────────
  String get _token         => SessionService.to.token;
  String get _currentUserId => SessionService.to.userId;
  String get _currentName   => SessionService.to.userName;

  Map<String, String> get _headers => {
    "Content-Type":  "application/json",
    "Accept":        "application/json",
    "Authorization": "Bearer $_token",
  };

  @override
  void onInit() {
    super.onInit();
    fetchFeed();
  }

  // ═══════════════════════════════════════════════════════════════
  //  GET FEED  ──  GET /api/community/feed?page=X&limit=10
  // ═══════════════════════════════════════════════════════════════
  Future<void> fetchFeed({int page = 1}) async {
    page == 1 ? isLoading.value = true : isLoadingMore.value = true;

    try {
      final uri = Uri.parse("${_Ep.feed}?page=$page&limit=10");
      if (kDebugMode) print("[Feed] GET $uri");

      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) print("[Feed] ${res.statusCode} | ${res.body}");

      if (res.statusCode == 200) {
        final parsed = CommunityFeedData.fromJson(jsonDecode(res.body));
        final list   = parsed.data ?? [];

        page == 1 ? posts.assignAll(list) : posts.addAll(list);

        _page       = parsed.pagination?.current ?? page;
        _totalPages = parsed.pagination?.pages   ?? 1;
        hasMore.value = _page < _totalPages;
      } else {
        Get.snackbar("Error", "Feed load nahi ho saka",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      if (kDebugMode) print("[Feed] fetchFeed error: $e");
      Get.snackbar("Error", "Network error",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value     = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshFeed() async {
    _page = 1; _totalPages = 1; hasMore.value = true;
    await fetchFeed(page: 1);
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value) return;
    await fetchFeed(page: _page + 1);
  }

  // ═══════════════════════════════════════════════════════════════
  //  CREATE POST  ──  POST /api/community/posts
  //  form-data: content, feeling, images (files), video (file)
  // ═══════════════════════════════════════════════════════════════
  // Return type: String? — success hone par API ka message return karta hai,
  // fail hone par null. Snackbar caller (sheet) dikhata hai — sheet band hone ke baad.
  Future<String?> submitPost({
    required String description,
    String?       feeling,
    List<String>  imagePaths = const [],
    String?       videoPath,
  }) async {
    if (description.trim().isEmpty && imagePaths.isEmpty && videoPath == null) {
      return null;
    }
    if (isPosting.value) return null; // multiple attempts guard

    isPosting.value = true;
    String? uploadVideoPath = videoPath;
    try {
      // ── Video: compress + size-validate (upload se pehle) ─────
      if (videoPath != null) {
        isCompressing.value = true;
        compressProgress.value = 0;
        final result = await _videoCompressor.compress(
          videoPath,
          onProgress: (p) => compressProgress.value = p,
        );
        isCompressing.value = false;
        if (!result.success) {
          // Compressed bhi bada / compress fail → upload block.
          Get.snackbar('Video', result.error ?? 'Video process nahi hua',
              snackPosition: SnackPosition.BOTTOM);
          return null;
        }
        uploadVideoPath = result.path; // sirf compressed upload hoga
      }

      // ── Multipart via dio (Postman jaisa) ──
      // camelCaseContentDisposition: true → part header "Content-Disposition"
      // (Capital) jaata hai, jaise browser/Postman bhejte hain. Backend ka
      // case-sensitive parser lowercase "content-disposition" reject karta tha
      // → "File upload failed". Isse wo fix ho jaata hai.
      final form = dio.FormData(camelCaseContentDisposition: true);
      if (description.trim().isNotEmpty) {
        form.fields.add(MapEntry('content', description.trim()));
      }
      if (feeling != null && feeling.isNotEmpty) {
        form.fields.add(MapEntry('feeling', feeling));
      }

      // Images (same key = "images"). filename + contentType zaroori —
      // warna backend (multer) reject karta hai → "File upload failed".
      for (final path in imagePaths) {
        form.files.add(MapEntry(
          'images',
          dio.MultipartFile.fromFileSync(
            path,
            filename: _basename(path),
            contentType: _mediaTypeFor(path),
          ),
        ));
      }

      // Video (compressed)
      final vPath = uploadVideoPath;
      if (vPath != null) {
        form.files.add(MapEntry(
          'video',
          dio.MultipartFile.fromFileSync(
            vPath,
            filename: _basename(vPath),
            contentType: _mediaTypeFor(vPath),
          ),
        ));
      }

      if (kDebugMode) {
        print("[Feed] POST ${_Ep.posts}");
        print("[Feed] fields: ${form.fields}");
        print("[Feed] files:  ${form.files.map((f) => f.value.filename)}");
      }

      final client = dio.Dio(dio.BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout:    const Duration(seconds: 120),
        validateStatus: (_) => true, // 400 ko throw mat karo, hum handle karenge
      ));
      final resp = await client.post(
        _Ep.posts,
        data: form,
        options: dio.Options(headers: {'Authorization': 'Bearer $_token'}),
      );

      final status = resp.statusCode ?? 0;
      if (kDebugMode) print("[Feed] createPost $status: ${resp.data}");

      final data = resp.data;
      final Map body = data is Map
          ? data
          : (data is String && data.isNotEmpty ? jsonDecode(data) as Map : {});

      if (status == 200 || status == 201) {
        final message =
            body['message']?.toString() ?? 'Post created successfully';
        await refreshFeed();
        // "My Posts" (Profile tab, GET /profile/me se) bhi turant refresh —
        // warna wahan naya post tab tak nahi dikhta jab tak manually pull-
        // to-refresh na karo. Tab open na ho to controller registered hi
        // nahi hoga, safe skip.
        if (Get.isRegistered<WorkerProfileController>()) {
          Get.find<WorkerProfileController>().fetchProfile();
        }
        return message; // ← sheet ko return karo, woh band hokar snackbar dikhayega
      } else {
        final errMsg = body['message']?.toString() ?? 'Post create nahi hua';
        // Error snackbar yahan dikhao (sheet context se bahar nahi jaana)
        Get.snackbar('Error', errMsg, snackPosition: SnackPosition.BOTTOM);
        return null;
      }
    } catch (e) {
      if (kDebugMode) print("[Feed] submitPost error: $e");
      Get.snackbar('Error', 'Network error — try again',
          snackPosition: SnackPosition.BOTTOM);
      return null;
    } finally {
      isPosting.value      = false;
      isCompressing.value  = false;
      compressProgress.value = 0;
      // Compressed temp/cache saaf karo (agar video tha)
      if (videoPath != null) {
        await _videoCompressor.cleanup();
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIKE / UNLIKE  ──  PUT /api/community/posts/{id}/like
  //  Same endpoint toggles like ↔ unlike
  // ═══════════════════════════════════════════════════════════════
  void toggleLike(String? postId) => _toggleLikeAsync(postId);

  Future<void> _toggleLikeAsync(String? postId) async {
    if (postId == null) return;
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post         = posts[idx];
    final wasLiked     = isLikedByMe(post);
    final prevCount    = post.likesCount ?? 0;
    final prevLikes    = List<Like>.from(post.likes ?? []);

    // ── Optimistic update ────────────────────────────────────────
    if (wasLiked) {
      post.likesCount = prevCount - 1;
      post.likes      = prevLikes.where((l) => l.userId != _currentUserId).toList();
    } else {
      post.likesCount = prevCount + 1;
      post.likes      = [...prevLikes, Like(userId: _currentUserId, userName: _currentName)];
    }
    posts.refresh();

    try {
      final res = await http
          .put(Uri.parse(_Ep.like(postId)), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) print("[Feed] like ${res.statusCode}: ${res.body}");

      if (res.statusCode == 200) {
        // Sync server count (the response returns updated likesCount)
        final body        = jsonDecode(res.body);
        final serverCount = body['data']?['likesCount'] as int?;
        if (serverCount != null) {
          post.likesCount = serverCount;
          posts.refresh();
        }
      } else {
        // ── Revert on failure ──────────────────────────────────
        post.likesCount = prevCount;
        post.likes      = prevLikes;
        posts.refresh();
      }
    } catch (e) {
      if (kDebugMode) print("[Feed] toggleLike error: $e");
      post.likesCount = prevCount;
      post.likes      = prevLikes;
      posts.refresh();
    }
  }

  // ── Check if current user liked this post ────────────────────────
  bool isLikedByMe(CommunityFeedModel post) {
    if (_currentUserId.isEmpty) return false;
    return (post.likes ?? []).any((l) => l.userId == _currentUserId);
  }

  // ═══════════════════════════════════════════════════════════════
  //  DELETE POST  ──  DELETE /api/community/posts/{id}
  // ═══════════════════════════════════════════════════════════════
  Future<void> deletePost(String? postId) async {
    if (postId == null || postId.isEmpty) return;

    final idx    = posts.indexWhere((p) => p.id == postId);
    final backup = idx != -1 ? posts[idx] : null;

    // ── Optimistic removal ────────────────────────────────────────
    if (idx != -1) posts.removeAt(idx);

    try {
      final res = await http
          .delete(Uri.parse(_Ep.delete(postId)), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) print("[Feed] delete ${res.statusCode}: ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        Get.snackbar("Deleted", "Post delete ho gaya",
            snackPosition: SnackPosition.BOTTOM);
      } else {
        // ── Revert ─────────────────────────────────────────────
        if (backup != null && idx != -1) posts.insert(idx, backup);
        final body = jsonDecode(res.body);
        Get.snackbar("Error", body['message']?.toString() ?? "Delete nahi ho saka",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      if (kDebugMode) print("[Feed] deletePost error: $e");
      if (backup != null && idx != -1) posts.insert(idx, backup);
      Get.snackbar("Error", "Network error",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Profile tab ke liye — current user ke posts filter karta hai by posterName
  List<CommunityFeedModel> getMyPosts(String posterName) {
    if (posterName.isEmpty) return [];
    return posts.where((p) => p.posterName == posterName).toList();
  }

  /// Partial path → full URL
  /// e.g. "/uploads/abc.jpg" → "https://sitelink.../uploads/abc.jpg"
  static String fullUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    final p = path.trim();
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    final normalized = p.replaceAll(r'\', '/');
    final clean = normalized.startsWith('/') ? normalized.substring(1) : normalized;
    return '$_kHost/$clean';
  }
}