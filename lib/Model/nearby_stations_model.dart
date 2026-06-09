class StationModel {

  final int? stationId;
  final String name;
  final String distance;
  final String power;
  final int available;
  final double latitude;
  final double longitude;

  bool isFavorited;

  StationModel({
    this.stationId,
    required this.name,
    required this.distance,
    required this.power,
    required this.available,
    required this.latitude,
    required this.longitude,
    this.isFavorited = false,
  });

  factory StationModel.fromJson(
      Map<String, dynamic> json,
      ) {

    return StationModel(

      stationId:
      json['stationId'] ??
          json['station_id'] ??
          json['id'],

      name:
      json['name'] ??
          '',

      distance:
      json['distance']?.toString() ??
          '',

      power:
      json['power']?.toString() ??
          '',

      available:
      json['available'] ??
          0,

      latitude:
      double.tryParse(
        json['latitude'].toString(),
      ) ??
          0.0,

      longitude:
      double.tryParse(
        json['longitude'].toString(),
      ) ??
          0.0,

      isFavorited:
      json['isFavorited'] ??
          json['is_favorited'] ??
          false,
    );
  }

  Map<String, dynamic> toJson() {

    return {

      'stationId': stationId,
      'name': name,
      'distance': distance,
      'power': power,
      'available': available,
      'latitude': latitude,
      'longitude': longitude,
      'isFavorited': isFavorited,
    };
  }
}

class NearbyStationsResponse {

  final List<StationModel> stations;
  final String status;

  NearbyStationsResponse({
    required this.stations,
    required this.status,
  });

  factory NearbyStationsResponse.fromJson(
      Map<String, dynamic> json,
      ) {

    final List<dynamic> stationsList =
        json['stations'] ?? [];

    return NearbyStationsResponse(

      stations:
      stationsList
          .map(
            (e) => StationModel.fromJson(e),
      )
          .toList(),

      status:
      json['status'] ??
          'success',
    );
  }
}