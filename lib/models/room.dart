class Room {
  final String id;
  final String departmentId;
  final String name;
  final String type;
  final int productCount;
  final int inStock;
  final int inMaintenance;
  final int criticalIssue;
  final int retired;
  final String? roomCode;
  final String? bloc;
  final String? floor;
  final int? capacity;

  const Room({
    required this.id,
    required this.departmentId,
    required this.name,
    required this.type,
    this.productCount = 0,
    this.inStock = 0,
    this.inMaintenance = 0,
    this.criticalIssue = 0,
    this.retired = 0,
    this.roomCode,
    this.bloc,
    this.floor,
    this.capacity,
  });

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id:            json['id'] as String,
        departmentId:  json['department_id'] as String,
        name:          json['name'] as String,
        type:          json['type'] as String? ?? 'classroom',
        productCount:  _int(json['product_count']),
        inStock:       _int(json['in_stock']),
        inMaintenance: _int(json['in_maintenance']),
        criticalIssue: _int(json['critical_issue']),
        retired:       _int(json['retired']),
        roomCode:      json['room_code'] as String?,
        bloc:          json['bloc'] as String?,
        floor:         json['floor'] as String?,
        capacity:      json['capacity'] != null ? _int(json['capacity']) : null,
      );

  Room copyWith({
    String? name,
    String? type,
    String? roomCode,
    String? bloc,
    String? floor,
    int? capacity,
    bool clearRoomCode = false,
    bool clearBloc = false,
    bool clearFloor = false,
    bool clearCapacity = false,
  }) => Room(
        id:            id,
        departmentId:  departmentId,
        name:          name ?? this.name,
        type:          type ?? this.type,
        productCount:  productCount,
        inStock:       inStock,
        inMaintenance: inMaintenance,
        criticalIssue: criticalIssue,
        retired:       retired,
        roomCode:      clearRoomCode ? null : (roomCode ?? this.roomCode),
        bloc:          clearBloc    ? null : (bloc     ?? this.bloc),
        floor:         clearFloor   ? null : (floor    ?? this.floor),
        capacity:      clearCapacity? null : (capacity ?? this.capacity),
      );

  static int _int(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
}
