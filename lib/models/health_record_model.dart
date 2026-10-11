// lib/models/health_record_model.dart
class HealthRecordModel {
  final String id;
  final String animalId;
  final String ownerId;
  final String overallStatus;
  final double? temperature;
  final int? heartRate;
  final int? respirationRate;
  final String? notes;
  final DateTime recordDate;

  HealthRecordModel({
    required this.id,
    required this.animalId,
    required this.ownerId,
    required this.overallStatus,
    this.temperature,
    this.heartRate,
    this.respirationRate,
    this.notes,
    required this.recordDate,
  });

  factory HealthRecordModel.fromMap(Map<String, dynamic> map) {
    // ✅ record_date null-safe
    DateTime parsedDate;
    if (map['record_date'] != null) {
      parsedDate =
          DateTime.tryParse(map['record_date'].toString()) ?? DateTime.now();
    } else if (map['created_at'] != null) {
      parsedDate =
          DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return HealthRecordModel(
      id: map['id']?.toString() ?? '',
      animalId: map['animal_id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      overallStatus: map['overall_status']?.toString() ?? 'Healthy',
      temperature: (map['temperature'] as num?)?.toDouble(),
      heartRate: map['heart_rate'] is int
          ? map['heart_rate'] as int
          : int.tryParse('${map['heart_rate'] ?? ''}'),
      respirationRate: map['respiration_rate'] is int
          ? map['respiration_rate'] as int
          : int.tryParse('${map['respiration_rate'] ?? ''}'),
      notes: map['notes']?.toString(),
      recordDate: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animal_id': animalId,
      'owner_id': ownerId,
      'overall_status': overallStatus,
      'temperature': temperature,
      'heart_rate': heartRate,
      'respiration_rate': respirationRate,
      'notes': notes,
      'record_date': recordDate.toIso8601String().split('T')[0],
    };
  }

  // ✅ Helper getters
  bool get isHealthy => overallStatus.toLowerCase() == 'healthy';
  bool get needsAttention => overallStatus.toLowerCase() == 'need attention';
  bool get underTreatment => overallStatus.toLowerCase() == 'under treatment';

  HealthRecordModel copyWith({
    String? overallStatus,
    double? temperature,
    int? heartRate,
    int? respirationRate,
    String? notes,
    DateTime? recordDate,
  }) {
    return HealthRecordModel(
      id: id,
      animalId: animalId,
      ownerId: ownerId,
      overallStatus: overallStatus ?? this.overallStatus,
      temperature: temperature ?? this.temperature,
      heartRate: heartRate ?? this.heartRate,
      respirationRate: respirationRate ?? this.respirationRate,
      notes: notes ?? this.notes,
      recordDate: recordDate ?? this.recordDate,
    );
  }
}
