import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vaccination_model.dart';

class VaccinationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<VaccinationModel>> getVaccinations(String animalId) async {
    try {
      final data = await _supabase
          .from('vaccinations')
          .select()
          .eq('animal_id', animalId)
          .order('vaccination_date', ascending: false);

      return (data as List)
          .map((item) => VaccinationModel.fromMap(item))
          .toList();
    } catch (e) {
      print('Get vaccinations error: $e');
      return [];
    }
  }
}

