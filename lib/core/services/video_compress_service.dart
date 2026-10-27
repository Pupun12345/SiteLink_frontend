import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

// ═══════════════════════════════════════════════════════════════════
//  VIDEO COMPRESS SERVICE
// ═══════════════════════════════════════════════════════════════════
// Community feed video upload ke liye: size-validate → compress →
// (final) size-validate. Compressed temp files `cleanup()` se delete.
// Backend ko compressed file ek normal upload jaisa hi milta hai.

class VideoCompressResult {
  final bool success;
  final String? path;   // upload isi path ko karo (compressed ya original)
  final int? sizeBytes; // final file size
  final String? error;  // user ko dikhane wala message (fail par)

  const VideoCompressResult({
    required this.success,
    this.path,
    this.sizeBytes,
    this.error,
  });
}

class VideoCompressService {
  /// Max allowed size (configurable). Compression ke baad bhi isse bada
  /// hua to upload block ho jaata hai.
  static const int maxSizeMB = 50;
  static const int _maxBytes = maxSizeMB * 1024 * 1024;

  /// Max video duration (seconds). Isse badi video allow nahi.
  static const int maxDurationSec = 30; // 30 seconds

  Subscription? _progressSub;

  Future<int> _fileSize(String path) async {
    try {
      return await File(path).length();
    } catch (_) {
      return 0;
    }
  }

  /// Video ko compress karo aur size validate karo.
  /// [onProgress] 0.0–1.0 progress deta hai (UI ke liye).
  Future<VideoCompressResult> compress(
    String path, {
    void Function(double progress)? onProgress,
  }) async {
    // 1. File exist check (temp file creation / missing file failure)
    if (!await File(path).exists()) {
      return const VideoCompressResult(
          success: false, error: 'Video file nahi mila. Dobara select karein.');
    }

    final originalSize = await _fileSize(path);

    // 2. Progress subscribe
    onProgress?.call(0);
    _progressSub = VideoCompress.compressProgress$.subscribe((p) {
      onProgress?.call((p / 100).clamp(0.0, 1.0));
    });

    // 3. Compress (unsupported format / native failure yahan catch hota hai)
    MediaInfo? info;
    try {
      info = await VideoCompress.compressVideo(
        path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
    } catch (e) {
      if (kDebugMode) print('[VideoCompress] error: $e');
      _unsubscribe();
      return const VideoCompressResult(
          success: false,
          error: 'Video compress nahi ho paaya. Dobara try karein.');
    }
    _unsubscribe();
    onProgress?.call(1);

    final outPath = info?.path ?? info?.file?.path;
    if (outPath == null) {
      return const VideoCompressResult(
          success: false, error: 'Video compress nahi ho paaya.');
    }

    // 4. Compressed size. Agar compression ne size badha diya (pehle se
    //    optimized chhoti video), to original hi use karo.
    final compressedSize = info?.filesize ?? await _fileSize(outPath);
    String finalPath = outPath;
    int finalSize = compressedSize;
    if (originalSize > 0 && compressedSize >= originalSize) {
      finalPath = path;
      finalSize = originalSize;
    }

    // 5. Final size limit validate — abhi bhi bada to block.
    if (finalSize > _maxBytes) {
      await cleanup();
      return const VideoCompressResult(
        success: false,
        error:
            'Video size is too large. Please select a shorter or smaller video.',
      );
    }

    return VideoCompressResult(
        success: true, path: finalPath, sizeBytes: finalSize);
  }

  void _unsubscribe() {
    _progressSub?.unsubscribe();
    _progressSub = null;
  }

  /// Compressed temp/cache files delete (upload ke baad call karo).
  Future<void> cleanup() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (_) {}
  }

  /// Chal rahi compression cancel karo.
  void cancel() {
    try {
      VideoCompress.cancelCompression();
    } catch (_) {}
    _unsubscribe();
  }
}
