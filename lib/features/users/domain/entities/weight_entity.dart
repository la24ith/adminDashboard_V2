// domain/entities/weight_entity.dart

class WeightEntity {
  final int id;
  final double weight;
  final DateTime recordedDate;
  final int recordedBy;
  final String? notes;
  final double? bmi;
  final DateTime? createdAt;

  const WeightEntity({
    required this.id,
    required this.weight,
    required this.recordedDate,
    required this.recordedBy,
    this.notes,
    this.bmi,
    this.createdAt,
  });

  factory WeightEntity.fromJson(Map<String, dynamic> json) {
    return WeightEntity(
      id: json['id'] ?? 0,
      weight: double.parse(json['weight']?.toString() ?? '0'),
      recordedDate: json['recorded_date'] != null
          ? DateTime.parse(json['recorded_date'])
          : DateTime.now(),
      recordedBy: json['recorded_by'] ?? 0,
      notes: json['notes'],
      bmi: json['bmi']?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weight': weight,
      'recorded_date': recordedDate.toIso8601String().split('T')[0],
      'recorded_by': recordedBy,
      'notes': notes,
      'bmi': bmi,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeightEntity &&
        other.id == id &&
        other.weight == weight &&
        other.recordedDate == recordedDate;
  }

  @override
  int get hashCode => Object.hash(id, weight, recordedDate);

  @override
  String toString() =>
      'WeightEntity(id: $id, weight: $weight, recordedDate: $recordedDate)';
}
