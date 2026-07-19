// ═══════════════════════════════════════════════════════════════════
//  PROFILE MODELS — /api/profile/me
// ═══════════════════════════════════════════════════════════════════
import 'community_feed_models.dart';

class MyProfile {
  final String? id;
  final String? name;
  final String? email;
  final String? role;
  final String? profileImage;
  final String? primarySkill;
  final num? totalExperience; // worker ka overall experience (years)
  final List<String> skills;
  final List<CommunityFeedModel> posts; // user ke apne posts
  final String? workCity;
  final String? workState;
  final String? userType;
  final String? verification; // account verification key ('verified' | 'pending' | null)
  final String? language;     // 'hindi' | 'english' — app language preference
  final DateTime? createdAt;
  final DateTime? dateOfBirth;
  final String? phone;
  // ── Worker documents (relative server paths) ──
  final String? governmentID;
  final String? experienceCertificate;
  final List<String> workSamplesPhoto;
  // ── Vendor fields ──
  final String? companyName;
  final String? designation;
  final String? panNumber;
  final String? gstNumber;
  final String? whatsappNumber;
  final String? website;
  final String? workArea;
  final String? companyLogo;
  final String? panCardImage;
  final String? gstCertificate;

  const MyProfile({
    this.id,
    this.name,
    this.email,
    this.role,
    this.profileImage,
    this.primarySkill,
    this.totalExperience,
    this.skills = const [],
    this.posts = const [],
    this.workCity,
    this.workState,
    this.userType,
    this.verification,
    this.language,
    this.createdAt,
    this.dateOfBirth,
    this.phone,
    this.governmentID,
    this.experienceCertificate,
    this.workSamplesPhoto = const [],
    this.companyName,
    this.designation,
    this.panNumber,
    this.gstNumber,
    this.whatsappNumber,
    this.website,
    this.workArea,
    this.companyLogo,
    this.panCardImage,
    this.gstCertificate,
  });

  bool get isVendor => (userType ?? '').toLowerCase() == 'vendor';

  /// "workCity, workState" (jo bhi available ho).
  String get locationLabel =>
      [workCity, workState].where((e) => (e ?? '').isNotEmpty).join(', ');

  int get postsCount => posts.length;

  /// Account verified? Sirf jab backend 'verified' bheje. Warna false.
  bool get isVerified => (verification ?? '').toLowerCase() == 'verified';

  factory MyProfile.fromJson(Map<String, dynamic> json) {
    final skillsRaw = json['skills'] as List?;
    return MyProfile(
      id: (json['id'] ?? json['_id'])?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
      profileImage: json['profileImage']?.toString(),
      primarySkill: json['primarySkill']?.toString(),
      totalExperience: json['totalExperience'] is num
          ? json['totalExperience'] as num
          : num.tryParse(
              (json['totalExperience'] ?? json['experience'])?.toString() ??
                  ''),
      skills: skillsRaw
              ?.map((e) =>
                  (e is Map ? e['skillName'] : e)?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      posts: (json['posts'] as List?)
              ?.whereType<Map>()
              .map((e) =>
                  CommunityFeedModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      workCity: json['workCity']?.toString(),
      workState: json['workState']?.toString(),
      userType: json['userType']?.toString(),
      verification: json['verification']?.toString() ??
          (json['isVerified'] == true ? 'verified' : null),
      language: json['language']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? ''),
      phone: json['phone']?.toString(),
      governmentID: json['governmentID']?.toString(),
      experienceCertificate: json['experienceCertificate']?.toString(),
      workSamplesPhoto: (json['workSamplesPhoto'] as List?)
              ?.map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      companyName: json['companyName']?.toString(),
      designation: json['designation']?.toString(),
      panNumber: json['panNumber']?.toString(),
      gstNumber: json['gstNumber']?.toString(),
      whatsappNumber: json['whatsappNumber']?.toString(),
      website: json['website']?.toString(),
      workArea: json['workArea']?.toString(),
      companyLogo: json['companyLogo']?.toString(),
      panCardImage: json['panCardImage']?.toString(),
      gstCertificate: json['gstCertificate']?.toString(),
    );
  }
}

// ── Response: { success, data: { user: {...} } } ────────────────────
class MyProfileResponse {
  final bool success;
  final String? message;
  final MyProfile? user;

  const MyProfileResponse({required this.success, this.message, this.user});

  factory MyProfileResponse.fromJson(Map<String, dynamic> json) {
    final userRaw = json['data']?['user'] ?? json['user'];
    return MyProfileResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      user: userRaw is Map
          ? MyProfile.fromJson(Map<String, dynamic>.from(userRaw))
          : null,
    );
  }
}

// ── Response: phone-change send-otp / verify-otp ─────────────────────
class PhoneChangeOtpResponse {
  final bool success;
  final String? message;
  // Dev-only: backend echoes the OTP when NODE_ENV != production.
  final String? devOtp;

  const PhoneChangeOtpResponse({required this.success, this.message, this.devOtp});

  factory PhoneChangeOtpResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return PhoneChangeOtpResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      devOtp: data is Map ? data['otp']?.toString() : null,
    );
  }
}
