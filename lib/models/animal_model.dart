// lib/models/animal_model.dart
class AnimalModel {
  final String id;
  final String ownerId;
  final String? animalIdTag;
  final String name;
  final String species;
  final String? breed;
  final int? age;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? imageUrl; // ✅ Correct

  AnimalModel({
    required this.id,
    required this.ownerId,
    this.animalIdTag,
    required this.name,
    required this.species,
    this.breed,
    this.age,
    this.gender,
    this.dateOfBirth,
    this.imageUrl,
  });

  factory AnimalModel.fromMap(Map<String, dynamic> map) {
    return AnimalModel(
      id: map['id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      animalIdTag: map['animal_id_tag']?.toString(),
      name: map['name']?.toString() ?? 'Unknown',
      species: map['species']?.toString() ?? 'Animal',
      breed: map['breed']?.toString(),
      age: map['age'] is int
          ? map['age'] as int
          : int.tryParse('${map['age'] ?? ''}'),
      gender: map['gender']?.toString(),
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.tryParse(map['date_of_birth'].toString())
          : null,
      imageUrl: map['image_url']?.toString(), // ✅ Correct
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'animal_id_tag': animalIdTag,
      'name': name,
      'species': species,
      'breed': breed,
      'age': age,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'image_url': imageUrl,
    };
  }

  String get displayName => '$name ($species)';

  String get description {
    final parts = <String>[species];
    if (age != null) parts.add('$age years');
    if (gender != null && gender!.isNotEmpty) parts.add(gender!);
    return parts.join(' • ');
  }
}
