class VetModel {
  final String id;
  final String name;
  final String email;
  final String userType;
  final String specialization;
  final String location;
  final String phone;
  final int experience;
  final double consultationFee;

  VetModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    required this.specialization,
    required this.location,
    required this.phone,
    required this.experience,
    required this.consultationFee,
  });

  factory VetModel.fromMap(Map<String, dynamic> map) {
    return VetModel(
      id: map['id'] ?? '',
      name: map['full_name'] ?? 'Unknown Vet',
      email: map['email'] ?? '',
      userType: map['user_type'] ?? 'Veterinarian',
      specialization: map['specialization'] ?? 'General Veterinarian',
      location: map['location'] ?? 'Sri Lanka',
      phone: map['phone'] ?? '',
      experience: map['experience'] ?? 0,
      consultationFee: (map['consultation_fee'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': name,
      'email': email,
      'user_type': userType,
      'specialization': specialization,
      'location': location,
      'phone': phone,
      'experience': experience,
      'consultation_fee': consultationFee,
    };
  }
}
