import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import '../../app/config/app_config.dart';
import '../utils/mask_secret.dart';
import '../models/auth_models.dart';
import '../models/worker_models.dart';
import '../models/skill_models.dart';
import '../models/location_models.dart';
import '../models/job_models.dart';
import '../models/profile_models.dart';
import '../models/community_feed_models.dart';
import '../models/plan_models.dart';
import '../models/payment_models.dart';
import '../models/notification_models.dart';
import '../models/app_config_models.dart';
import 'api_services.dart';

// ═══════════════════════════════════════════════════════════════════
//  API ENDPOINTS
// ═══════════════════════════════════════════════════════════════════
// Base URL AppConfig se aata hai — yahan local alias taaki neeche ke
// const interpolations clean rahein.
const String baseUrl = AppConfig.baseUrl;

class ApiEndpoints {
  // Auth endpoints
  static const String register    = "$baseUrl/auth/register";
  static const String verifyOtp   = "$baseUrl/auth/verify-otp";
  static const String resendOtp   = "$baseUrl/auth/resend-otp";
  static const String googleLogin = "$baseUrl/auth/google-login";
  static const String logout      = "$baseUrl/auth/logout";

  // Profile endpoints
  static const String myProfile   = "$baseUrl/profile/me";
  static const String setLanguage = "$baseUrl/profile/language";
  static const String phoneSendOtp   = "$baseUrl/profile/phone/send-otp";
  static const String phoneVerifyOtp = "$baseUrl/profile/phone/verify-otp";

  // Vendor endpoints
  static const String createVendor = "$baseUrl/profile/create/vendor";
  static const String editVendor   = "$baseUrl/profile/edit/vendor";

  // Misc endpoints
  static const String saveFcmToken  = "$baseUrl/notifications/save-token";

  // Notification history
  static const String notifications = "$baseUrl/notifications";
  static const String notificationsReadAll = "$baseUrl/notifications/read-all";
  static String notificationRead(String id) => "$baseUrl/notifications/$id/read";
  static String notificationById(String id) => "$baseUrl/notifications/$id";
  static const String plans         = "$baseUrl/plans/plans";
  static const String legalPolicies = "$baseUrl/legal/policies";

  /// Public app-level config (maintenance notice). Token nahi lagta —
  /// login se pehle bhi padha ja sakta hai.
  static const String appConfig = "$baseUrl/app-config";
  static const String supportContact = "$baseUrl/legal/support-contact";

  // Payment endpoints (Razorpay — order create + signature verify)
  static const String createOrder   = "$baseUrl/payments/create-order";
  static const String verifyPayment = "$baseUrl/payments/verify-payment";

  // Auto-payment (Razorpay Subscriptions) — one-time payment se ALAG
  // flow hai. Yahan mandate banta hai aur Razorpay har cycle par khud
  // paise kaat leta hai, jab tak user cancel na kare.
  static const String createSubscription = "$baseUrl/payments/create-subscription";
  static const String verifySubscription = "$baseUrl/payments/verify-subscription";
  static const String cancelSubscription = "$baseUrl/payments/cancel-subscription";

  // Amenities endpoints
  static const String amenities        = "$baseUrl/amenities";
  static const String amenitiesGrouped = "$baseUrl/amenities/grouped";

  // Worker endpoints
  static const String createWorker        = "$baseUrl/profile/create/worker";
  static const String updateWorkerProfile = "$baseUrl/profile/update/worker";
  static const String editWorker          = "$baseUrl/profile/edit/worker";
  static const String getWorkerProfile    = "$baseUrl/profile/worker";

  // Skills endpoints
  static const String getAllSkills = "$baseUrl/profile/skills";

  // Location endpoints
  static const String getStates = "$baseUrl/profile/states";
  static const String getCities = "$baseUrl/profile/cities";

  // Document upload endpoints
  static const String uploadIdProof        = "$baseUrl/upload/id-proof";
  static const String uploadWorkPhoto      = "$baseUrl/upload/work-photo";
  static const String uploadExperienceCert = "$baseUrl/upload/experience-cert";

  // Job endpoints
  static const String jobs = "$baseUrl/jobs";
  static const String myJobs = "$baseUrl/jobs/my";
  static const String appliedJobs = "$baseUrl/jobs/getAppliedJobs";
  static String jobById(String id) => "$baseUrl/jobs/$id";
  static String applyJob(String id) => "$baseUrl/jobs/$id/apply";
  static String likeJob(String id) => "$baseUrl/jobs/$id/like";
  static String jobComments(String id) => "$baseUrl/jobs/$id/comments";
  static String jobApplicants(String jobId) => "$baseUrl/jobs/$jobId/applicants";
  static String jobApplicantStatus(String jobId, String applicationId) =>
      "$baseUrl/jobs/$jobId/applicants/$applicationId/status";

  // Community — own posts ("My Posts" on profile screens)
  static const String myPosts = "$baseUrl/community/posts/mine";

  // Community feed endpoints
  static const String communityFeed = "$baseUrl/community/feed";
  static const String communityPosts = "$baseUrl/community/posts";
  static String communityPostLike(String postId) =>
      "$baseUrl/community/posts/$postId/like";
  static String communityPostDelete(String postId) =>
      "$baseUrl/community/posts/$postId";

  /// Kisi ek user ke public posts. Backend access check karta hai — vendor
  /// sirf un workers ke posts dekh sakta hai jinhone uski job par apply
  /// kiya ho.
  static String communityPostsByUser(String userId) =>
      "$baseUrl/community/posts/user/$userId";

  // Community comment endpoints
  static String postComments(String postId) =>
      "$baseUrl/community/posts/$postId/comments";
  static String postComment(String postId, String commentId) =>
      "$baseUrl/community/posts/$postId/comments/$commentId";
}

// ═══════════════════════════════════════════════════════════════════
//  AUTH API SERVICE
// ═══════════════════════════════════════════════════════════════════
class AuthApiService {
  final RestApi _api = Get.find<RestApi>();

