import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/animal_model.dart';

class AnimalService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<AnimalModel>> getFarmerAnimals(String farmerId) async {
    try {
      print('🔍 Loading animals for farmer: $farmerId');

      final data = await _supabase
          .from('animals')
          .select()
          .eq('owner_id', farmerId)
          .order('name', ascending: true);

      print('📊 Found ${(data as List).length} animals');

      return (data as List).map((json) => AnimalModel.fromMap(json)).toList();
    } catch (e) {
      print('❌ Error loading animals: $e');
      return [];
    }
  }

  /// ✅ Single animal by ID
  Future<AnimalModel?> getAnimalById(String animalId) async {
    try {
      final data = await _supabase
          .from('animals')
          .select()
          .eq('id', animalId)
          .maybeSingle();

      if (data == null) return null;
      return AnimalModel.fromMap(data);
    } catch (e) {
      print('❌ Error loading animal: $e');
      return null;
    }
  }
}
