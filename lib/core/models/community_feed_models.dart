import 'dart:convert';

// ═══════════════════════════════════════════════════════════════════
//  COMMUNITY FEED MODELS  —  exact as provided
//  Path: lib/features/worker/models/community_feed_model.dart
// ═══════════════════════════════════════════════════════════════════

CommunityFeedData communityFeedDataFromJson(String str) =>
    CommunityFeedData.fromJson(json.decode(str));

String communityFeedDataToJson(CommunityFeedData data) =>
    json.encode(data.toJson());

class CommunityFeedData {
  bool? success;
  List<CommunityFeedModel>? data;
  Pagination? pagination;

  CommunityFeedData({
    this.success,
    this.data,
    this.pagination,
  });

  factory CommunityFeedData.fromJson(Map<String, dynamic> json) =>
      CommunityFeedData(
        success: json["success"],
        data: json["data"] == null
            ? []
            : List<CommunityFeedModel>.from(
            json["data"]!.map((x) => CommunityFeedModel.fromJson(x))),
        pagination: json["pagination"] == null
            ? null
            : Pagination.fromJson(json["pagination"]),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data == null
        ? []
        : List<dynamic>.from(data!.map((x) => x.toJson())),
    "pagination": pagination?.toJson(),
  };
}

class CommunityFeedModel {
  String? id;
  String? content;
  List<String>? images;
  String? video;
  String? feeling;
  String? posterName;
  String? posterImage;
  String? posterType;   // 'vendor' | 'worker' | 'admin'
  /// Vendor ka designation / worker ka primary skill — feed me name ke
  /// neeche role ki jagah yahi dikhta hai.
  String? posterDesignation;
  String? companyName;

  /// Worker ki automatic performance rating — feed me naam ke baad
  /// dikhti hai (jaise vendor ke naam ke baad verified badge). Backend
  /// ise live bhejta hai, snapshot nahi. Vendor/admin par null.
  num? posterRating;

  /// Kitni jobs par rating bani hai. 0 → UI "New" dikhata hai, 0 stars nahi.
  int? posterRatedJobsCount;

  String? verification;   // 'verified' | 'pending'
  String? approvalStatus; // 'approved' | 'pending' | 'rejected'
  int? likesCount;
  int? commentsCount;
  DateTime? createdAt;
  List<Like>? likes;

  CommunityFeedModel({
    this.id,
    this.content,
    this.images,
    this.video,
    this.feeling,
    this.posterName,
    this.posterImage,
    this.posterType,
    this.posterDesignation,
    this.companyName,
    this.posterRating,
    this.posterRatedJobsCount,
    this.verification,
    this.approvalStatus,
    this.likesCount,
    this.commentsCount,
    this.createdAt,
    this.likes,
  });

  factory CommunityFeedModel.fromJson(Map<String, dynamic> json) =>
      CommunityFeedModel(
        id:            json["_id"],
        content:       json["content"],
        images:        json["images"] == null
            ? []
            : List<String>.from(json["images"]!.map((x) => x)),
        video:         json["video"],
        feeling:       json["feeling"],
        posterName:    json["posterName"],
        posterImage:   json["posterImage"],
        posterType:    json["posterType"],
        posterDesignation: json["posterDesignation"]?.toString(),
        companyName:   json["companyName"],
        posterRating: json["posterRating"] is num
            ? json["posterRating"] as num
            : num.tryParse(json["posterRating"]?.toString() ?? ""),
        posterRatedJobsCount:
            int.tryParse(json["posterRatedJobsCount"]?.toString() ?? ""),
        verification:  json["verification"],
        approvalStatus:json["approvalStatus"],
        likesCount:    json["likesCount"],
        commentsCount: json["commentsCount"],
        createdAt:     json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
        likes: json["likes"] == null
            ? []
            : List<Like>.from(json["likes"]!.map((x) => Like.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
    "_id":          id,
    "content":      content,
    "images":       images == null ? [] : List<dynamic>.from(images!.map((x) => x)),
    "video":        video,
    "feeling":      feeling,
    "posterName":   posterName,
    "posterImage":  posterImage,
    "posterType":   posterType,
    "posterDesignation": posterDesignation,
    "companyName":  companyName,
    "posterRating": posterRating,
    "posterRatedJobsCount": posterRatedJobsCount,
    "verification": verification,
    "approvalStatus": approvalStatus,
    "likesCount":   likesCount,
    "commentsCount":commentsCount,
    "createdAt":    createdAt?.toIso8601String(),
    "likes":        likes == null
        ? []
        : List<dynamic>.from(likes!.map((x) => x.toJson())),
  };
}

class Like {
  String? userId;
  String? userName;

  Like({this.userId, this.userName});

  factory Like.fromJson(Map<String, dynamic> json) => Like(
    userId:   json["userId"],
    userName: json["userName"],
  );

  Map<String, dynamic> toJson() => {
    "userId":   userId,
    "userName": userName,
  };
}

// ═══════════════════════════════════════════════════════════════════
//  COMMENT MODELS — /api/community/posts/:postId/comments
// ═══════════════════════════════════════════════════════════════════
class CommentModel {
  String? id;
  String? comment;
  String? userId;
  String? userName;
  String? userImage;
  DateTime? createdAt;

  CommentModel({
    this.id,
    this.comment,
    this.userId,
    this.userName,
    this.userImage,
    this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // author kabhi nested object (user/author/postedBy) me, kabhi flat fields me
    final user = json['user'] ?? json['author'] ?? json['postedBy'];
    String? fromUser(String k) =>
        (user is Map && user[k] != null) ? user[k].toString() : null;
    return CommentModel(
      id: (json['_id'] ?? json['id'])?.toString(),
      comment:
          (json['comment'] ?? json['text'] ?? json['content'])?.toString(),
      userId: (fromUser('_id') ??
              fromUser('id') ??
              json['userId'] ??
              json['user'])
          ?.toString(),
      userName: (fromUser('name') ?? json['userName'] ?? json['name'])
          ?.toString(),
      userImage:
          (fromUser('profileImage') ?? json['userImage'])?.toString(),
      createdAt: DateTime.tryParse(
          (json['createdAt'] ?? json['updatedAt'] ?? '').toString()),
    );
  }
}

// ── List response: { success, data: [...] } (ya data.comments) ──────
class CommentsResponse {
  final bool success;
  final String? message;
  final List<CommentModel> data;

  const CommentsResponse(
      {required this.success, this.message, this.data = const []});

  factory CommentsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final list = raw is List
        ? raw
        : (raw is Map ? (raw['comments'] as List?) : null);
    return CommentsResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: list
              ?.whereType<Map>()
              .map((e) => CommentModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }
}

// ── Add/update/delete response ──────────────────────────────────────
class CommentActionResponse {
  final bool success;
  final String? message;
  final CommentModel? data;

  const CommentActionResponse(
      {required this.success, this.message, this.data});

  factory CommentActionResponse.fromJson(Map<String, dynamic> json) {
    final d = json['data'];
    return CommentActionResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: d is Map
          ? CommentModel.fromJson(Map<String, dynamic>.from(d))
          : null,
    );
  }
}

class Pagination {
  int? current;
  int? limit;
  int? total;
  int? pages;

  Pagination({this.current, this.limit, this.total, this.pages});

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    current: json["current"],
    limit:   json["limit"],
    total:   json["total"],
    pages:   json["pages"],
  );

  Map<String, dynamic> toJson() => {
    "current": current,
    "limit":   limit,
    "total":   total,
    "pages":   pages,
  };
}