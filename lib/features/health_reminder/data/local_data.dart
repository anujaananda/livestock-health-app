import '../models/models.dart';

class LocalData {
  static final LocalData _instance = LocalData._internal();
  factory LocalData() => _instance;
  LocalData._internal();

  DemoAnimal get currentAnimal => DemoAnimal(
    id: 'C002',
    name: 'Moo',
    species: 'Cattle',
    breed: 'Jersey',
    age: 3,
    gender: 'Female',
    status: 'Need attention',
  );

  List<HealthRecord> healthRecords = [];

  List<Treatment> treatments = [
    Treatment(
      id: 't1',
      animalId: 'C002',
      date: DateTime(2024, 7, 15),
      title: 'Antibiotic',
      description: 'Amoxicillin - 500mg (7 days)',
      status: 'Completed',
    ),
    Treatment(
      id: 't2',
      animalId: 'C002',
      date: DateTime(2024, 6, 20),
      title: 'Deworming',
      description: 'Albendazole - 10ml',
      status: 'Completed',
    ),
  ];

  List<Vaccination> vaccinations = [
    Vaccination(
      id: 'v1',
      animalId: 'C002',
      name: 'Foot and Mouth Disease (FMD)',
      date: DateTime(2024, 4, 15),
      nextDueDate: DateTime(2024, 10, 15),
      status: 'Completed',
    ),
    Vaccination(
      id: 'v2',
      animalId: 'C002',
      name: 'Brucellosis',
      date: DateTime(2024, 4, 15),
      nextDueDate: DateTime(2025, 4, 15),
      status: 'Completed',
    ),
  ];

  List<MedicalRecord> medicalRecords = [
    MedicalRecord(
      id: 'm1',
      animalId: 'C002',
      title: 'General Health Check',
      date: DateTime(2024, 8, 10),
    ),
    MedicalRecord(
      id: 'm2',
      animalId: 'C002',
      title: 'Blood Test Report',
      date: DateTime(2024, 5, 12),
    ),
  ];

  List<NotificationItem> notifications = [
    NotificationItem(
      id: 'n1',
      title: 'FMD Vaccine due soon',
      description: 'Make a schedule in 7 days',
      time: DateTime.now().subtract(const Duration(minutes: 30)),
      isToday: true,
      isRead: false,
    ),
    NotificationItem(
      id: 'n2',
      title: 'Treatment follow-up',
      description: 'Check swelling and temperature',
      time: DateTime.now().subtract(const Duration(hours: 4)),
      isToday: true,
      isRead: false,
    ),
    NotificationItem(
      id: 'n3',
      title: 'HS Vaccine overdue',
      description: 'Overdue by 2 weeks',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isToday: false,
      isRead: true,
    ),
  ];

  // CRUD for Health Records
  void addHealthRecord(HealthRecord record) {
    healthRecords.add(record);
    // Explicitly removed automatic Treatment creation as per instructions.
  }

  void updateHealthRecord(HealthRecord record) {
    int index = healthRecords.indexWhere((r) => r.id == record.id);
    if (index != -1) healthRecords[index] = record;
  }

  void deleteHealthRecord(String id) {
    healthRecords.removeWhere((r) => r.id == id);
  }

  // CRUD for Treatments
  void addTreatment(Treatment t) => treatments.insert(0, t);
  void updateTreatment(Treatment t) {
    int index = treatments.indexWhere((x) => x.id == t.id);
    if (index != -1) treatments[index] = t;
  }

  void deleteTreatment(String id) => treatments.removeWhere((x) => x.id == id);

  // CRUD for Vaccinations
  void addVaccination(Vaccination v) => vaccinations.insert(0, v);
  void updateVaccination(Vaccination v) {
    int index = vaccinations.indexWhere((x) => x.id == v.id);
    if (index != -1) vaccinations[index] = v;
  }

  void deleteVaccination(String id) =>
      vaccinations.removeWhere((x) => x.id == id);

  // CRUD for Medical Records
  void addMedicalRecord(MedicalRecord m) => medicalRecords.insert(0, m);
  void updateMedicalRecord(MedicalRecord m) {
    int index = medicalRecords.indexWhere((x) => x.id == m.id);
    if (index != -1) medicalRecords[index] = m;
  }

  void deleteMedicalRecord(String id) =>
      medicalRecords.removeWhere((x) => x.id == id);

  // CRUD for Notifications
  void markNotificationRead(String id) {
    int index = notifications.indexWhere((x) => x.id == id);
    if (index != -1) notifications[index].isRead = true;
  }

  void deleteNotification(String id) =>
      notifications.removeWhere((x) => x.id == id);
}
