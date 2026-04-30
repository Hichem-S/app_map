class Tracker {
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final DateTime? lastSeen;
  final int? confidence;

  Tracker({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.lastSeen,
    this.confidence,
  });

  factory Tracker.fromJson(Map<String, dynamic> json) {
    return Tracker(
      id: json['id'] ?? json['tracker_id'] ?? '',
      name: json['name'] ?? json['id'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'])
          : null,
      confidence: json['confidence'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'last_seen': lastSeen?.toIso8601String(),
      'confidence': confidence,
    };
  }
}
