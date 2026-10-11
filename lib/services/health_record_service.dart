// lib/services/health_record_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/health_record_model.dart';

class HealthRecordService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // ================= GET LATEST RECORD =================
  Future<HealthRecordModel?> getHealthRecord(String animalId) async {
    try {
      final data = await _supabase
          .from('health_records')
          .select()
          .eq('animal_id', animalId)
          .order('record_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      return HealthRecordModel.fromMap(data);
    } catch (e) {
      print('❌ Get health record error: $e');
      return null;
    }
  }

  // ================= GET ALL RECORDS =================
  Future<List<HealthRecordModel>> getAllRecords(String animalId) async {
    try {
      final data = await _supabase
          .from('health_records')
          .select()
          .eq('animal_id', animalId)
          .order('record_date', ascending: false);

      return (data as List)
          .map((json) => HealthRecordModel.fromMap(json))
          .toList();
    } catch (e) {
      print('❌ Get all records error: $e');
      return [];
    }
  }

  // ================= SAVE (ADD) =================
  Future<bool> saveHealthRecord(HealthRecordModel record) async {
    try {
      final data = record.toMap();
      // ✅ ID generate if empty
      if ((data['id'] as String).isEmpty) {
        data['id'] = _uuid.v4();
      }

      await _supabase.from('health_records').insert(data);
      print('✅ Health record saved');
      return true;
    } catch (e) {
      print('❌ Save health record error: $e');
      return false;
    }
  }

  // ================= UPDATE =================
  Future<bool> updateHealthRecord(HealthRecordModel record) async {
    try {
      await _supabase
          .from('health_records')
          .update(record.toMap())
          .eq('id', record.id);

      print('✅ Health record updated');
      return true;
    } catch (e) {
      print('❌ Update health record error: $e');
      return false;
    }
  }

  // ================= DELETE =================
  Future<bool> deleteHealthRecord(String recordId) async {
    try {
      await _supabase.from('health_records').delete().eq('id', recordId);
      print('✅ Health record deleted');
      return true;
    } catch (e) {
      print('❌ Delete health record error: $e');
      return false;
    }
  }
}
