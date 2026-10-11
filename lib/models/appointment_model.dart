// lib/models/appointment_model.dart
class AppointmentModel {
  final String id;
  final String farmerId;
  final String vetId;
  final String animalName;
  final DateTime date;
  final String time;
  final String notes;
  final String status;
  final String type;

  // ✅ Vet details from Supabase
  final String? vetName;
  final String? vetImageUrl;
  final String? vetSpecialization;

  // ✅ Photos (from consultation request)
  final List<String> photoUrls;

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
    this.vetName,
    this.vetImageUrl,
    this.vetSpecialization,
    this.photoUrls = const [],
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    // ✅ Type detection — multiple fallbacks
    final rawType =
        map['type']?.toString() ??
        map['consultation_type']?.toString() ??
        map['visit_type']?.toString() ??
        'online';

    final typeValue = rawType.toLowerCase().trim();

    // ✅ Date parsing
    DateTime parsedDate;
    if (map['date'] != null) {
      parsedDate = DateTime.tryParse(map['date'].toString()) ?? DateTime.now();
    } else if (map['created_at'] != null) {
      parsedDate =
          DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    // ✅ Vet details
    String? vetName;
    String? vetImageUrl;
    String? vetSpecialization;

    final vetData = map['vet_profiles'];
    if (vetData != null && vetData is Map) {
      vetName = vetData['full_name']?.toString();
      vetImageUrl = vetData['profile_image_url']?.toString();
      vetSpecialization = vetData['specialization']?.toString();
    } else {
      vetName = map['vet_name']?.toString();
      vetImageUrl = map['vet_image_url']?.toString();
      vetSpecialization = map['vet_specialization']?.toString();
    }

    // ✅ Parse photos from JSONB array
    final List<String> photos = [];
    final photoData = map['photos'];

    if (photoData != null) {
      if (photoData is List) {
        for (var item in photoData) {
          if (item != null) {
            photos.add(item.toString());
          }
        }
      } else if (photoData is String) {
        if (photoData.isNotEmpty) {
          photos.add(photoData);
        }
      }
    }

    return AppointmentModel(
      id: map['id']?.toString() ?? '',
      farmerId: map['farmer_id']?.toString() ?? '',
      vetId: map['vet_id']?.toString() ?? '',
      animalName: map['animal_name']?.toString() ?? 'Animal',
      date: parsedDate,
      time: map['time']?.toString() ?? _formatTime(parsedDate),
      notes: map['notes']?.toString() ?? map['symptoms']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      type: typeValue,
      vetName: vetName,
      vetImageUrl: vetImageUrl,
      vetSpecialization: vetSpecialization,
      photoUrls: photos,
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
      'photos': photoUrls,
    };
  }

  AppointmentModel copyWith({
    String? vetName,
    String? vetImageUrl,
    String? vetSpecialization,
    List<String>? photoUrls,
  }) {
    return AppointmentModel(
      id: id,
      farmerId: farmerId,
      vetId: vetId,
      animalName: animalName,
      date: date,
      time: time,
      notes: notes,
      status: status,
      type: type,
      vetName: vetName ?? this.vetName,
      vetImageUrl: vetImageUrl ?? this.vetImageUrl,
      vetSpecialization: vetSpecialization ?? this.vetSpecialization,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }

  // ✅ Helper getters
  String get displayVetName =>
      (vetName != null && vetName!.isNotEmpty) ? vetName! : 'Waiting for Vet';

  String get displaySpecialization =>
      (vetSpecialization != null && vetSpecialization!.isNotEmpty)
      ? vetSpecialization!
      : 'Veterinarian';

  String get displayImage => (vetImageUrl != null && vetImageUrl!.isNotEmpty)
      ? vetImageUrl!
      : 'https://i.pravatar.cc/150?img=12';

  // ✅ Type helpers
  bool get isOnline => type.toLowerCase() == 'online';
  bool get isOnsite => type.toLowerCase() == 'onsite';
  String get displayType => isOnsite ? 'On-site' : 'Online';

  // ✅ Photos helpers
  bool get hasPhotos => photoUrls.isNotEmpty;
  int get photoCount => photoUrls.length;

  static String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
