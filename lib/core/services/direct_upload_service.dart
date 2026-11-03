import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import '../../app/config/app_config.dart';
import 'api_services.dart';

// ═══════════════════════════════════════════════════════════════════
//  DIRECT UPLOAD — phone → Cloudinary (seedha), backend ko sirf URL
// ═══════════════════════════════════════════════════════════════════
// Backend ab files khud nahi leta (multipart hata diya). Har file ke liye:
//   1. POST /uploads/signature {context}  → backend signed params deta hai
//   2. file seedha Cloudinary par upload  → secure_url milta hai
//   3. POST /uploads/confirm               → backend ownership check karta hai
// Phir profile/post API ko ye URLs JSON me bhejte hain.
//
// `context` wahi naam hai jo backend ke UPLOAD_CONTEXTS me hai
// (profileImage, governmentID, postImage, postVideo, ...).

class UploadException implements Exception {
  final String message;
  UploadException(this.message);
  @override
  String toString() => message;
}

class DirectUploadService {
  DirectUploadService._();

  static final dio.Dio _client = dio.Dio(dio.BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(minutes: 5),
    validateStatus: (_) => true,
  ));

  static String get _token => Get.find<RestApi>().storage.read("token") ?? '';

  static Map<String, dynamic> _json(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      try {
        final d = jsonDecode(data);
        if (d is Map) return Map<String, dynamic>.from(d);
      } catch (_) {/* HTML / plain text */}
    }
    return {};
  }

  static MediaType _mimeFor(String path) {
    switch (path.split('.').last.toLowerCase()) {
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
      case 'mp4':
        return MediaType('video', 'mp4');
      case 'mov':
        return MediaType('video', 'quicktime');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  /// Ek file upload karo, Cloudinary ka secure_url lautao.
  /// Fail hone par [UploadException] (user ko dikhane layak message).
  static Future<String> upload(File file, String context,
      {void Function(double progress)? onProgress}) async {
    try {
      return await _upload(file, context, onProgress: onProgress);
    } on UploadException {
      rethrow;
    } catch (e) {
      // Network gaya / timeout / Cloudinary down.
      if (kDebugMode) print("[Upload] $context error: $e");
      throw UploadException("upload_failed_error".tr);
    }
  }

  static Future<String> _upload(File file, String context,
      {void Function(double progress)? onProgress}) async {
    final auth = {'Authorization': 'Bearer $_token'};

    // ── 1. Signature ────────────────────────────────────────────
    final sigResp = await _client.post(
      '${AppConfig.baseUrl}/uploads/signature',
      data: {'context': context},
      options: dio.Options(headers: auth, contentType: 'application/json'),
    );
    final sigJson = _json(sigResp.data);
    if (sigResp.statusCode != 200 || sigJson['data'] is! Map) {
      if (kDebugMode) print('[Upload] signature ${sigResp.statusCode}: ${sigResp.data}');
      throw UploadException(sigResp.statusCode == 429
          ? (sigJson['message']?.toString() ?? 'upload_failed_error'.tr)
          : 'upload_failed_error'.tr);
    }
    final s = Map<String, dynamic>.from(sigJson['data']);

    final maxBytes = (s['maxBytes'] as num?)?.toInt();
    if (maxBytes != null && file.lengthSync() > maxBytes) {
      throw UploadException('upload_too_large_error'.tr);
    }

    // ── 2. Cloudinary par seedha upload ─────────────────────────
    final form = dio.FormData.fromMap({
      'file': await dio.MultipartFile.fromFile(
        file.path,
        filename: file.path.split(RegExp(r'[/\\]')).last,
        contentType: _mimeFor(file.path),
      ),
      'api_key': s['api_key'].toString(),
      'timestamp': s['timestamp'].toString(),
      'signature': s['signature'].toString(),
      'folder': s['folder'].toString(),
      'public_id': s['public_id'].toString(),
    });
    final upResp = await _client.post(
      'https://api.cloudinary.com/v1_1/${s['cloud_name']}/${s['resource_type']}/upload',
      data: form,
      onSendProgress: onProgress == null
          ? null
          : (sent, total) {
              if (total > 0) onProgress(sent / total);
            },
    );
    final upJson = _json(upResp.data);
    final secureUrl = upJson['secure_url']?.toString();
    if (upResp.statusCode != 200 || secureUrl == null) {
      if (kDebugMode) print('[Upload] cloudinary ${upResp.statusCode}: ${upResp.data}');
      throw UploadException('upload_failed_error'.tr);
    }

    // ── 3. Backend confirm (ownership check) ────────────────────
    final confResp = await _client.post(
      '${AppConfig.baseUrl}/uploads/confirm',
      data: {'public_id': s['public_id'], 'secure_url': secureUrl},
      options: dio.Options(headers: auth, contentType: 'application/json'),
    );
    if (confResp.statusCode != 200) {
      if (kDebugMode) print('[Upload] confirm ${confResp.statusCode}: ${confResp.data}');
      throw UploadException('upload_failed_error'.tr);
    }
    return secureUrl;
  }

  /// Kai files ek ke baad ek (ek fail ho to sab ruk jaata hai).
  static Future<List<String>> uploadAll(List<File> files, String context) async {
    final urls = <String>[];
    for (final f in files) {
      urls.add(await upload(f, context));
    }
    return urls;
  }
}
