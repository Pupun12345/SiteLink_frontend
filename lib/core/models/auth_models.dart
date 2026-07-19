// ═══════════════════════════════════════════════════════════════════
//  AUTH MODELS — Register, OTP Verify, User
// ═══════════════════════════════════════════════════════════════════

// ── Register Request ──────────────────────────────────────────────
class RegisterRequest {
  final String phone;

  RegisterRequest({required this.phone});

  Map<String, dynamic> toJson() => {"phone": phone};
}

// ── Register Response ──────────────────────────────────────────────
class RegisterResponse {
  final bool success;
  final String message;

  RegisterResponse({required this.success, required this.message});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
    );
  }
}

// ── OTP Verify Request ────────────────────────────────────────────
class VerifyOtpRequest {
  final String phone;
  final String otp;

  VerifyOtpRequest({required this.phone, required this.otp});

  Map<String, dynamic> toJson() => {
        "phone": phone,
        "otp": otp,
      };
}

// ── User Model ────────────────────────────────────────────────────
class UserModel {
  final String? id;
  final String? phone;
  final bool? isPhoneVerified;
  final String? userType;
  final String? role;
  final String? name;
  final String? email;
  final String? profileImage;
  final String? primarySkill;
  final List<dynamic>? additionalSkills;

  UserModel({
    this.id,
    this.phone,
    this.isPhoneVerified,
    this.userType,
    this.role,
    this.name,
    this.email,
    this.profileImage,
    this.primarySkill,
    this.additionalSkills,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Backend kabhi `_id`/`id` aur `phone`/`phoneNumber` dono variants bhejta
    // hai (OTP vs Google login) — dono handle karte hain.
    return UserModel(
      id: (json["_id"] ?? json["id"])?.toString(),
      phone: (json["phone"] ?? json["phoneNumber"])?.toString(),
      isPhoneVerified: json["isPhoneVerified"] as bool?,
      userType: json["userType"]?.toString(),
      role: json["role"]?.toString(),
      name: json["name"]?.toString(),
      email: json["email"]?.toString(),
      profileImage: json["profileImage"]?.toString(),
      primarySkill: json["primarySkill"]?.toString(),
      additionalSkills: json["additionalSkills"] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "phone": phone,
        "isPhoneVerified": isPhoneVerified,
        "userType": userType,
        "role": role,
        "name": name,
        "email": email,
        "profileImage": profileImage,
        "primarySkill": primarySkill,
        "additionalSkills": additionalSkills,
      };
}

// ── OTP Verify Response ───────────────────────────────────────────
class VerifyOtpResponse {
  final bool success;
  final String? message;
  final String? token;
  final bool? isExist;
  final UserModel? user;

  VerifyOtpResponse({
    required this.success,
    this.message,
    this.token,
    this.isExist,
    this.user,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      success: json["success"] ?? false,
      message: json["message"],
      token: json["token"],
      isExist: json["isExist"],
      user: json["user"] != null ? UserModel.fromJson(json["user"]) : null,
    );
  }
}

// ── Generic API Response ──────────────────────────────────────────
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResponse(
      success: json["success"] ?? false,
      message: json["message"],
      data: json["data"] != null ? fromJsonT(json["data"]) : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Google Login Response — backend se Google login ke baad ka response.
// `user` ab unified UserModel use karta hai (pehle alag UserData tha).
// ─────────────────────────────────────────────────────────────────
class GoogleLoginResponse {
  final bool    success;
  final String? message;
  final String? token;       // Backend JWT token
  final bool?   isNewUser;   // true = pehli baar login → role selection
  final UserModel? user;

  const GoogleLoginResponse({
    required this.success,
    this.message,
    this.token,
    this.isNewUser,
    this.user,
  });

  factory GoogleLoginResponse.fromJson(Map<String, dynamic> json) {
    // Response flat ya `data` ke andar nested — dono handle.
    final userJson = json['user'] ?? json['data']?['user'];
    return GoogleLoginResponse(
      success:   json['success'] as bool? ?? false,
      message:   json['message']?.toString(),
      token:     json['token']?.toString()
          ?? json['data']?['token']?.toString(),
      isNewUser: json['isNewUser'] as bool?
          ?? json['data']?['isNewUser'] as bool?,
      user: userJson is Map
          ? UserModel.fromJson(Map<String, dynamic>.from(userJson))
          : null,
    );
  }
}
