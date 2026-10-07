class AppointmentModel {
  final String id;
  final String farmerId;
  final String vetId;
  final String animalName;
  final DateTime date;
  final String time;
  final String notes;
  final String status;
  final String type; // 'online' හෝ 'onsite'

  AppointmentModel({
    required this.id,
    required this.farmerId,
    required this.vetId,
    required this.animalName,
    required this.date,
    required this.time,
    required this.notes,
    required this.status,
    required this.type,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'] ?? '',
      farmerId: map['farmer_id'] ?? '',
      vetId: map['vet_id'] ?? '',
      animalName: map['animal_name'] ?? '',
      date: DateTime.parse(map['date']),
      time: map['time'] ?? '',
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'pending',
      type: map['type'] ?? 'online',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'vet_id': vetId,
      'animal_name': animalName,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      'notes': notes,
      'status': status,
      'type': type,
    };
  }
}
