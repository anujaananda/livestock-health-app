import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ConsultationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> createConsultation({
    required String farmerId,
    required String symptoms,
    required String urgency,
  }) async {
    try {
      await _supabase.from('consultations').insert({
        'id': const Uuid().v4(),
        'farmer_id': farmerId,
        'symptoms': symptoms,
        'urgency': urgency,
        'status': 'pending',
      });
      return true;
    } catch (e) {
      print('Create consultation error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getFarmerConsultations(
      String farmerId) async {
    try {
      final data = await _supabase
          .from('consultations')
          .select()
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Get consultations error: $e');
      return [];
    }
  }
}