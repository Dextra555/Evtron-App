

class WishlistResponse {
  final bool success;
  final int count;
  final List<WishlistItem> data;

  WishlistResponse({
    required this.success,
    required this.count,
    required this.data,
  });

  factory WishlistResponse.fromJson(Map<String, dynamic> json) {
    return WishlistResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      data: (json['data'] as List)
          .map((e) => WishlistItem.fromJson(e))
          .toList(),
    );
  }
}

class WishlistItem {

  final int wishlistId;
  final String notes;
  final bool isFavorite;
  final String addedAt;
  final WishlistStation station;

  WishlistItem({
    required this.wishlistId,
    required this.notes,
    required this.isFavorite,
    required this.addedAt,
    required this.station,
  });

  factory WishlistItem.fromJson(
      Map<String, dynamic> json,
      ) {
    return WishlistItem(
      wishlistId: json['wishlist_id'] ?? 0,
      notes: json['notes'] ?? '',
      isFavorite: json['is_favorite'] ?? false,
      addedAt: json['added_at'] ?? '',
      station: WishlistStation.fromJson(
        json['station'],
      ),
    );
  }
}

class WishlistStation {
  final int id;
  final String stationName;
  final String fullAddress;
  final String latitude;
  final String longitude;
  final String status;
  final bool is24_7;
  final int totalChargers;
  final int availableChargers;
  final List connectorPorts;
  final List amenities;

  WishlistStation({
    required this.id,
    required this.stationName,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.is24_7,
    required this.totalChargers,
    required this.availableChargers,
    required this.connectorPorts,
    required this.amenities,
  });

  factory WishlistStation.fromJson(Map<String, dynamic> json) {
    return WishlistStation(
      id: json['id'] ?? 0,
      stationName: json['station_name'] ?? '',
      fullAddress: json['full_address'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      status: json['status'] ?? '',
      is24_7: json['is_24_7'] ?? false,
      totalChargers: json['total_chargers'] ?? 0,
      availableChargers: json['available_chargers'] ?? 0,
      connectorPorts: json['connector_ports'] ?? [],
      amenities: json['amenities'] ?? [],
    );
  }
}