  // ── Send OTP ──────────────────────────────────────────────────────
  Future<RegisterResponse> sendRegisterOtp(String phone) async {
    try {
      final request  = RegisterRequest(phone: phone);
      final response = await _api.postApi(
        ApiEndpoints.register,
        jsonEncode(request.toJson()),
      );
      debugPrint(response.body);

      if (response.statusCode == 200) {
        return RegisterResponse.fromJson(jsonDecode(response.body));
      }
      return RegisterResponse(
          success: false, message: "Failed to send OTP. Please try again.");
    } catch (e) {
      if (kDebugMode) print("[AuthAPI] sendOtp error: $e");
      return RegisterResponse(
          success: false, message: "Network error: Unable to send OTP");
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────
  Future<VerifyOtpResponse> verifyOtp(String phone, String otp) async {
    try {
      final request  = VerifyOtpRequest(phone: phone, otp: otp);
      final response = await _api.postApi(
        ApiEndpoints.verifyOtp,
        jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return VerifyOtpResponse.fromJson(jsonDecode(response.body));
      }
      return VerifyOtpResponse(
          success: false, message: "Invalid OTP. Please try again.");
    } catch (e) {
      if (kDebugMode) print("[AuthAPI] verifyOtp error: $e");
      return VerifyOtpResponse(
          success: false, message: "Network error: Unable to verify OTP");
    }
  }

  // ── Resend OTP ────────────────────────────────────────────────────
  Future<RegisterResponse> resendOtp(String phone) async {
    try {
      final request  = RegisterRequest(phone: phone);
      final response = await _api.postApi(
        ApiEndpoints.resendOtp,
        jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return RegisterResponse.fromJson(jsonDecode(response.body));
      }
      return RegisterResponse(
          success: false, message: "Failed to resend OTP. Please try again.");
    } catch (e) {
      if (kDebugMode) print("[AuthAPI] resendOtp error: $e");
      return RegisterResponse(
          success: false, message: "Network error: Unable to resend OTP");
    }
  }

  Future<GoogleLoginResponse> googleLogin(
      String firebaseIdToken, {
        String deviceToken = '',
        String deviceType  = 'android',
      }) async {

    try {

      final requestBody = {
        'firebaseIdToken': firebaseIdToken,
        'deviceToken': deviceToken,
        'deviceType': deviceType,
      };

      // ── CLEAN DEBUG PRINTS ─────────────────────
      if (kDebugMode) {
        print("====================================");
        print("[AuthAPI] GOOGLE LOGIN REQUEST");

        print("URL: ${ApiEndpoints.googleLogin}");

        // Token masked — ye bearer credential hai (~1 ghanta valid).
        // Debug logs regularly share/paste kiye jaate hain, to poora
        // token print karna account handover ke barabar hai. Prefix +
        // length se debug karne ke liye kaafi hai.
        print("firebaseIdToken: ${maskSecret(firebaseIdToken)}");
        print("deviceToken: ${maskSecret(deviceToken)}");
        print("deviceType: $deviceType");
        print("====================================");
      }

      final response = await _api.postApi(
        ApiEndpoints.googleLogin,
        jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print("====================================");
        print("[AuthAPI] GOOGLE LOGIN RESPONSE");
        print("STATUS CODE: ${response.statusCode}");
        print("BODY: ${response.body}");
        print("====================================");
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return GoogleLoginResponse.fromJson(jsonDecode(response.body));
      }

      final body = jsonDecode(response.body);

      return GoogleLoginResponse(
        success: false,
        message: body['message']?.toString() ?? 'Google login failed',
      );

    } catch (e) {

      if (kDebugMode) {
        print("[AuthAPI] GOOGLE LOGIN ERROR: $e");
      }

      return GoogleLoginResponse(
        success: false,
        message: "Network error: Unable to sign in with Google",
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PROXY / GATEWAY ERROR HELPER
// ═══════════════════════════════════════════════════════════════════
// nginx jaise reverse proxy apni errors HTML me bhejte hain, JSON me nahi
// (e.g. 413 "Request Entity Too Large" jab upload nginx ke
// client_max_body_size se bada ho). Aise body ko jsonDecode karne par
// FormatException aata tha aur user ko raw Dart exception dikh jaata tha.
// Yahan pehle hi pakad ke saaf, translated message de dete hain.
//
// null return = normal JSON response hai, aage jsonDecode safe hai.
String? proxyErrorMessage(int statusCode, String body) {
  if (statusCode == 413) return 'upload_too_large_error'.tr;

  // JSON hamesha { ya [ se shuru hota hai; < matlab HTML error page.
  final trimmed = body.trimLeft();
  if (trimmed.isEmpty) return 'server_error_generic'.tr;
  if (!trimmed.startsWith('<')) return null;

  if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
    return 'server_unavailable_error'.tr;
  }
  return 'server_error_generic'.tr;
}

// ═══════════════════════════════════════════════════════════════════
//  WORKER PROFILE API SERVICE  (unchanged)
// ═══════════════════════════════════════════════════════════════════
class WorkerApiService {
  final RestApi _api = Get.find<RestApi>();

  Future<CreateWorkerResponse> createWorkerProfile(
      WorkerProfileRequest request, {
        File?       profileImage,
        List<File>? experienceCertificates,
        File?       governmentID,
      }) async {
    try {
      if (kDebugMode) {
        print("========== CREATE WORKER REQUEST ==========");
        print(request.toJson());
      }

      final httpRequest = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoints.createWorker),
      );

      final token = _api.storage.read("token") ?? '';
      httpRequest.headers['Authorization'] = "Bearer $token";

      final data = request.toJson();
      data.forEach((key, value) {
        if (value != null) {
          httpRequest.fields[key] =
          value is List ? jsonEncode(value) : value.toString();
          if (kDebugMode) print("FIELD => $key : ${httpRequest.fields[key]}");
        }
      });

      void addFile(File file, String fieldName) {
        httpRequest.files.add(http.MultipartFile(
          fieldName,
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: file.path.split('/').last,
        ));
      }

      if (profileImage         != null) addFile(profileImage,         'profileImage');
      if (experienceCertificates != null) {
        for (final c in experienceCertificates) addFile(c, 'experienceCertificate');
      }
      if (governmentID         != null) addFile(governmentID,         'governmentID');

      final streamed = await httpRequest.send()
          .timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if (kDebugMode) {
        print("STATUS: ${response.statusCode}");
        print("BODY:   ${response.body}");
      }

      // nginx/proxy ne reject kiya (e.g. 413 — files bahut badi) to body
      // HTML hoti hai; jsonDecode se pehle pakad lo.
      final proxyError =
          proxyErrorMessage(response.statusCode, response.body);
      if (proxyError != null) {
        return CreateWorkerResponse(success: false, message: proxyError);
      }

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return CreateWorkerResponse.fromJson(json);
      }
      return CreateWorkerResponse(
          success: false,
          message: json['message']?.toString() ?? 'server_error_generic'.tr);
    } on TimeoutException {
      return CreateWorkerResponse(
          success: false, message: "Request timeout. Please try again.");
    } catch (e) {
      if (kDebugMode) print("[WorkerAPI] createProfile error: $e");
      return CreateWorkerResponse(success: false, message: e.toString());
    }
  }

  /// Worker profile edit — PUT /profile/edit/worker (multipart, partial).
  /// Sirf diye gaye [fields] hi jaate hain (backend partial update karta hai).
  /// Files optional — na dena ho to purane hi rehte hain.
  Future<CreateWorkerResponse> editWorkerProfile({
    Map<String, dynamic> fields = const {},
    File? profileImage,
    List<File>? experienceCertificates,
    /// Purane certificates jo user ne rakhe (paths). Backend final list
    /// = ye + naye files banata hai. null bhejne par purane waise hi
    /// rehte hain.
    List<String>? keepExperienceCertificates,
    File? governmentID,
  }) async {
    try {
      // camelCaseContentDisposition — backend ka multipart parser Capital
      // "Content-Disposition" hi accept karta hai (community posts wala fix).
      final form = dio.FormData(camelCaseContentDisposition: true);

      fields.forEach((key, value) {
        if (value == null) return;
        form.fields.add(MapEntry(
            key, value is List ? jsonEncode(value) : value.toString()));
      });

      MediaType mimeFor(String path) {
        final ext = path.split('.').last.toLowerCase();
        switch (ext) {
          case 'jpg':
          case 'jpeg':
            return MediaType('image', 'jpeg');
          case 'png':
            return MediaType('image', 'png');
          case 'webp':
            return MediaType('image', 'webp');
          case 'heic':
            return MediaType('image', 'heic');
          case 'pdf':
            return MediaType('application', 'pdf');
          default:
            return MediaType('application', 'octet-stream');
        }
      }

      void addFile(File file, String fieldName) {
        form.files.add(MapEntry(
          fieldName,
          dio.MultipartFile.fromFileSync(
            file.path,
            filename: file.path.split(RegExp(r'[/\\]')).last,
            contentType: mimeFor(file.path),
          ),
        ));
      }

      if (profileImage          != null) addFile(profileImage,          'profileImage');
      if (experienceCertificates != null) {
        for (final c in experienceCertificates) addFile(c, 'experienceCertificate');
      }
      // Kaunse purane certificates rakhne hain — backend final list
      // = ye + naye files banata hai. Ye na bhejo to purane waise hi
      // rehte hain (naye sirf add ho jaate hain).
      if (keepExperienceCertificates != null) {
        form.fields.add(MapEntry(
            'keepExperienceCertificate', jsonEncode(keepExperienceCertificates)));
      }
      if (governmentID          != null) addFile(governmentID,          'governmentID');

      if (kDebugMode) {
        print("========== EDIT WORKER REQUEST ==========");
        print("fields: ${form.fields}");
        print("files:  ${form.files.map((f) => '${f.key}:${f.value.filename}')}");
      }

      final token = _api.storage.read("token") ?? '';
      final client = dio.Dio(dio.BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout:    const Duration(seconds: 120),
        validateStatus: (_) => true, // error body ko khud handle karenge
      ));
      final resp = await client.put(
        ApiEndpoints.editWorker,
        data: form,
        options: dio.Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final status = resp.statusCode ?? 0;
      if (kDebugMode) print("EDIT WORKER $status: ${resp.data}");

      final data = resp.data;
      final proxyError = proxyErrorMessage(status, data?.toString() ?? '');
      if (proxyError != null) {
        return CreateWorkerResponse(success: false, message: proxyError);
      }

      final Map<String, dynamic> json = data is Map
          ? Map<String, dynamic>.from(data)
          : (data is String && data.isNotEmpty
              ? Map<String, dynamic>.from(jsonDecode(data))
              : {});

      if (status == 200) return CreateWorkerResponse.fromJson(json);
      return CreateWorkerResponse(
          success: false,
          message: json['message']?.toString() ?? "Failed to update profile");
    } on TimeoutException {
      return CreateWorkerResponse(
          success: false, message: "Request timeout. Please try again.");
    } catch (e) {
      if (kDebugMode) print("[WorkerAPI] editProfile error: $e");
      return CreateWorkerResponse(
          success: false, message: "Network error: Unable to update profile");
    }
  }

  Future<CreateWorkerResponse> getWorkerProfile() async {
    try {
      final response = await _api.getApiWithAuth(ApiEndpoints.getWorkerProfile);
      if (kDebugMode) print("GET PROFILE: ${response.body}");
      final json = jsonDecode(response.body);
      if (response.statusCode == 200) return CreateWorkerResponse.fromJson(json);
      return CreateWorkerResponse(
          success: false,
          message: json['message']?.toString() ?? "Failed to fetch profile");
    } catch (e) {
      return CreateWorkerResponse(success: false, message: e.toString());
    }
  }

  Future<CreateWorkerResponse> updateWorkerProfile(WorkerProfileRequest request) async {
    try {
      if (kDebugMode) print("UPDATE REQUEST: ${request.toJson()}");
      final response = await _api.putApiWithAuth(
          ApiEndpoints.updateWorkerProfile, jsonEncode(request.toJson()));
      if (kDebugMode) print("UPDATE RESPONSE: ${response.body}");
      final json = jsonDecode(response.body);
      if (response.statusCode == 200) return CreateWorkerResponse.fromJson(json);
      return CreateWorkerResponse(
          success: false,
          message: json['message']?.toString() ?? "Failed to update profile");
    } catch (e) {
      return CreateWorkerResponse(success: false, message: e.toString());
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SKILLS API SERVICE  (unchanged)
// ═══════════════════════════════════════════════════════════════════
class SkillsApiService {
  final RestApi _api = Get.find<RestApi>();

  Future<GetSkillsResponse> getAllSkills() async {
    try {
      final response = await _api.getApiWithAuth(ApiEndpoints.getAllSkills);
      if (response.statusCode == 200) {
        return GetSkillsResponse.fromJson(jsonDecode(response.body));
      }
      return GetSkillsResponse(success: false, message: "Failed to fetch skills", data: []);
    } catch (e) {
      if (kDebugMode) print("[SkillsAPI] error: $e");
      return GetSkillsResponse(
          success: false, message: "Network error", data: []);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  LOCATION API SERVICE  (unchanged)
// ═══════════════════════════════════════════════════════════════════
class LocationApiService {
  final RestApi _api = Get.find<RestApi>();

  Future<GetStatesResponse> getStates() async {
    try {
      final response = await _api.get(ApiEndpoints.getStates);
      if (response.statusCode == 200) {
        return GetStatesResponse.fromJson(jsonDecode(response.body));
      }
      return GetStatesResponse(success: false, message: "Failed to fetch states", data: []);
    } catch (e) {
      if (kDebugMode) print("[LocationAPI] getStates error: $e");
      return GetStatesResponse(success: false, message: "Network error", data: []);
    }
  }

  Future<GetCitiesResponse> getCities(int stateId) async {
    try {
      final response = await _api.get("${ApiEndpoints.getCities}/$stateId");
      if (response.statusCode == 200) {
        return GetCitiesResponse.fromJson(jsonDecode(response.body));
      }
      return GetCitiesResponse(success: false, message: "Failed to fetch cities", data: []);
    } catch (e) {
      if (kDebugMode) print("[LocationAPI] getCities error: $e");
      return GetCitiesResponse(success: false, message: "Network error", data: []);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DOCUMENT UPLOAD API SERVICE  (unchanged)
// ═══════════════════════════════════════════════════════════════════
class DocumentUploadService {
  final RestApi _api = Get.find<RestApi>();

  Future<DocumentUploadResponse> _upload(File file, String endpoint, String field) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(endpoint));
      request.headers['Authorization'] =
      "Bearer ${_api.storage.read("token") ?? ''}";
      request.files.add(http.MultipartFile(
        field,
        file.readAsBytes().asStream(),
        file.lengthSync(),
        filename: file.path.split('/').last,
      ));
      final streamed  = await request.send().timeout(const Duration(seconds: 30));
      final response  = await http.Response.fromStream(streamed);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return DocumentUploadResponse.fromJson(jsonDecode(response.body));
      }
      final proxyError =
          proxyErrorMessage(response.statusCode, response.body);
      return DocumentUploadResponse(
          success: false, message: proxyError ?? "Upload failed");
    } on TimeoutException {
      return DocumentUploadResponse(success: false, message: "Upload timed out");
    } catch (e) {
      return DocumentUploadResponse(success: false, message: "Network error");
    }
  }

  Future<DocumentUploadResponse> uploadIdProof(File file) =>
      _upload(file, ApiEndpoints.uploadIdProof, 'file');

  Future<DocumentUploadResponse> uploadWorkPhoto(File file) =>
      _upload(file, ApiEndpoints.uploadWorkPhoto, 'file');

  Future<DocumentUploadResponse> uploadExperienceCert(File file) =>
      _upload(file, ApiEndpoints.uploadExperienceCert, 'file');
}

// ═══════════════════════════════════════════════════════════════════
//  JOBS API SERVICE — /api/jobs (list + detail)
// ═══════════════════════════════════════════════════════════════════
class JobsApiService {
  final RestApi _api = Get.find<RestApi>();

  Future<JobListResponse> getJobs() async {
    try {
      final response = await _api.getApiWithAuth(ApiEndpoints.jobs);
      if (response.statusCode == 200) {
        return JobListResponse.fromJson(jsonDecode(response.body));
      }
      return const JobListResponse(
          success: false, message: "Failed to load jobs");
    } catch (e) {
      if (kDebugMode) print("[JobsAPI] getJobs error: $e");
      return const JobListResponse(success: false, message: "Network error");
    }
  }

  /// Vendor: apni saari jobs (pending + approved + rejected) — GET /jobs/my.
  Future<JobListResponse> getMyJobs() async {
    try {
      final response = await _api.getApiWithAuth(ApiEndpoints.myJobs);
      if (response.statusCode == 200) {
        return JobListResponse.fromJson(jsonDecode(response.body));
      }
      return const JobListResponse(
          success: false, message: "Failed to load your jobs");
    } catch (e) {
      if (kDebugMode) print("[JobsAPI] getMyJobs error: $e");
      return const JobListResponse(success: false, message: "Network error");
    }
  }

  Future<JobModel?> getJobById(String id) async {
    try {
      final response = await _api.getApiWithAuth(ApiEndpoints.jobById(id));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        if (data is Map) {
          return JobModel.fromJson(Map<String, dynamic>.from(data));
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print("[JobsAPI] getJobById error: $e");
      return null;
    }
  }

  /// Worker ke applied jobs (bearer token).
  Future<AppliedJobsResponse> getAppliedJobs() async {
    try {
      final response = await _api.getApiWithAuth(ApiEndpoints.appliedJobs);
      if (response.statusCode == 200) {
        return AppliedJobsResponse.fromJson(jsonDecode(response.body));
      }
      return const AppliedJobsResponse(
          success: false, message: "Failed to load applied jobs");
    } catch (e) {
      if (kDebugMode) print("[JobsAPI] getAppliedJobs error: $e");
      return const AppliedJobsResponse(success: false, message: "Network error");
    }
  }

  /// Job pe direct apply karo (bearer token, koi input nahi — empty body).
  Future<JobActionResponse> applyToJob(String jobId) async {
    try {
      final response = await _api.postApiWithAuth(
          ApiEndpoints.applyJob(jobId), jsonEncode({}));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return JobActionResponse.fromJson(jsonDecode(response.body));
      }
      // `code` bhi chahiye — backend SUBSCRIPTION_REQUIRED bhejta hai jab
      // worker ke paas active plan nahi hai, jispe UI Plans screen kholti hai.
      final json = jsonDecode(response.body);
      return JobActionResponse(
          success: false,
          code: json['code']?.toString(),
          message: json['message']?.toString() ?? "Failed to apply");
    } catch (e) {
      if (kDebugMode) print("[JobsAPI] applyToJob error: $e");
      return const JobActionResponse(
          success: false, message: "Network error: Unable to apply");
    }
  }

  /// Job like/unlike toggle — PUT /jobs/:id/like
  Future<JobActionResponse> likeJob(String jobId) async {
    try {
      final response =
          await _api.putApiWithAuth(ApiEndpoints.likeJob(jobId), '');
      final json = jsonDecode(response.body);
      return JobActionResponse.fromJson(json);
    } catch (e) {
      if (kDebugMode) print("[JobsAPI] likeJob error: $e");
      return const JobActionResponse(
          success: false, message: "Network error: Unable to like");
    }
  }

  /// Vendor: naya job create — POST /jobs (verified vendor only).
  Future<JobActionResponse> createJob(Map<String, dynamic> body) async {
    try {
      final response =
          await _api.postApiWithAuth(ApiEndpoints.jobs, jsonEncode(body));
      final json = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return JobActionResponse.fromJson(json);
      }
      // Error par `code` bhi chahiye — backend SUBSCRIPTION_REQUIRED /
      // WORKER_QUOTA_EXCEEDED bhejta hai, jisse UI decide karta hai ki
      // vendor ko Plans screen par bhejna hai ya nahi.
      return JobActionResponse(
          success: false,
          code: json['code']?.toString(),
          message: json['message']?.toString() ?? "Failed to create job");
    } catch (e) {
      if (kDebugMode) print("[JobsAPI] createJob error: $e");
      return const JobActionResponse(
          success: false, message: "Network error: Unable to create job");
    }
  }

  /// Vendor: job ke applicants (jinhone apply kiya) — GET /jobs/:id/applicants.
  Future<JobApplicantsResponse> getApplicants(String jobId) async {
    try {
      final response =
          await _api.getApiWithAuth(ApiEndpoints.jobApplicants(jobId));
      if (response.statusCode == 200) {
        return JobApplicantsResponse.fromJson(jsonDecode(response.body));
      }
      final json = jsonDecode(response.body);
      return JobApplicantsResponse(
          success: false,
          message: json['message']?.toString() ?? "Failed to load applicants");
    } catch (e) {
      if (kDebugMode) print("[JobsAPI] getApplicants error: $e");
      return const JobApplicantsResponse(
          success: false, message: "Network error");
    }
  }

  /// Vendor: applicant ka status update (confirm/reject/shortlist) —
  /// PUT /jobs/:jobId/applicants/:applicationId/status { status }.
  Future<JobActionResponse> updateApplicantStatus(
      String jobId, String applicationId, String status) async {
    try {
      final response = await _api.putApiWithAuth(
        ApiEndpoints.jobApplicantStatus(jobId, applicationId),
        jsonEncode({"status": status}),
      );
      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return JobActionResponse.fromJson(json);
      }
      return JobActionResponse(
          success: false,
          message: json['message']?.toString() ?? "Failed to update status");
    } catch (e) {
      if (kDebugMode) print("[JobsAPI] updateApplicantStatus error: $e");
      return const JobActionResponse(
          success: false, message: "Network error: Unable to update status");
    }
  }

  /// Vendor: apna job delete — DELETE /jobs/:id (owner/admin).
  Future<JobActionResponse> deleteJob(String jobId) async {
    try {
      final response = await _api.deleteApiWithAuth(
          ApiEndpoints.jobById(jobId), jsonEncode({}));
      final json = jsonDecode(response.body);
      return JobActionResponse.fromJson(json);
    } catch (e) {
      if (kDebugMode) print("[JobsAPI] deleteJob error: $e");
      return const JobActionResponse(
          success: false, message: "Network error: Unable to delete job");
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PROFILE API SERVICE — /api/profile/me
// ═══════════════════════════════════════════════════════════════════
class ProfileApiService {
  final RestApi _api = Get.find<RestApi>();

  Future<MyProfileResponse> getMe() async {
    try {
      final response = await _api.getApiWithAuth(ApiEndpoints.myProfile);
      if (response.statusCode == 200) {
        return MyProfileResponse.fromJson(jsonDecode(response.body));
      }
      return const MyProfileResponse(
          success: false, message: "Failed to load profile");
    } catch (e) {
      if (kDebugMode) print("[ProfileAPI] getMe error: $e");
      return const MyProfileResponse(success: false, message: "Network error");
    }
  }

  // ── Change phone number — step 1: send OTP to the new number ──────
  Future<PhoneChangeOtpResponse> sendPhoneChangeOtp(String newPhone) async {
    try {
      final response = await _api.postApiWithAuth(
        ApiEndpoints.phoneSendOtp,
        jsonEncode({"newPhone": newPhone}),
      );
      final body = jsonDecode(response.body);
      return PhoneChangeOtpResponse.fromJson(body);
    } catch (e) {
      if (kDebugMode) print("[ProfileAPI] sendPhoneChangeOtp error: $e");
      return const PhoneChangeOtpResponse(
          success: false, message: "Network error: Unable to send OTP");
    }
  }

  // ── Change phone number — step 2: verify OTP, applies the change ──
  Future<PhoneChangeOtpResponse> verifyPhoneChangeOtp(String otp) async {
    try {
      final response = await _api.postApiWithAuth(
        ApiEndpoints.phoneVerifyOtp,
        jsonEncode({"otp": otp}),
      );
      final body = jsonDecode(response.body);
      return PhoneChangeOtpResponse.fromJson(body);
    } catch (e) {
      if (kDebugMode) print("[ProfileAPI] verifyPhoneChangeOtp error: $e");
      return const PhoneChangeOtpResponse(
          success: false, message: "Network error: Unable to verify OTP");
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  COMMENTS API SERVICE — /api/community/posts/:postId/comments
// ═══════════════════════════════════════════════════════════════════
class CommentsApiService {
  /// [forJob] = true → job comments (/jobs/:id/comments),
  /// false (default) → community post comments.
  final bool forJob;
  CommentsApiService({this.forJob = false});

  final RestApi _api = Get.find<RestApi>();

  String _listUrl(String id) =>
      forJob ? ApiEndpoints.jobComments(id) : ApiEndpoints.postComments(id);

  Future<CommentsResponse> getComments(String postId) async {
    try {
      // Post comments ka backend default 10 hi bhejta tha — baaki dikhte hi
      // nahi the. Ek baar me 100 (har ek ke saath uske replies).
      final url = forJob ? _listUrl(postId) : '${_listUrl(postId)}?limit=100';
      final r = await _api.getApiWithAuth(url);
      if (r.statusCode == 200) {
        return CommentsResponse.fromJson(jsonDecode(r.body));
      }
      return const CommentsResponse(
          success: false, message: "Failed to load comments");
    } catch (e) {
      if (kDebugMode) print("[CommentsAPI] get error: $e");
      return const CommentsResponse(success: false, message: "Network error");
    }
  }

  /// [parentId] diya ho to ye us comment ka reply hai (sirf post comments).
  Future<CommentActionResponse> addComment(String postId, String text,
      {String? parentId}) async {
    try {
      final r = await _api.postApiWithAuth(
          _listUrl(postId),
          jsonEncode({
            "comment": text,
            if (!forJob && parentId != null) "parentComment": parentId,
          }));
      if (r.statusCode == 200 || r.statusCode == 201) {
        return CommentActionResponse.fromJson(jsonDecode(r.body));
      }
      final m = jsonDecode(r.body)['message']?.toString();
      return CommentActionResponse(
          success: false, message: m ?? "Failed to add comment");
    } catch (e) {
      if (kDebugMode) print("[CommentsAPI] add error: $e");
      return const CommentActionResponse(
          success: false, message: "Network error");
    }
  }

  Future<CommentActionResponse> updateComment(
      String postId, String commentId, String text) async {
    try {
      final r = await _api.putApiWithAuth(
          ApiEndpoints.postComment(postId, commentId),
          jsonEncode({"comment": text}));
      if (r.statusCode == 200) {
        return CommentActionResponse.fromJson(jsonDecode(r.body));
      }
      final m = jsonDecode(r.body)['message']?.toString();
      return CommentActionResponse(
          success: false, message: m ?? "Failed to update comment");
    } catch (e) {
      if (kDebugMode) print("[CommentsAPI] update error: $e");
      return const CommentActionResponse(
          success: false, message: "Network error");
    }
  }

  Future<CommentActionResponse> deleteComment(
      String postId, String commentId) async {
    try {
      final r = await _api.deleteApiWithAuth(
          ApiEndpoints.postComment(postId, commentId), '');
      if (r.statusCode == 200) {
        return CommentActionResponse.fromJson(jsonDecode(r.body));
      }
      final m = jsonDecode(r.body)['message']?.toString();
      return CommentActionResponse(
          success: false, message: m ?? "Failed to delete comment");
    } catch (e) {
      if (kDebugMode) print("[CommentsAPI] delete error: $e");
      return const CommentActionResponse(
          success: false, message: "Network error");
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  VENDOR API SERVICE — /profile/create/vendor + /profile/edit/vendor
// ═══════════════════════════════════════════════════════════════════
class VendorApiService {
  final RestApi _api = Get.find<RestApi>();

  MediaType _mimeFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'pdf':
        return MediaType('application', 'pdf');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  dio.MultipartFile _part(File f) => dio.MultipartFile.fromFileSync(
        f.path,
        filename: f.path.split(RegExp(r'[/\\]')).last,
        contentType: _mimeFor(f.path),
      );

  Future<dio.Response> _sendMultipart(
      String method, String url, dio.FormData form) async {
    final token = _api.storage.read("token") ?? '';
    final client = dio.Dio(dio.BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 120),
      validateStatus: (_) => true,
    ));
    final opts = dio.Options(headers: {'Authorization': 'Bearer $token'});
    return method == 'PUT'
        ? client.put(url, data: form, options: opts)
        : client.post(url, data: form, options: opts);
  }

  Map<String, dynamic> _asJson(dio.Response resp) {
    final data = resp.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      // Proxy error page (HTML) bhi String hi hoti hai — throw mat karo.
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {/* JSON nahi hai — khaali map */}
    }
    return {};
  }

  /// Vendor profile create — panCardImage + gstCertificate MANDATORY.
  /// Sets userType='vendor' backend par.
  Future<CreateWorkerResponse> createVendorProfile({
    required Map<String, dynamic> fields,
    File? panCardImage, // optional — user chhod sakta hai
    required File gstCertificate,
    File? companyLogo,
    File? profileImage,
  }) async {
    try {
      final form = dio.FormData(camelCaseContentDisposition: true);
      fields.forEach((k, v) {
        if (v != null) form.fields.add(MapEntry(k, v.toString()));
      });
      if (panCardImage != null) {
        form.files.add(MapEntry('panCardImage', _part(panCardImage)));
      }
      form.files.add(MapEntry('gstCertificate', _part(gstCertificate)));
      if (companyLogo != null) {
        form.files.add(MapEntry('companyLogo', _part(companyLogo)));
      }
      if (profileImage != null) {
        form.files.add(MapEntry('profileImage', _part(profileImage)));
      }

      if (kDebugMode) print("[VendorAPI] CREATE fields: ${form.fields}");
      final resp =
          await _sendMultipart('POST', ApiEndpoints.createVendor, form);
      final proxyError = proxyErrorMessage(
          resp.statusCode ?? 0, resp.data?.toString() ?? '');
      if (proxyError != null) {
        return CreateWorkerResponse(success: false, message: proxyError);
      }
      final json = _asJson(resp);
      if (kDebugMode) print("[VendorAPI] CREATE ${resp.statusCode}: $json");
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return CreateWorkerResponse.fromJson(json);
      }
      return CreateWorkerResponse(
          success: false,
          message:
              json['message']?.toString() ?? "Failed to create vendor profile");
    } catch (e) {
      if (kDebugMode) print("[VendorAPI] create error: $e");
      return CreateWorkerResponse(
          success: false, message: "Network error: Unable to create profile");
    }
  }

  /// Vendor profile edit — partial (sirf diye gaye fields/files).
  Future<CreateWorkerResponse> editVendorProfile({
    Map<String, dynamic> fields = const {},
    File? panCardImage,
    File? gstCertificate,
    File? companyLogo,
    File? profileImage,
  }) async {
    try {
      final form = dio.FormData(camelCaseContentDisposition: true);
      fields.forEach((k, v) {
        if (v != null) form.fields.add(MapEntry(k, v.toString()));
      });
      if (panCardImage != null) {
        form.files.add(MapEntry('panCardImage', _part(panCardImage)));
      }
      if (gstCertificate != null) {
        form.files.add(MapEntry('gstCertificate', _part(gstCertificate)));
      }
      if (companyLogo != null) {
        form.files.add(MapEntry('companyLogo', _part(companyLogo)));
      }
      if (profileImage != null) {
        form.files.add(MapEntry('profileImage', _part(profileImage)));
      }

      final resp = await _sendMultipart('PUT', ApiEndpoints.editVendor, form);
      final proxyError = proxyErrorMessage(
          resp.statusCode ?? 0, resp.data?.toString() ?? '');
      if (proxyError != null) {
        return CreateWorkerResponse(success: false, message: proxyError);
      }
      final json = _asJson(resp);
      if (kDebugMode) print("[VendorAPI] EDIT ${resp.statusCode}: $json");
      if (resp.statusCode == 200) return CreateWorkerResponse.fromJson(json);
      return CreateWorkerResponse(
          success: false,
          message: json['message']?.toString() ?? "Failed to update profile");
    } catch (e) {
      if (kDebugMode) print("[VendorAPI] edit error: $e");
      return CreateWorkerResponse(
          success: false, message: "Network error: Unable to update profile");
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  AMENITIES API SERVICE — /amenities/grouped (job create ke liye)
// ═══════════════════════════════════════════════════════════════════
class AmenitiesApiService {
  final RestApi _api = Get.find<RestApi>();

  /// Grouped amenities: { "Financial Benefits": [JobAmenity...], ... }
  /// `/amenities/grouped` abhi live backend par 500 deta hai (server-side
  /// bug — "amenities is not defined"), isliye pehle wahi try karo aur
  /// khaali/fail ho to flat `/amenities` (jo kaam karta hai) se client-side
  /// group kar lo — same parsing dono shape handle karti hai.
  Future<Map<String, List<JobAmenity>>> getGrouped() async {
    final grouped = await _fetchAndGroup(ApiEndpoints.amenitiesGrouped);
    if (grouped.isNotEmpty) return grouped;
    return _fetchAndGroup(ApiEndpoints.amenities);
  }

  /// Flexible parse: data Map (category→list) ya List (category field se group).
  Future<Map<String, List<JobAmenity>>> _fetchAndGroup(String url) async {
    try {
      final r = await _api.getApiWithAuth(url);
      if (r.statusCode != 200) return {};
      final json = jsonDecode(r.body);
      final raw = json['data'];
      final Map<String, List<JobAmenity>> out = {};

      void add(String cat, Map m) {
        out
            .putIfAbsent(cat, () => [])
            .add(JobAmenity.fromJson(Map<String, dynamic>.from(m)));
      }

      if (raw is Map) {
        raw.forEach((cat, list) {
          if (list is List) {
            for (final e in list) {
              if (e is Map) add(cat.toString(), e);
            }
          }
        });
      } else if (raw is List) {
        for (final e in raw) {
          if (e is Map) add((e['category'] ?? 'Other').toString(), e);
        }
      }
      return out;
    } catch (e) {
      if (kDebugMode) print("[AmenitiesAPI] fetch error ($url): $e");
      return {};
    }
  }

  /// Vendor custom amenity add — POST /amenities { name, category }.
  /// category must be one of the 7 backend categories.
  Future<JobActionResponse> addAmenity(String name, String category) async {
    try {
      final r = await _api.postApiWithAuth(ApiEndpoints.amenities,
          jsonEncode({"name": name, "category": category}));
      final json = jsonDecode(r.body);
      if (r.statusCode == 200 || r.statusCode == 201) {
        return JobActionResponse.fromJson(json);
      }
      return JobActionResponse(
          success: false,
          message: json['message']?.toString() ?? "Failed to add amenity");
    } catch (e) {
      if (kDebugMode) print("[AmenitiesAPI] addAmenity error: $e");
      return const JobActionResponse(
          success: false, message: "Network error: Unable to add amenity");
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MISC API SERVICE — logout / language / fcm-token / plans / legal
// ═══════════════════════════════════════════════════════════════════
class MiscApiService {
  final RestApi _api = Get.find<RestApi>();

  /// Logout — backend token blacklist karta hai. Fail ho to bhi app
  /// local session clear karega (caller handle karta hai).
  Future<bool> logout() async {
    try {
      final r = await _api.postApiWithAuth(ApiEndpoints.logout, '');
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("[MiscAPI] logout error: $e");
      return false;
    }
  }

  /// App language backend me save — { "language": "hindi" | "english" }
  Future<bool> saveLanguage(String language) async {
    try {
      final r = await _api.postApiWithAuth(
          ApiEndpoints.setLanguage, jsonEncode({"language": language}));
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("[MiscAPI] language error: $e");
      return false;
    }
  }

  /// FCM device token save (push notifications).
  Future<bool> saveFcmToken(String fcmToken) async {
    if (fcmToken.isEmpty) return false;
    try {
      final r = await _api.postApiWithAuth(
          ApiEndpoints.saveFcmToken, jsonEncode({"fcmToken": fcmToken}));
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("[MiscAPI] fcm error: $e");
      return false;
    }
  }

  /// Subscription plans (userType ke hisaab se filtered).
  Future<PlansResponse> getPlans() async {
    try {
      final r = await _api.getApiWithAuth(ApiEndpoints.plans);
      if (r.statusCode == 200) {
        return PlansResponse.fromJson(jsonDecode(r.body));
      }
      return const PlansResponse(success: false);
    } catch (e) {
      if (kDebugMode) print("[MiscAPI] plans error: $e");
      return const PlansResponse(success: false);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  LEGAL API SERVICE — /api/legal/policies (Privacy + Terms)
// ═══════════════════════════════════════════════════════════════════
class LegalApiService {
  final RestApi _api = Get.find<RestApi>();

  /// policyType ('PRIVACY_POLICY' | 'TERMS_AND_CONDITIONS') → content.
  /// Backend saari active policies (version desc) deta hai — har type ka
  /// pehla (latest) rakhte hain. Fail/empty par khaali map (caller static
  /// fallback dikha deta hai).
  Future<Map<String, String>> getPolicies() async {
    try {
      final r = await _api.getApiWithAuth(ApiEndpoints.legalPolicies);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body)['data'];
        final map = <String, String>{};
        if (data is List) {
          for (final p in data) {
            if (p is Map) {
              final type = p['policyType']?.toString();
              final content = p['content']?.toString();
              if (type != null && content != null && !map.containsKey(type)) {
                map[type] = content;
              }
            }
          }
        }
        return map;
      }
    } catch (e) {
      if (kDebugMode) print("[LegalAPI] getPolicies error: $e");
    }
    return const {};
  }

  /// Contact Support screen ka data (phone/whatsapp/email/hours) — admin ke
  /// Platform Settings se manage hota hai (PlatformSettings.supportContact).
  ///
  /// Ye paid feature hai: plan na ho to backend 403 +
  /// `code: SUBSCRIPTION_REQUIRED` deta hai. Isliye yahan khaali map nahi,
  /// ek result lautate hain — screen "abhi configure nahi hua" aur "plan
  /// chahiye" me farq kar sake.
  Future<SupportContactResult> getSupportContact() async {
    try {
      final r = await _api.getApiWithAuth(ApiEndpoints.supportContact);
      final json = jsonDecode(r.body);
      if (r.statusCode == 200) {
        final data = json['data'];
        if (data is Map) {
          return SupportContactResult(
            contact:
                data.map((k, v) => MapEntry(k.toString(), (v ?? '').toString())),
          );
        }
        return const SupportContactResult();
      }
      return SupportContactResult(
        code: json['code']?.toString(),
        message: json['message']?.toString(),
      );
    } catch (e) {
      if (kDebugMode) print("[LegalAPI] getSupportContact error: $e");
      return const SupportContactResult();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  APP CONFIG API SERVICE — /api/app-config (public, no token)
// ═══════════════════════════════════════════════════════════════════
class AppConfigApiService {
  final RestApi _api = Get.find<RestApi>();

  /// Maintenance notice. Fail/offline par `null` — us case me app bilkul
  /// normal chalti hai (config na mile to kabhi block/notice nahi karte).
  Future<MaintenanceInfo?> getMaintenance() async {
    try {
      final r = await _api.get(ApiEndpoints.appConfig);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body)['data'];
        if (data is Map && data['maintenance'] is Map) {
          return MaintenanceInfo.fromJson(
              Map<String, dynamic>.from(data['maintenance'] as Map));
        }
      }
    } catch (e) {
      if (kDebugMode) print("[AppConfigAPI] getMaintenance error: $e");
    }
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════
//  COMMUNITY API SERVICE — /api/community/posts/mine ("My Posts")
// ═══════════════════════════════════════════════════════════════════
class CommunityApiService {
  final RestApi _api = Get.find<RestApi>();

  /// Current user's own posts — any approvalStatus/isActive, paginated.
  /// Dedicated endpoint (not embedded in /profile/me anymore) so the
  /// "My Posts" section can page independently of the profile fetch.
  Future<CommunityFeedData> getMyPosts({int page = 1, int limit = 20}) async {
    try {
      final r = await _api.getApiWithAuth(
          "${ApiEndpoints.myPosts}?page=$page&limit=$limit");
      if (r.statusCode == 200) {
        return CommunityFeedData.fromJson(jsonDecode(r.body));
      }
      return CommunityFeedData(success: false, data: const []);
    } catch (e) {
      if (kDebugMode) print("[CommunityAPI] getMyPosts error: $e");
      return CommunityFeedData(success: false, data: const []);
    }
  }

  /// Kisi worker ke posts — vendor applicant ko parakhte waqt dekhta hai.
  /// Backend 403 deta hai agar us worker ne is vendor ki koi job par
  /// apply nahi kiya, isliye empty result normal hai.
  Future<CommunityFeedData> getPostsByUser(String userId,
      {int page = 1, int limit = 20}) async {
    try {
      final r = await _api.getApiWithAuth(
          "${ApiEndpoints.communityPostsByUser(userId)}?page=$page&limit=$limit");
      if (r.statusCode == 200) {
        return CommunityFeedData.fromJson(jsonDecode(r.body));
      }
      return CommunityFeedData(success: false, data: const []);
    } catch (e) {
      if (kDebugMode) print("[CommunityAPI] getPostsByUser error: $e");
      return CommunityFeedData(success: false, data: const []);
    }
  }

  /// Ek single post — shared deep link kholne ke liye. Feed se nahi le
  /// sakte kyunki wo post paged feed me kahin bhi ho sakti hai (ya
  /// bahut purani ho).
  ///
  /// Post hataayi/reject ho gayi ho to backend 404 deta hai —
  /// `(null, message)` return karke UI wahi message dikha deta hai.
  Future<(CommunityFeedModel?, String?)> getPostById(String postId) async {
    try {
      final r = await _api.getApiWithAuth("${ApiEndpoints.communityPosts}/$postId");
      final json = jsonDecode(r.body);
      if (r.statusCode == 200 && json['data'] != null) {
        return (
          CommunityFeedModel.fromJson(Map<String, dynamic>.from(json['data'])),
          null,
        );
      }
      return (null, json['message']?.toString());
    } catch (e) {
      if (kDebugMode) print("[CommunityAPI] getPostById error: $e");
      return (null, null);
    }
  }

  /// Like/unlike toggle. `ok` false ho to caller optimistic update revert
  /// kare; `count` server ka asli likesCount hai (null bhi ho sakta hai).
  Future<({bool ok, int? count})> toggleLike(String postId) async {
    try {
      final r = await _api.putApiWithAuth(
          ApiEndpoints.communityPostLike(postId), '');
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        return (ok: true, count: body['data']?['likesCount'] as int?);
      }
      return (ok: false, count: null);
    } catch (e) {
      if (kDebugMode) print("[CommunityAPI] toggleLike error: $e");
      return (ok: false, count: null);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  NOTIFICATION API SERVICE — /api/notifications
// ═══════════════════════════════════════════════════════════════════
class NotificationApiService {
  final RestApi _api = Get.find<RestApi>();

  Future<NotificationListResponse> getMyNotifications({int page = 1}) async {
    try {
      final r = await _api.getApiWithAuth(
          "${ApiEndpoints.notifications}?page=$page&limit=20");
      if (r.statusCode == 200) {
        return NotificationListResponse.fromJson(jsonDecode(r.body));
      }
      return const NotificationListResponse(
          success: false, message: "Failed to load notifications");
    } catch (e) {
      if (kDebugMode) print("[NotificationAPI] list error: $e");
      return const NotificationListResponse(
          success: false, message: "Network error");
    }
  }

  Future<bool> markRead(String id) async {
    try {
      final r = await _api.putApiWithAuth(ApiEndpoints.notificationRead(id), '');
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("[NotificationAPI] markRead error: $e");
      return false;
    }
  }

  Future<bool> markAllRead() async {
    try {
      final r = await _api.putApiWithAuth(ApiEndpoints.notificationsReadAll, '');
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("[NotificationAPI] markAllRead error: $e");
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      final r = await _api.deleteApiWithAuth(ApiEndpoints.notificationById(id), '');
      return r.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("[NotificationAPI] delete error: $e");
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PAYMENT API SERVICE — Razorpay order create + verify (backend)
// ═══════════════════════════════════════════════════════════════════
// Razorpay ka key_secret app me kabhi nahi aata — order banana aur
// signature verify karna dono hamesha backend pe hote hain. Ye service
// sirf un 2 backend endpoints ko call karta hai.
class PaymentApiService {
  final RestApi _api = Get.find<RestApi>();

  /// Step 1 — subscription plan ke liye Razorpay order banwao.
  Future<CreateOrderResponse> createOrder(String planId) async {
    try {
      final r = await _api.postApiWithAuth(
          ApiEndpoints.createOrder, jsonEncode({"planId": planId}));
      final json = jsonDecode(r.body);
      if (r.statusCode == 200 || r.statusCode == 201) {
        return CreateOrderResponse.fromJson(json);
      }
      return CreateOrderResponse(
        success: false,
        message: json['message']?.toString() ?? "Order create nahi hua",
      );
    } catch (e) {
      if (kDebugMode) print("[PaymentAPI] createOrder error: $e");
      return const CreateOrderResponse(
          success: false, message: "Network error: Unable to create order");
    }
  }

  /// Step 2 — Razorpay checkout ke baad payment signature backend se verify.
  Future<VerifyPaymentResponse> verifyPayment({
    required String planId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final r = await _api.postApiWithAuth(
        ApiEndpoints.verifyPayment,
        jsonEncode({
          "planId": planId,
          "razorpay_order_id": razorpayOrderId,
          "razorpay_payment_id": razorpayPaymentId,
          "razorpay_signature": razorpaySignature,
        }),
      );
      final json = jsonDecode(r.body);
      if (r.statusCode == 200 || r.statusCode == 201) {
        return VerifyPaymentResponse.fromJson(json);
      }
      return VerifyPaymentResponse(
        success: false,
        message: json['message']?.toString() ?? "Payment verify nahi hua",
      );
    } catch (e) {
      if (kDebugMode) print("[PaymentAPI] verifyPayment error: $e");
      return const VerifyPaymentResponse(
          success: false, message: "Network error: Unable to verify payment");
    }
  }

  // ── Auto-payment (Razorpay Subscriptions) ───────────────────────

  /// Step 1 — auto-pay ke liye Razorpay subscription banwao.
  Future<CreateSubscriptionResponse> createSubscription(String planId) async {
    try {
      final r = await _api.postApiWithAuth(
          ApiEndpoints.createSubscription, jsonEncode({"planId": planId}));
      final json = jsonDecode(r.body);
      if (r.statusCode == 200 || r.statusCode == 201) {
        return CreateSubscriptionResponse.fromJson(json);
      }
      return CreateSubscriptionResponse(
        success: false,
        message: json['message']?.toString() ??
            "Auto-payment start nahi hua",
      );
    } catch (e) {
      if (kDebugMode) print("[PaymentAPI] createSubscription error: $e");
      return const CreateSubscriptionResponse(
          success: false,
          message: "Network error: Unable to start auto-payment");
    }
  }

  /// Step 2 — mandate authorize hone ke baad backend se verify.
  Future<VerifyPaymentResponse> verifySubscription({
    required String planId,
    required String razorpaySubscriptionId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final r = await _api.postApiWithAuth(
        ApiEndpoints.verifySubscription,
        jsonEncode({
          "planId": planId,
          "razorpay_subscription_id": razorpaySubscriptionId,
          "razorpay_payment_id": razorpayPaymentId,
          "razorpay_signature": razorpaySignature,
        }),
      );
      final json = jsonDecode(r.body);
      if (r.statusCode == 200 || r.statusCode == 201) {
        return VerifyPaymentResponse.fromJson(json);
      }
      return VerifyPaymentResponse(
        success: false,
        message: json['message']?.toString() ?? "Auto-payment verify nahi hua",
      );
    } catch (e) {
      if (kDebugMode) print("[PaymentAPI] verifySubscription error: $e");
      return const VerifyPaymentResponse(
          success: false,
          message: "Network error: Unable to verify auto-payment");
    }
  }

  /// Auto-payment band karo. Plan current cycle ke end tak chalta rahega.
  Future<CancelAutoPayResponse> cancelSubscription() async {
    try {
      final r = await _api.postApiWithAuth(
          ApiEndpoints.cancelSubscription, jsonEncode({}));
      final json = jsonDecode(r.body);
      if (r.statusCode == 200) {
        return CancelAutoPayResponse.fromJson(json);
      }
      return CancelAutoPayResponse(
        success: false,
        message: json['message']?.toString() ?? "Auto-payment cancel nahi hua",
      );
    } catch (e) {
      if (kDebugMode) print("[PaymentAPI] cancelSubscription error: $e");
      return const CancelAutoPayResponse(
          success: false,
          message: "Network error: Unable to cancel auto-payment");
    }
  }
}