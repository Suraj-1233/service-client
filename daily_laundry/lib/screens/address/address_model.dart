class Address {
  final String? id;
  final String fullName;
  final String mobileNumber;
  final String flatBuilding;
  final String areaStreet;
  final String city;
  final String pincode;
  final String label; // e.g., Home / Work
  final double? latitude;
  final double? longitude;

  Address({
    this.id,
    required this.fullName,
    required this.mobileNumber,
    required this.flatBuilding,
    required this.areaStreet,
    required this.city,
    required this.pincode,
    required this.label,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? json['_id'], // ✅ handle both cases
      fullName: json['fullName'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      flatBuilding: json['flatBuilding'] ?? '',
      areaStreet: json['areaStreet'] ?? '',
      city: json['city'] ?? '',
      pincode: json['pincode'] ?? '',
      label: json['label'] ?? 'Home',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'mobileNumber': mobileNumber,
      'flatBuilding': flatBuilding,
      'areaStreet': areaStreet,
      'city': city,
      'pincode': pincode,
      'label': label,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Computed property for displaying full address
  String get address => "$flatBuilding, $areaStreet, $city - $pincode";
}
