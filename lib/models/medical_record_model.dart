// lib/models/medical_record_model.dart
class MedicalRecordModel {
  final String id;
  final String animalId;
  final String ownerId;
  final String recordType;
  final String recordName;
  final DateTime recordDate;
  final String? fileUrl;
  final String? notes;

  MedicalRecordModel({
    required this.id,
    required this.animalId,
    required this.ownerId,
    required this.recordType,
    required this.recordName,
    required this.recordDate,
    this.fileUrl,
    this.notes,
  });

  factory MedicalRecordModel.fromMap(Map<String, dynamic> map) {
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

    return MedicalRecordModel(
      id: map['id']?.toString() ?? '',
      animalId: map['animal_id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      recordType: map['record_type']?.toString() ?? 'General',
      recordName: map['record_name']?.toString() ?? 'Untitled',
      recordDate: parsedDate,
      fileUrl: map['file_url']?.toString(),
      notes: map['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animal_id': animalId,
      'owner_id': ownerId,
      'record_type': recordType,
      'record_name': recordName,
      'record_date': recordDate.toIso8601String().split('T')[0],
      'file_url': fileUrl,
      'notes': notes,
    };
  }
}
