// lib/models/emergency_alert_model.dart
// ⚠️ Only EmergencyAlertModel class here. No other class.

class EmergencyAlertModel {
  final String id;
  final String? vetId;
  final String? farmerId;
  final String? animalId;
  final String farmerName;
  final String farmerPhone;
  final String animalName;
  final String farmName;
  final String condition;
  final String description;
  final String farmerDescription;
  final String urgency; // 'High', 'Critical', 'Medium'
  final String status; // 'active', 'in_progress', 'resolved'
  final String location;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String? visitType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  EmergencyAlertModel({
    required this.id,
    this.vetId,
    this.farmerId,
    this.animalId,
    required this.farmerName,
    required this.farmerPhone,
    required this.animalName,
    required this.farmName,
    required this.condition,
    required this.description,
    required this.farmerDescription,
    required this.urgency,
    required this.status,
    required this.location,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.visitType,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  factory EmergencyAlertModel.fromMap(Map<String, dynamic> map) {
    return EmergencyAlertModel(
      id: map['id']?.toString() ?? '',
      vetId: map['vet_id']?.toString(),
      farmerId: map['farmer_id']?.toString(),
      animalId: map['animal_id']?.toString(),
      farmerName: map['farmer_name']?.toString() ?? 'Unknown Farmer',
      farmerPhone: map['farmer_phone']?.toString() ?? '',
      animalName: map['animal_name']?.toString() ?? 'Unknown Animal',
      farmName: map['farm_name']?.toString() ?? '',
      condition: map['condition']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      farmerDescription: map['farmer_description']?.toString() ?? '',
      urgency: map['urgency']?.toString() ?? 'High',
      status: map['status']?.toString() ?? 'active',
      location: map['location']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      imageUrl: map['image_url']?.toString(),
      visitType: map['visit_type']?.toString(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
      resolvedAt: map['resolved_at'] != null
          ? DateTime.tryParse(map['resolved_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vet_id': vetId,
      'farmer_id': farmerId,
      'animal_id': animalId,
      'farmer_name': farmerName,
      'farmer_phone': farmerPhone,
      'animal_name': animalName,
      'farm_name': farmName,
      'condition': condition,
      'description': description,
      'farmer_description': farmerDescription,
      'urgency': urgency,
      'status': status,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'visit_type': visitType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  // ==================== Helper Getters ====================

  /// Urgency checks
  bool get isCritical => urgency.toLowerCase() == 'critical';
  bool get isHigh => urgency.toLowerCase() == 'high';

  /// Status checks
  bool get isActive => status.toLowerCase() == 'active';
  bool get isResolved => status.toLowerCase() == 'resolved';
  bool get isInProgress =>
      status.toLowerCase() == 'in_progress' ||
      status.toLowerCase() == 'inprogress';
}
