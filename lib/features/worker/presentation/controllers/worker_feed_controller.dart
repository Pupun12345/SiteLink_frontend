import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import '../../../../app/config/app_config.dart';
import '../../../../core/models/community_feed_models.dart'; // apna path adjust karo
import '../../../../core/services/api_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/services/video_compress_service.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../shared/presentation/controllers/app_refresh.dart';
import '../../../../core/services/review_service.dart';

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
      final uri = Uri.parse("${ApiEndpoints.communityFeed}?page=$page&limit=10");
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
        AppSnackbar.error(message: "feed_load_failed".tr);
      }
    } catch (e) {
      if (kDebugMode) print("[Feed] fetchFeed error: $e");
      AppSnackbar.error(message: "network_error".tr);
    } finally {
      isLoading.value     = false;
      isLoadingMore.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  SEARCH  ──  GET /api/community/feed?search=...
  // ═══════════════════════════════════════════════════════════════
  // Pehle search sirf load hui posts (pehli 10) me hota tha — purani post
  // milti hi nahi thi. Ab server poore feed me dhoondhta hai: text, naam,
  // company aur likhne wale ki skills.
  final searchResults = <CommunityFeedModel>[].obs;
  final isSearching   = false.obs;
  Timer? _searchDebounce;
  int _searchSeq = 0;

  /// Har akshar par nahi — likhna rukne ke 400ms baad.
  void search(String query) {
    _searchDebounce?.cancel();
    final q = query.trim();
    if (q.isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }
    isSearching.value = true;
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    final seq = ++_searchSeq; // purane (dheemi) jawab naye ko overwrite na karein
    try {
      final uri = Uri.parse(ApiEndpoints.communityFeed).replace(
          queryParameters: {'page': '1', 'limit': '30', 'search': q});
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (seq != _searchSeq) return;
      if (res.statusCode == 200) {
        searchResults.assignAll(
            CommunityFeedData.fromJson(jsonDecode(res.body)).data ?? []);
      }
    } catch (e) {
      if (kDebugMode) print("[Feed] search error: $e");
    } finally {
      if (seq == _searchSeq) isSearching.value = false;
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
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
          AppSnackbar.warning(
              message: result.error ?? 'video_process_failed'.tr);
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
        print("[Feed] POST ${ApiEndpoints.communityPosts}");
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
        ApiEndpoints.communityPosts,
        data: form,
        options: dio.Options(headers: {'Authorization': 'Bearer $_token'}),
      );

      final status = resp.statusCode ?? 0;
      if (kDebugMode) print("[Feed] createPost $status: ${resp.data}");

      final data = resp.data;

      // nginx/proxy reject (413 — video/photos bahut badi) par body HTML
      // hoti hai; jsonDecode se pehle saaf message de do.
      final proxyError = proxyErrorMessage(status, data?.toString() ?? '');
      if (proxyError != null) {
        AppSnackbar.error(message: proxyError);
        return null;
      }

      final Map body = data is Map
          ? data
          : (data is String && data.isNotEmpty ? jsonDecode(data) as Map : {});

      if (status == 200 || status == 201) {
        final message =
            body['message']?.toString() ?? 'post_created_success'.tr;
        await refreshFeed();
        // Profile tab ka posts list + count bhi turant refresh — warna
        // wahan naya post aur badhi hui count tab tak nahi dikhti jab tak
        // manually pull-to-refresh na karo.
        //
        // Pehle yahan `fetchProfile()` bulaya jaata tha, par posts alag
        // endpoint se aate hain — isliye count kabhi update hi nahi hota
        // tha. Helper dono roles ka dhyaan rakhta hai.
        await refreshProfilePosts();
        // Post ban gayi — achha moment hai rating maangne ka. Service
        // khud dekh leti hai ki pehle maang chuke hain ya nahi.
        // `await` nahi karte: rating prompt ki wajah se sheet band hone
        // me der nahi honi chahiye.
        ReviewService.maybeAsk();
        return message; // ← sheet ko return karo, woh band hokar snackbar dikhayega
      } else {
        final errMsg = body['message']?.toString() ?? 'post_create_failed'.tr;
        // Error snackbar yahan dikhao (sheet context se bahar nahi jaana)
        AppSnackbar.error(message: errMsg);
        return null;
      }
    } catch (e) {
      if (kDebugMode) print("[Feed] submitPost error: $e");
      AppSnackbar.error(message: 'network_error_retry'.tr);
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
          .put(Uri.parse(ApiEndpoints.communityPostLike(postId)), headers: _headers)
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
          .delete(Uri.parse(ApiEndpoints.communityPostDelete(postId)), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) print("[Feed] delete ${res.statusCode}: ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        AppSnackbar.success(message: "post_deleted_success".tr);
        // Profile tab ka count bhi ghatna chahiye, warna delete ke baad
        // wahan purani ginti dikhti rehti hai.
        await refreshProfilePosts();
      } else {
        // ── Revert ─────────────────────────────────────────────
        if (backup != null && idx != -1) posts.insert(idx, backup);
        final body = jsonDecode(res.body);
        AppSnackbar.error(
            message: body['message']?.toString() ??
                "delete_failed_generic".tr);
      }
    } catch (e) {
      if (kDebugMode) print("[Feed] deletePost error: $e");
      if (backup != null && idx != -1) posts.insert(idx, backup);
      AppSnackbar.error(message: "network_error".tr);
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
  /// e.g. "/uploads/abc.jpg" → "http://host/uploads/abc.jpg"
  /// Most images already come back as absolute Cloudinary URLs — this is
  /// only a fallback for legacy relative paths. Uses [AppConfig.mediaBaseUrl]
  /// (no `/api` prefix) since `/uploads` is served from the backend's root.
  static String fullUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    final p = path.trim();
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    final normalized = p.replaceAll(r'\', '/');
    final clean = normalized.startsWith('/') ? normalized.substring(1) : normalized;
    return '${AppConfig.mediaBaseUrl}/$clean';
  }
}