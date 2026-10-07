import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vet_model.dart';

class VetService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<VetModel>> getAllVets() async {
    try {
      print('🔍 getAllVets() called');

      final data = await _supabase
          .from('profiles')
          .select()
          .ilike('user_type', '%veterinarian%');

      print('📊 Raw data from Supabase: $data');
      print('📊 Number of records: ${(data as List).length}');

      final vets = (data as List).map((item) {
        print('👤 Vet: ${item['full_name']} | ${item['specialization']}');
        return VetModel.fromMap(item);
      }).toList();

      print('✅ Vets loaded: ${vets.length}');
      return vets;
    } catch (e) {
      print('❌ Get vets error: $e');
      return [];
    }
  }

  Future<VetModel?> getVetById(String vetId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', vetId)
          .single();

      return VetModel.fromMap(data);
    } catch (e) {
      print('❌ Get vet error: $e');
      return null;
    }
  }
}
