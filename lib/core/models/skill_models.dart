// ═══════════════════════════════════════════════════════════════════
//  SKILL MODELS
// ═══════════════════════════════════════════════════════════════════

class SkillModel {
  final String? id;
  final int? skillId;
  final String? name;
  final String? description;
  final String? icon;
  final String? category;

  SkillModel({
    this.id,
    this.skillId,
    this.name,
    this.description,
    this.icon,
    this.category,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json["_id"] ?? json["id"],
      skillId: json["id"],
      name: json["name"],
      description: json["description"],
      icon: json["icon"],
      category: json["category"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "skillId": skillId,
        "name": name,
        "description": description,
        "icon": icon,
        "category": category,
      };

  @override
  String toString() => name ?? "";
}

class GetSkillsResponse {
  final bool success;
  final String? message;
  final List<SkillModel> data;

  GetSkillsResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory GetSkillsResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json["data"] as List?;
    return GetSkillsResponse(
      success: json["success"] ?? false,
      message: json["message"],
      data: dataList?.map((e) => SkillModel.fromJson(e)).toList() ?? [],
    );
  }
}
