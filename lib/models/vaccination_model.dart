class VaccinationModel {
  final String id;
  final String animalId;
  final String ownerId;
  final String vaccineName;
  final DateTime vaccinationDate;
  final DateTime? nextDueDate;
  final String status;

  VaccinationModel({
    required this.id,
    required this.animalId,
    required this.ownerId,
    required this.vaccineName,
    required this.vaccinationDate,
    this.nextDueDate,
    required this.status,
  });

  factory VaccinationModel.fromMap(Map<String, dynamic> map) {
    return VaccinationModel(
      id: map['id'] ?? '',
      animalId: map['animal_id'] ?? '',
      ownerId: map['owner_id'] ?? '',
      vaccineName: map['vaccine_name'] ?? '',
      vaccinationDate: DateTime.parse(map['vaccination_date']),
      nextDueDate: map['next_due_date'] != null
          ? DateTime.parse(map['next_due_date'])
          : null,
      status: map['status'] ?? 'Completed',
    );
  }
}
