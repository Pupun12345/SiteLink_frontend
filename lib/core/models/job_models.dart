// ═══════════════════════════════════════════════════════════════════
//  JOB MODELS — /api/jobs (list + detail)
// ═══════════════════════════════════════════════════════════════════
// Ek hi JobModel list aur detail dono responses handle karta hai
// (list me `company`/`workersNeeded`/`postedAt`, detail me
//  `quantity`/`description`/`experience` aata hai).

class JobPostedBy {
  final String? id;
  final String? name;
  final String? companyName;
  final String? designation;
  // Backend sirf tabhi bhejta hai jab worker ki application confirm/hire ho
  // chuki ho — warna dono null aate hai (contact abhi unlock nahi hua).
  final String? phone;
  final String? whatsappNumber;

  const JobPostedBy({
    this.id,
    this.name,
    this.companyName,
    this.designation,
    this.phone,
    this.whatsappNumber,
  });

  factory JobPostedBy.fromJson(Map<String, dynamic> json) => JobPostedBy(
        id: (json['_id'] ?? json['id'])?.toString(),
        name: json['name']?.toString(),
        companyName: json['companyName']?.toString(),
        designation: json['designation']?.toString(),
        phone: json['phone']?.toString(),
        whatsappNumber: json['whatsappNumber']?.toString(),
      );
}

/// Job amenity / benefit — { _id, id, name, category, icon }
class JobAmenity {
  final String? id;      // mongo _id
  final int? numericId;  // backend ka numeric id (job create isi se hota hai)
  final String? name;
  final String? category;
  final String? icon;

  const JobAmenity(
      {this.id, this.numericId, this.name, this.category, this.icon});

  factory JobAmenity.fromJson(Map<String, dynamic> json) => JobAmenity(
        id: (json['_id'] ?? json['id'])?.toString(),
        numericId: json['id'] is int
            ? json['id'] as int
            : int.tryParse(json['id']?.toString() ?? ''),
        name: json['name']?.toString(),
        category: json['category']?.toString(),
        icon: json['icon']?.toString(),
      );
}

class JobModel {
  final String? id;
  final String? title;
  final String? company;
  final String? location;
  final String? latitude;
  final String? longitude;
  final String? workersNeeded; // list response
  final String? quantity;      // detail response
  final num? salary;
  final String? salaryType;
  final bool isUrgent;
  final String? duration;
  final String? description;   // detail response
  final String? experience;    // detail response
  final DateTime? postedAt;
  final JobPostedBy? postedBy;
  final List<JobAmenity> amenities; // detail response
  final int applicationsCount;
  final String? status;         // 'Open' | 'Closed' etc.
  final String? approvalStatus; // 'approved' | 'pending' | 'rejected'
  final bool isActive;          // false = vendor ne deactivate (delete) kiya
  final String? rejectionReason; // admin ne reject karte waqt diya reason
  final String? jobId;          // human-readable e.g. "REQ-20E7"

  const JobModel({
    this.id,
    this.title,
    this.company,
    this.location,
    this.latitude,
    this.longitude,
    this.workersNeeded,
    this.quantity,
    this.salary,
    this.salaryType,
    this.isUrgent = false,
    this.duration,
    this.description,
    this.experience,
    this.postedAt,
    this.postedBy,
    this.amenities = const [],
    this.applicationsCount = 0,
    this.status,
    this.approvalStatus,
    this.isActive = true,
    this.rejectionReason,
    this.jobId,
  });

  /// Map/directions ke liye coords available hain?
  bool get hasLocation =>
      (latitude ?? '').isNotEmpty && (longitude ?? '').isNotEmpty;

  /// list `workersNeeded` ya detail `quantity` — jo bhi mile.
  int get workersCount =>
      int.tryParse((workersNeeded ?? quantity ?? '').trim()) ?? 0;

  /// Display company name — top-level `company` ya postedBy.companyName.
  String get companyName =>
      company ?? postedBy?.companyName ?? '';

