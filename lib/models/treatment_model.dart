class TreatmentModel {
  final String id;
  final String animalId;
  final String ownerId;
  final String treatmentName;
  final String? medicine;
  final String? dosage;
  final DateTime treatmentDate;
  final String status;

  TreatmentModel({
    required this.id,
    required this.animalId,
    required this.ownerId,
    required this.treatmentName,
    this.medicine,
    this.dosage,
    required this.treatmentDate,
    required this.status,
  });

  factory TreatmentModel.fromMap(Map<String, dynamic> map) {
    return TreatmentModel(
      id: map['id'] ?? '',
      animalId: map['animal_id'] ?? '',
      ownerId: map['owner_id'] ?? '',
      treatmentName: map['treatment_name'] ?? '',
      medicine: map['medicine'],
      dosage: map['dosage'],
      treatmentDate: DateTime.parse(map['treatment_date']),
      status: map['status'] ?? 'Completed',
    );
  }
}
