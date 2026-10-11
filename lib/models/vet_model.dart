// lib/models/vet_model.dart
class VetModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String specialization;
  final String location;
  final String district;
  final String? imageUrl;
  final String? profileImageUrl;
  final String? bio;
  final double rating;
  final int experience;
  final int experienceYears;
  final bool isAvailable;
  final List<String> availableDays;
  final String? clinicName;
  final double? consultationFee;

  VetModel({
    required this.id,
    this.userId = '',
    required this.name,
    required this.email,
    required this.phone,
    required this.specialization,
    required this.location,
    required this.district,
    this.imageUrl,
    this.profileImageUrl,
    this.bio,
    this.rating = 0.0,
    this.experience = 0,
    this.experienceYears = 0,
    this.isAvailable = true,
    this.availableDays = const [],
    this.clinicName,
    this.consultationFee,
  });

  String get effectiveUserId => userId.isNotEmpty ? userId : id;

  // ============================================================
  // ✅ FROM MAP — මේකයි fix වුනේ
  // ============================================================
  factory VetModel.fromMap(Map<String, dynamic> map) {
    // ✅ 'full_name' first, then fallback
    final nameValue =
        map['full_name']?.toString() ??
        map['name']?.toString() ??
        map['vet_name']?.toString() ??
        'Unknown';

    final exp = map['experience'] is int
        ? map['experience'] as int
        : int.tryParse('${map['experience'] ?? 0}') ?? 0;

    final imgUrl =
        map['profile_image_url']?.toString() ?? map['image_url']?.toString();

    final feeValue = map['consultation_fee'];
    final fee = feeValue is num
        ? feeValue.toDouble()
        : double.tryParse('${feeValue ?? ''}');

    return VetModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? map['id']?.toString() ?? '',
      name: nameValue, // ✅ FIXED
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      specialization:
          map['specialization']?.toString() ?? 'General Veterinarian',
      location: map['location']?.toString() ?? '',
      district: map['district']?.toString() ?? '',
      imageUrl: imgUrl,
      profileImageUrl: imgUrl,
      bio: map['bio']?.toString(),
      rating: (map['rating'] is num)
          ? (map['rating'] as num).toDouble()
          : double.tryParse('${map['rating'] ?? 0}') ?? 0.0,
      experience: exp,
      experienceYears: exp,
      isAvailable: map['is_available'] ?? true,
      availableDays: map['available_days'] != null
          ? List<String>.from(map['available_days'])
          : <String>[],
      clinicName: map['clinic_name']?.toString(),
      consultationFee: fee,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': name, // ✅ DB column name
      'name': name, // backward compatibility
      'email': email,
      'phone': phone,
      'specialization': specialization,
      'location': location,
      'district': district,
      'clinic_name': clinicName,
      'profile_image_url': profileImageUrl,
      'experience': experience,
      'consultation_fee': consultationFee,
    };
  }
}
