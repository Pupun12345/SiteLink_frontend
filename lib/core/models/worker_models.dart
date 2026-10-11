// ═══════════════════════════════════════════════════════════════════
//  WORKER PROFILE MODELS
// ═══════════════════════════════════════════════════════════════════

import 'auth_models.dart';

class WorkerProfileRequest {
  final String? name;
  final String? dateOfBirth;
  final String? gender;
  final int? primarySkillId;
  final List<int>? secondarySkillId;
  final int? totalExperience;
  final String? experienceDescription;
  final bool? willingtoRelocate;
  final String? salaryType;
  final String? salary;
  final String? otherSkill;
  final int? workStateId;  // backend: workStateID
  final int? workCityId;   // backend: workCityID
  final String? cityName;  // backend: city (display name)
  /// Family Protection claim isi vyakti ko milta hai.
  final String? nomineeName;

  WorkerProfileRequest({
    this.name,
    this.dateOfBirth,
    this.gender,
    this.primarySkillId,
    this.secondarySkillId,
    this.totalExperience,
    this.experienceDescription,
    this.willingtoRelocate,
    this.salaryType,
    this.salary,
    this.otherSkill,
    this.workStateId,
    this.workCityId,
    this.cityName,
    this.nomineeName,
  });

  Map<String, dynamic> toJson() => {
        if (name != null) "name": name,
        if (dateOfBirth != null) "dateOfBirth": dateOfBirth,
        if (gender != null) "gender": gender,
        if (primarySkillId != null) "primarySkillId": primarySkillId,
        if (secondarySkillId != null) "secondarySkillId": secondarySkillId,
        if (totalExperience != null) "totalExperience": totalExperience,
        if (experienceDescription != null)
          "experienceDescription": experienceDescription,
        if (willingtoRelocate != null) "willingtoRelocate": willingtoRelocate,
        if (salaryType != null) "salaryType": salaryType,
        if (salary != null) "salary": salary,
        if (otherSkill != null) "otherSkill": otherSkill,
        if (workStateId != null) "workStateID": workStateId,
        if (workCityId != null) "workCityID": workCityId,
        if (cityName != null) "city": cityName,
        if (nomineeName != null) "nomineeName": nomineeName,
      };
}

class CreateWorkerResponse {
  final bool success;
  final String? message;
  final UserModel? user;

  CreateWorkerResponse({
    required this.success,
    this.message,
    this.user,
  });

  factory CreateWorkerResponse.fromJson(Map<String, dynamic> json) {
    return CreateWorkerResponse(
      success: json["success"] ?? false,
      message: json["message"],
      user: json["user"] != null ? UserModel.fromJson(json["user"]) : null,
    );
  }
}

// ── Government ID Upload Request ──────────────────────────────────
class GovernmentIdUploadRequest {
  final String? idType;
  final String? idNumber;

  GovernmentIdUploadRequest({
    this.idType,
    this.idNumber,
  });

  Map<String, dynamic> toJson() => {
        if (idType != null) "idType": idType,
        if (idNumber != null) "idNumber": idNumber,
      };
}

class DocumentUploadResponse {
  final bool success;
  final String? message;
  final String? documentUrl;

  DocumentUploadResponse({
    required this.success,
    this.message,
    this.documentUrl,
  });

  factory DocumentUploadResponse.fromJson(Map<String, dynamic> json) {
    return DocumentUploadResponse(
      success: json["success"] ?? false,
      message: json["message"],
      documentUrl: json["documentUrl"] ?? json["url"],
    );
  }
}
