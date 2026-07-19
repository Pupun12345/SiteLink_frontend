import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/auth_models.dart';

// ═══════════════════════════════════════════════════════════════════
//  SESSION SERVICE — token + logged-in user ka single source of truth
// ═══════════════════════════════════════════════════════════════════
// Pehle token/user/userType alag-alag controllers me ad-hoc GetStorage me
// likhe jaate the. Ab sab kuch yahin se. Storage keys backward-compatible
// hain (purane sessions valid rahenge).
class SessionService extends GetxService {
  final GetStorage _box = GetStorage();

  /// Convenience accessor: `SessionService.to`
  static SessionService get to => Get.find<SessionService>();

  // ── Storage keys (unchanged for backward compatibility) ─────────────
  static const _kToken = 'token';
  static const _kUser = 'user';
  static const _kUserType = 'userType';
  static const _kUserRole = 'userRole';
  static const _kUserId = 'userId';
  static const _kUserName = 'userName';

  // ── Write ───────────────────────────────────────────────────────────
  Future<void> saveSession({required String token, UserModel? user}) async {
    await _box.write(_kToken, token);
    if (user != null) await _writeUser(user);
  }

  Future<void> _writeUser(UserModel user) async {
    await _box.write(_kUser, user.toJson());
    await _box.write(_kUserType, user.userType ?? '');
    await _box.write(_kUserRole, user.role ?? '');
    await _box.write(_kUserId, user.id ?? '');
    await _box.write(_kUserName, user.name ?? '');
  }

  /// Registration complete hone par userType set karo ('worker'/'vendor').
  /// Isse relaunch/splash pe user seedha home jaata hai, dobara registration nahi.
  Future<void> setUserType(String type) => _box.write(_kUserType, type);

  /// Pura session clear (logout).
  Future<void> clear() => _box.erase();

  // ── Read ────────────────────────────────────────────────────────────
  String get token => _box.read<String>(_kToken) ?? '';
  bool get isLoggedIn => token.isNotEmpty;

  /// Hamesha lowercase ('worker' | 'vendor' | '').
  String get userType => (_box.read<String>(_kUserType) ?? '').toLowerCase();
  String get role => _box.read<String>(_kUserRole) ?? '';
  String get userId => _box.read<String>(_kUserId) ?? '';
  String get userName => _box.read<String>(_kUserName) ?? '';

  UserModel? get user {
    final raw = _box.read(_kUser);
    if (raw is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}
