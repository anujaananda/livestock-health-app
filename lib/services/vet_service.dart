import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vet_model.dart';

class VetService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// ✅ හැම vet කෙනෙක්වම `vet_profiles` table එකෙන් ගන්නවා
  Future<List<VetModel>> getAllVets() async {
    try {
      print('🔍 getAllVets() called');

      final data = await _supabase.from('vet_profiles').select();

      print('📊 Raw data from Supabase: $data');
      print('📊 Number of records: ${(data as List).length}');

      final vets = (data as List).map((item) {
        print(
          '👤 Vet: ${item['full_name']} | ${item['specialization']} | ${item['district']}',
        );
        return VetModel.fromMap(item as Map<String, dynamic>);
      }).toList();

      print('✅ Vets loaded: ${vets.length}');
      return vets;
    } catch (e) {
      print('❌ Get vets error: $e');
      return [];
    }
  }

  /// ✅ ID එකෙන් එක vet කෙනෙක්ව ගන්නවා
  Future<VetModel?> getVetById(String vetId) async {
    try {
      final data = await _supabase
          .from('vet_profiles')
          .select()
          .eq('id', vetId)
          .single();

      return VetModel.fromMap(data);
    } catch (e) {
      print('❌ Get vet error: $e');
      return null;
    }
  }

  /// ✅ District එකකින් vets filter කරන්න (Supabase level එකේ)
  Future<List<VetModel>> getVetsByDistrict(String district) async {
    try {
      final data = await _supabase
          .from('vet_profiles')
          .select()
          .eq('district', district);

      return (data as List)
          .map((item) => VetModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Get vets by district error: $e');
      return [];
    }
  }
}