  factory JobModel.fromJson(Map<String, dynamic> json) {
    final postedByRaw = json['postedBy'];
    return JobModel(
      id: (json['_id'] ?? json['id'])?.toString(),
      title: json['title']?.toString(),
      company: json['company']?.toString(),
      location: json['location']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      workersNeeded: json['workersNeeded']?.toString(),
      quantity: json['quantity']?.toString(),
      salary: json['salary'] is num
          ? json['salary'] as num
          : num.tryParse(json['salary']?.toString() ?? ''),
      salaryType: json['salaryType']?.toString(),
      isUrgent: json['isUrgent'] == true || json['isUrgent']?.toString() == 'true',
      duration: json['duration']?.toString(),
      description: json['description']?.toString(),
      experience: json['experience']?.toString(),
      postedAt: DateTime.tryParse(json['postedAt']?.toString() ?? ''),
      postedBy: (postedByRaw is Map && postedByRaw.isNotEmpty)
          ? JobPostedBy.fromJson(Map<String, dynamic>.from(postedByRaw))
          : null,
      amenities: (json['amenities'] as List?)
              ?.whereType<Map>()
              .map((e) => JobAmenity.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      applicationsCount: json['applicationsCount'] is int
          ? json['applicationsCount'] as int
          : int.tryParse(json['applicationsCount']?.toString() ?? '') ?? 0,
      status: json['status']?.toString(),
      approvalStatus: json['approvalStatus']?.toString(),
      isActive: json['isActive'] != false,
      rejectionReason: json['rejectionReason']?.toString(),
      jobId: json['jobId']?.toString(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  JOB APPLICANT — vendor ke liye, GET /api/jobs/:id/applicants
// ═══════════════════════════════════════════════════════════════════
// Ek job pe apply kiye hue worker ki application + uski profile details.
// Parsing flexible hai — backend jo bhi shape de (nested `worker` object
// ya flat fields), dono handle karta hai.
class JobApplicant {
  final String? applicationId; // application/doc id (confirm/reject isi se)
  final String? workerId;
  final String? name;
  final String? profileImage;
  final String? primarySkill;
  final List<String> skills;
  final num? totalExperience;  // worker profile ka overall experience
  final String? phone;
  final String? workCity;
  final String? workState;
  final bool isVerified;
  final num? rating;
  final String? coverLetter;   // application ke waqt likha
  final String? experienceNote; // application-specific experience text
  final String status;         // pending | shortlisted | confirmed | rejected
  final DateTime? appliedAt;

  const JobApplicant({
    this.applicationId,
    this.workerId,
    this.name,
    this.profileImage,
    this.primarySkill,
    this.skills = const [],
    this.totalExperience,
    this.phone,
    this.workCity,
    this.workState,
    this.isVerified = false,
    this.rating,
    this.coverLetter,
    this.experienceNote,
    this.status = 'pending',
    this.appliedAt,
  });

  String get locationLabel =>
      [workCity, workState].where((e) => (e ?? '').isNotEmpty).join(', ');

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isShortlisted => status.toLowerCase() == 'shortlisted';

  factory JobApplicant.fromJson(Map<String, dynamic> json) {
    // worker details kabhi nested `worker`/`user` object me, kabhi flat
    final workerRaw = json['worker'] ?? json['user'] ?? json['applicant'];
    final Map worker = workerRaw is Map ? workerRaw : json;

    String? pick(String key) => (worker[key] ?? json[key])?.toString();
    num? pickNum(String key) {
      final v = worker[key] ?? json[key];
      if (v is num) return v;
      return num.tryParse(v?.toString() ?? '');
    }

    final skillsRaw = worker['skills'] ?? json['skills'];
    final skills = (skillsRaw as List?)
            ?.map((e) => (e is Map ? e['skillName'] : e)?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];

    return JobApplicant(
      applicationId: (json['_id'] ?? json['id'])?.toString(),
      workerId: (worker['_id'] ?? worker['id'])?.toString(),
      name: pick('name'),
      profileImage: pick('profileImage'),
      primarySkill: pick('primarySkill') ?? pick('role'),
      skills: skills,
      totalExperience: pickNum('totalExperience') ?? pickNum('experience'),
      phone: pick('phone'),
      workCity: pick('workCity'),
      workState: pick('workState'),
      isVerified: worker['isVerified'] == true || json['isVerified'] == true,
      rating: pickNum('rating'),
      coverLetter: json['coverLetter']?.toString(),
      experienceNote: json['experience']?.toString(),
      status: (json['status']?.toString() ?? 'pending').toLowerCase(),
      appliedAt: DateTime.tryParse(
          (json['createdAt'] ?? json['appliedAt'] ?? '').toString()),
    );
  }
}

class JobApplicantsResponse {
  final bool success;
  final String? message;
  final int count;
  final List<JobApplicant> data;

  const JobApplicantsResponse({
    required this.success,
    this.message,
    this.count = 0,
    this.data = const [],
  });

  factory JobApplicantsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List?;
    return JobApplicantsResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      count: json['count'] as int? ?? (list?.length ?? 0),
      data: list
              ?.whereType<Map>()
              .map((e) => JobApplicant.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  APPLIED JOB — /api/jobs/getAppliedJobs ka item (nested job + status)
// ═══════════════════════════════════════════════════════════════════
class AppliedJobModel {
  final String? id;        // application id
  final JobModel? job;     // nested job
  final String? status;    // 'pending' | 'accepted' | 'completed' | ...
  final String? coverLetter;
  final String? experience;
  final DateTime? createdAt;

  const AppliedJobModel({
    this.id,
    this.job,
    this.status,
    this.coverLetter,
    this.experience,
    this.createdAt,
  });

  factory AppliedJobModel.fromJson(Map<String, dynamic> json) {
    final jobRaw = json['job'];
    return AppliedJobModel(
      id: (json['_id'] ?? json['id'])?.toString(),
      job: jobRaw is Map
          ? JobModel.fromJson(Map<String, dynamic>.from(jobRaw))
          : null,
      status: json['status']?.toString(),
      coverLetter: json['coverLetter']?.toString(),
      experience: json['experience']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

// ── Applied jobs response: { success, data: [...] } ─────────────────
class AppliedJobsResponse {
  final bool success;
  final String? message;
  final List<AppliedJobModel> data;

  const AppliedJobsResponse({
    required this.success,
    this.message,
    this.data = const [],
  });

  factory AppliedJobsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List?;
    return AppliedJobsResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      data: list
              ?.whereType<Map>()
              .map((e) => AppliedJobModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }
}

// ── Generic job action response (apply etc.) ────────────────────────
class JobActionResponse {
  final bool success;
  final String? message;
  final String? approvalStatus; // create-job: 'pending' | 'approved'

  const JobActionResponse({
    required this.success,
    this.message,
    this.approvalStatus,
  });

  factory JobActionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return JobActionResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      approvalStatus: data is Map ? data['approvalStatus']?.toString() : null,
    );
  }
}

// ── Worker quota summary (getMyJobs ke response me) ─────────────────
class WorkerQuota {
  final bool hasActiveSubscription;
  final int maxWorkers;   // 0 = admin ne limit configure nahi ki
  final int used;
  final int? remaining;   // null = no limit configured

  const WorkerQuota({
    this.hasActiveSubscription = false,
    this.maxWorkers = 0,
    this.used = 0,
    this.remaining,
  });

  bool get hasLimit => maxWorkers > 0;

  factory WorkerQuota.fromJson(Map<String, dynamic> json) => WorkerQuota(
        hasActiveSubscription: json['hasActiveSubscription'] as bool? ?? false,
        maxWorkers: (json['maxWorkers'] as num?)?.toInt() ?? 0,
        used: (json['used'] as num?)?.toInt() ?? 0,
        remaining: (json['remaining'] as num?)?.toInt(),
      );
}

// ── List response: { success, count, data: [...], quota } ───────────
class JobListResponse {
  final bool success;
  final String? message;
  final int count;
  final List<JobModel> data;
  final WorkerQuota? quota;

  const JobListResponse({
    required this.success,
    this.message,
    this.count = 0,
    this.data = const [],
    this.quota,
  });

  factory JobListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List?;
    final q = json['quota'];
    return JobListResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString(),
      count: json['count'] as int? ?? (list?.length ?? 0),
      data: list
              ?.whereType<Map>()
              .map((e) => JobModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      quota: q is Map ? WorkerQuota.fromJson(Map<String, dynamic>.from(q)) : null,
    );
  }
}
