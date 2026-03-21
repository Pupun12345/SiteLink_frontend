import 'package:get/get.dart';

// ═══════════════════════════════════════════════════════════════════
//  POST MODEL
// ═══════════════════════════════════════════════════════════════════
class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorInitials;
  final String authorRole; // 'vendor' | 'worker'
  final String? authorSkill;
  final String description;
  final String? imageUrl;
  final DateTime createdAt;
  final int likesCount;
  final bool isLikedByMe;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorInitials,
    required this.authorRole,
    this.authorSkill,
    required this.description,
    this.imageUrl,
    required this.createdAt,
    this.likesCount = 0,
    this.isLikedByMe = false,
  });

  PostModel copyWith({int? likesCount, bool? isLikedByMe}) => PostModel(
    id: id,
    authorId: authorId,
    authorName: authorName,
    authorInitials: authorInitials,
    authorRole: authorRole,
    authorSkill: authorSkill,
    description: description,
    imageUrl: imageUrl,
    createdAt: createdAt,
    likesCount: likesCount ?? this.likesCount,
    isLikedByMe: isLikedByMe ?? this.isLikedByMe,
  );
}

// ═══════════════════════════════════════════════════════════════════
//  WORKER FEED CONTROLLER
// ═══════════════════════════════════════════════════════════════════
class WorkerFeedController extends GetxController {
  final posts              = <PostModel>[].obs;
  final isLoading          = false.obs;
  final isPosting          = false.obs;
  final selectedImagePath  = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadPosts();
  }

  // ── Load ───────────────────────────────────────────────────────
  Future<void> _loadPosts() async {
    isLoading.value = true;
    // TODO: replace with API call
    await Future.delayed(const Duration(milliseconds: 700));
    posts.assignAll(_mockPosts);
    isLoading.value = false;
  }

  Future<void> refreshPosts() => _loadPosts();

  // ── Like ───────────────────────────────────────────────────────
  void toggleLike(String postId) {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = posts[idx];
    posts[idx] = post.copyWith(
      isLikedByMe: !post.isLikedByMe,
      likesCount: post.isLikedByMe ? post.likesCount - 1 : post.likesCount + 1,
    );
  }

  // ── Create post ────────────────────────────────────────────────
  Future<void> submitPost({
    required String description,
    String? imagePath,
  }) async {
    if (description.trim().isEmpty) return;
    isPosting.value = true;
    // TODO: upload image → API call
    await Future.delayed(const Duration(seconds: 1));
    posts.insert(
      0,
      PostModel(
        id: 'post_${DateTime.now().millisecondsSinceEpoch}',
        authorId: 'current_user',
        authorName: 'Ramesh Kumar',
        authorInitials: 'RK',
        authorRole: 'worker',
        authorSkill: 'Mason',
        description: description.trim(),
        imageUrl: imagePath,
        createdAt: DateTime.now(),
      ),
    );
    selectedImagePath.value = null;
    isPosting.value = false;
  }

  // ── Posts by user (for profile) ────────────────────────────────
  List<PostModel> getPostsByUser(String userId) =>
      posts.where((p) => p.authorId == userId).toList();

  // ── Mock data ──────────────────────────────────────────────────
  static final _mockPosts = [
    PostModel(
      id: 'post_001',
      authorId: 'vendor_001',
      authorName: 'Rajesh Construction',
      authorInitials: 'RC',
      authorRole: 'vendor',
      authorSkill: 'Contractor',
      description:
      'Vaishali Nagar project work has started! All workers must report by 8 AM. Safety equipment is mandatory.',
      imageUrl: 'https://picsum.photos/seed/site1/600/400',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      likesCount: 14,
    ),
    PostModel(
      id: 'post_002',
      authorId: 'worker_002',
      authorName: 'Suresh Meena',
      authorInitials: 'SM',
      authorRole: 'worker',
      authorSkill: 'Tile Worker',
      description:
      'Completed tile work at Mansarovar project today. 5 years experience in tile fitting — bathroom, kitchen, hall.',
      imageUrl: 'https://picsum.photos/seed/tile1/600/400',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      likesCount: 27,
      isLikedByMe: true,
    ),
    PostModel(
      id: 'post_003',
      authorId: 'vendor_002',
      authorName: 'Sharma Builders',
      authorInitials: 'SB',
      authorRole: 'vendor',
      authorSkill: 'Builder',
      description:
      'Urgently needed — 3 experienced Mason workers for Malviya Nagar project. Rate: ₹650/day. Contact SiteLink admin.',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      likesCount: 9,
    ),
    PostModel(
      id: 'post_004',
      authorId: 'worker_003',
      authorName: 'Mohan Lal',
      authorInitials: 'ML',
      authorRole: 'worker',
      authorSkill: 'Helper',
      description:
      '2 years of construction helper experience. Ready to work on any site. Available in Jaipur.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      likesCount: 5,
    ),
    PostModel(
      id: 'post_005',
      authorId: 'vendor_003',
      authorName: 'Metro Infra Pvt Ltd',
      authorInitials: 'MI',
      authorRole: 'vendor',
      authorSkill: 'Contractor',
      description:
      'New project at Sitapura industrial area — skilled workers needed for electrical work. Duration: 20 days.',
      imageUrl: 'https://picsum.photos/seed/metro1/600/400',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      likesCount: 18,
    ),
  ];
}