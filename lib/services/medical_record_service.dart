// lib/services/medical_record_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/medical_record_model.dart';

class MedicalRecordService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  Future<List<MedicalRecordModel>> getMedicalRecords(String animalId) async {
    try {
      final data = await _supabase
          .from('medical_records')
          .select()
          .eq('animal_id', animalId)
          .order('record_date', ascending: false);

      return (data as List)
          .map((item) => MedicalRecordModel.fromMap(item))
          .toList();
    } catch (e) {
      print('❌ Get medical records error: $e');
      return [];
    }
  }

  Future<bool> saveMedicalRecord(MedicalRecordModel record) async {
    try {
      final data = record.toMap();
      if ((data['id'] as String).isEmpty) {
        data['id'] = _uuid.v4();
      }
      await _supabase.from('medical_records').insert(data);
      print('✅ Medical record saved');
      return true;
    } catch (e) {
      print('❌ Save medical record error: $e');
      return false;
    }
  }

  Future<bool> deleteMedicalRecord(String recordId) async {
    try {
      await _supabase.from('medical_records').delete().eq('id', recordId);
      return true;
    } catch (e) {
      print('❌ Delete medical record error: $e');
      return false;
    }
  }
}
