import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/appointment_model.dart';

class AppointmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ================= CREATE =================
  Future<bool> createAppointment({
    required String farmerId,
    required String vetId,
    required String animalName,
    required DateTime date,
    required String time,
    required String notes,
    String type = 'online', // 'online' හෝ 'onsite'
  }) async {
    try {
      await _supabase.from('appointments').insert({
        'id': const Uuid().v4(),
        'farmer_id': farmerId,
        'vet_id': vetId,
        'animal_name': animalName,
        'date': date.toIso8601String().split('T')[0],
        'time': time,
        'notes': notes,
        'status': 'pending',
        'type': type,
      });
      return true;
    } catch (e) {
      print('❌ Create appointment error: $e');
      return false;
    }
  }

  // ================= READ (Farmer) =================
  Future<List<AppointmentModel>> getFarmerAppointments(String farmerId) async {
    try {
      final data = await _supabase
          .from('appointments')
          .select()
          .eq('farmer_id', farmerId)
          .order('date', ascending: false);

      return (data as List)
          .map((item) => AppointmentModel.fromMap(item))
          .toList();
    } catch (e) {
      print('❌ Get farmer appointments error: $e');
      return [];
    }
  }

  // ================= READ (Vet) =================
  Future<List<AppointmentModel>> getVetAppointments(String vetId) async {
    try {
      final data = await _supabase
          .from('appointments')
          .select()
          .eq('vet_id', vetId)
          .order('date', ascending: false);

      return (data as List)
          .map((item) => AppointmentModel.fromMap(item))
          .toList();
    } catch (e) {
      print('❌ Get vet appointments error: $e');
      return [];
    }
  }

  // ================= READ (All - Vet Dashboard) =================
  Future<List<AppointmentModel>> getAllAppointments() async {
    try {
      final data = await _supabase
          .from('appointments')
          .select()
          .order('date', ascending: false);

      return (data as List)
          .map((item) => AppointmentModel.fromMap(item))
          .toList();
    } catch (e) {
      print('❌ Get all appointments error: $e');
      return [];
    }
  }

  // ================= UPDATE STATUS =================
  Future<bool> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': status})
          .eq('id', appointmentId);
      return true;
    } catch (e) {
      print('❌ Update appointment status error: $e');
      return false;
    }
  }

  // ================= UPDATE TYPE =================
  Future<bool> updateAppointmentType({
    required String appointmentId,
    required String type,
  }) async {
    try {
      await _supabase
          .from('appointments')
          .update({'type': type})
          .eq('id', appointmentId);
      return true;
    } catch (e) {
      print('❌ Update appointment type error: $e');
      return false;
    }
  }

  // ================= DELETE =================
  Future<bool> deleteAppointment(String appointmentId) async {
    try {
      await _supabase.from('appointments').delete().eq('id', appointmentId);
      return true;
    } catch (e) {
      print('❌ Delete appointment error: $e');
      return false;
    }
  }

  // ================= GET BY ID =================
  Future<AppointmentModel?> getAppointmentById(String appointmentId) async {
    try {
      final data = await _supabase
          .from('appointments')
          .select()
          .eq('id', appointmentId)
          .single();

      return AppointmentModel.fromMap(data);
    } catch (e) {
      print('❌ Get appointment error: $e');
      return null;
    }
  }
}
