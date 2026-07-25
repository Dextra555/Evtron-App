

class FilterMasterResponse {
  final bool success;
  final FilterMasterData data;
  final String message;

  FilterMasterResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory FilterMasterResponse.fromJson(Map<String, dynamic> json) {
    return FilterMasterResponse(
      success: json['success'] ?? false,
      data: FilterMasterData.fromJson(json['data'] ?? {}),
      message: json['message'] ?? '',
    );
  }
}

class FilterMasterData {
  final List<FilterOption> chargerTypes;
  final List<FilterOption> connectorTypes;

  FilterMasterData({
    required this.chargerTypes,
    required this.connectorTypes,
  });

  factory FilterMasterData.fromJson(Map<String, dynamic> json) {
    return FilterMasterData(
      chargerTypes: (json['charger_types'] as List?)
          ?.map((item) => FilterOption.fromJson(item))
          .toList() ?? [],
      connectorTypes: (json['connector_types'] as List?)
          ?.map((item) => FilterOption.fromJson(item))
          .toList() ?? [],
    );
  }
}

class FilterOption {
  final int id;
  final String name;

  FilterOption({
    required this.id,
    required this.name,
  });

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

