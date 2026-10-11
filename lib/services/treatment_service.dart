import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/treatment_model.dart';

class TreatmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<TreatmentModel>> getTreatments(String animalId) async {
    try {
      final data = await _supabase
          .from('treatments')
          .select()
          .eq('animal_id', animalId)
          .order('treatment_date', ascending: false);

      return (data as List)
          .map((item) => TreatmentModel.fromMap(item))
          .toList();
    } catch (e) {
      print('Get treatments error: $e');
      return [];
    }
  }
}
