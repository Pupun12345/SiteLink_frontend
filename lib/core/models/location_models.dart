// ═══════════════════════════════════════════════════════════════════
//  LOCATION MODELS — States and Cities
// ═══════════════════════════════════════════════════════════════════

class StateModel {
  final int? id;
  final String? name;

  StateModel({this.id, this.name});

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: json["id"],
      name: json["name"],
    );
  }

  Map<String, dynamic> toJson() => {"id": id, "name": name};

  @override
  String toString() => name ?? "";
}

class GetStatesResponse {
  final bool success;
  final String? message;
  final List<StateModel> data;

  GetStatesResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory GetStatesResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json["data"] as List?;
    return GetStatesResponse(
      success: json["success"] ?? false,
      message: json["message"],
      data: dataList?.map((e) => StateModel.fromJson(e)).toList() ?? [],
    );
  }
}

// ── City Model ────────────────────────────────────────────────────
class CityModel {
  final int? id;
  final String? name;

  CityModel({this.id, this.name});

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json["id"],
      name: json["name"],
    );
  }

  Map<String, dynamic> toJson() => {"id": id, "name": name};

  @override
  String toString() => name ?? "";
}

class GetCitiesResponse {
  final bool success;
  final String? message;
  final String? state;
  final List<CityModel> data;

  GetCitiesResponse({
    required this.success,
    this.message,
    this.state,
    required this.data,
  });

  factory GetCitiesResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json["data"] as List?;
    return GetCitiesResponse(
      success: json["success"] ?? false,
      message: json["message"],
      state: json["state"],
      data: dataList?.map((e) => CityModel.fromJson(e)).toList() ?? [],
    );
  }
}
