// ═══════════════════════════════════════════════════════════════════
//  PROFILE MODELS — /api/profile/me
// ═══════════════════════════════════════════════════════════════════
class MyProfile {
  final String? id;
  final String? name;
  final String? email;
  final String? role;
  final String? profileImage;
  final String? primarySkill;
  final num? totalExperience; // worker ka overall experience (years)
  final String? experienceDescription;
  /// Worker ka nominee (Family Protection). Purane workers ke liye null.
  final String? nomineeName;
  final String? gender;          // 'Male' | 'Female' | 'Other'
  final bool? willingtoRelocate;
  final String? salaryType;      // 'daily' | 'monthly' | 'hourly' | 'project-based'
  final num? salary;
  /// Admin ki di hui rating (1–5). null = admin ne abhi rating nahi di.
  /// Automatic rating (job outcomes se) ka system hata diya gaya hai.
  final num? rating;
  /// Admin ka comment, rating ke saath.
  final String? ratingComment;

  /// Abhi koi plan chal raha hai? Backend live compute karke bhejta hai.
  /// Paid features (Contact Support waghairah) ka lock isi se decide hota
  /// hai — purana `subscription` boolean expiry par false nahi hota tha.
  final bool hasActivePlan;

  /// Rating mili hai? null/0 par UI kuch nahi dikhata.
  bool get hasRating => (rating ?? 0) > 0;

  final List<String> skills;
  // "My Posts" — ab dedicated endpoint se aata hai (GET /community/posts/mine,
  // CommunityApiService.getMyPosts()), yahan embed nahi hota.
  final String? workCity;
  final String? workState;
  final String? userType;
  final String? verification; // account verification key ('verified' | 'pending' | null)
  /// Documents ka admin review: 'pending' | 'verified' | 'rejected'.
  final String? verificationStatus;
  /// Admin ne reject kiya to uski wajah (warna null).
  final String? rejectionReason;
  /// Har document ka admin review, file path se. Jis path ka review nahi
  /// wo "under review" hai (naya upload).
  final Map<String, DocumentReview> documentReviews;
  final String? language;     // 'hindi' | 'english' — app language preference
  final DateTime? createdAt;
  final DateTime? dateOfBirth;
  final String? phone;
  // ── Worker documents (relative server paths) ──
  final String? governmentID;
  /// Ek se zyada ho sakte hain (alag company/skill ke). Purane users ke
  /// paas ek hi hota tha — backend usse bhi array hi bhejta hai.
  final List<String> experienceCertificate;
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
    this.experienceDescription,
    this.nomineeName,
    this.gender,
    this.willingtoRelocate,
    this.salaryType,
    this.salary,
    this.rating,
    this.ratingComment,
    this.hasActivePlan = false,
    this.skills = const [],
    this.workCity,
    this.workState,
    this.userType,
    this.verification,
    this.verificationStatus,
    this.rejectionReason,
    this.documentReviews = const {},
    this.language,
    this.createdAt,
    this.dateOfBirth,
    this.phone,
    this.governmentID,
    this.experienceCertificate = const [],
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

  /// Account verified? Sirf jab backend 'verified' bheje. Warna false.
  bool get isVerified => (verification ?? '').toLowerCase() == 'verified';

  /// Admin ne documents reject kiye — worker naye upload kar sakta hai.
  bool get isRejected => (verificationStatus ?? '').toLowerCase() == 'rejected';

  DocumentReview? reviewFor(String? path) =>
      path == null ? null : documentReviews[path];

  /// Admin ne document-wise reject kiya hai? (purane reject me ye info nahi
  /// hoti — tab saare documents dobara upload ho sakte hain.)
  bool get hasDocumentRejections =>
      documentReviews.values.any((r) => r.isRejected);

  /// Ye document worker badal sakta hai? Sirf reject hone par — aur agar
  /// admin ne specific documents chune the to sirf wahi.
  bool canReplaceDocument(String? path) {
    if (!isRejected) return false;
    if (!hasDocumentRejections) return true;
    return reviewFor(path)?.isRejected ?? false;
  }

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
      experienceDescription: json['experienceDescription']?.toString(),
      nomineeName: json['nomineeName']?.toString(),
      gender: json['gender']?.toString(),
      willingtoRelocate: json['willingtoRelocate'] is bool
          ? json['willingtoRelocate'] as bool
          : (json['willingtoRelocate']?.toString() == 'true' ? true : null),
      salaryType: json['salaryType']?.toString(),
      salary: json['salary'] is num
          ? json['salary'] as num
          : num.tryParse(json['salary']?.toString() ?? ''),
      rating: json['rating'] is num
          ? json['rating'] as num
          : num.tryParse(json['rating']?.toString() ?? ''),
      ratingComment: json['ratingComment']?.toString(),
      hasActivePlan: json['hasActivePlan'] == true,
      skills: skillsRaw
              ?.map((e) =>
                  (e is Map ? e['skillName'] : e)?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      workCity: json['workCity']?.toString(),
      workState: json['workState']?.toString(),
      userType: json['userType']?.toString(),
      verification: json['verification']?.toString() ??
          (json['isVerified'] == true ? 'verified' : null),
      verificationStatus: json['verificationStatus']?.toString(),
      rejectionReason: json['verificationRejectedReason']?.toString(),
      documentReviews: {
        for (final r in (json['documentReviews'] as List? ?? const []).whereType<Map>())
          if ((r['path'] ?? '').toString().isNotEmpty)
            r['path'].toString():
                DocumentReview.fromJson(Map<String, dynamic>.from(r)),
      },
      language: json['language']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? ''),
      phone: json['phone']?.toString(),
      governmentID: json['governmentID']?.toString(),
      // Purane records me ye single string ho sakti hai — dono handle karo.
      experienceCertificate: switch (json['experienceCertificate']) {
        final List l => l.map((e) => e.toString()).where((s) => s.isNotEmpty).toList(),
        final String s when s.isNotEmpty => [s],
        _ => const <String>[],
      },
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

// ── Ek document ka admin review ──────────────────────────────────────
class DocumentReview {
  final String status; // 'approved' | 'rejected'
  final String? reason;

  const DocumentReview({required this.status, this.reason});

  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory DocumentReview.fromJson(Map<String, dynamic> json) => DocumentReview(
        status: json['status']?.toString() ?? '',
        reason: json['reason']?.toString(),
      );
}
