class DemoAnimal {
  // IMPORTANT: This is temporary demo-only data for standalone testing.
  // DO NOT use this as the permanent shared Animal Management model.
  // During final integration, this should be replaced with the shared Animal model.
  final String id;
  final String name;
  final String species;
  final String breed;
  final int age;
  final String gender;
  final String status;

  DemoAnimal({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.gender,
    required this.status,
  });
}

class Treatment {
  final String id;
  final String animalId;
  final DateTime date;
  final String title;
  final String description;
  final String status;

  Treatment({
    required this.id,
    required this.animalId,
    required this.date,
    required this.title,
    required this.description,
    required this.status,
  });
}

class Vaccination {
  final String id;
  final String animalId;
  final String name;
  final DateTime date;
  final DateTime nextDueDate;
  final String status;

  Vaccination({
    required this.id,
    required this.animalId,
    required this.name,
    required this.date,
    required this.nextDueDate,
    required this.status,
  });
}

class MedicalRecord {
  final String id;
  final String animalId;
  final String title;
  final DateTime date;

  MedicalRecord({
    required this.id,
    required this.animalId,
    required this.title,
    required this.date,
  });
}

class HealthRecord {
  final String id;
  final String animalId;
  final DateTime date;
  final String condition;
  final String medicine;
  final String treatment;
  final String notes;
  final String status;

  HealthRecord({
    required this.id,
    required this.animalId,
    required this.date,
    required this.condition,
    required this.medicine,
    required this.treatment,
    required this.notes,
    required this.status,
  });
}

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final DateTime time;
  final bool isToday;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.isToday,
    this.isRead = false,
  });
}
