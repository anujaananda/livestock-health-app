// lib/services/appointment_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/appointment_model.dart';

class AppointmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ================= CREATE APPOINTMENT =================
  Future<bool> createAppointment({
    required String farmerId,
    required String vetId,
    required String animalName,
    required DateTime date,
    required String time,
    required String notes,
    String type = 'online',
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

  // ================= ✅ READ (Farmer Appointments with vet details) =================
  Future<List<AppointmentModel>> getFarmerAppointments(String farmerId) async {
    try {
      print('🔍 Loading appointments for farmer: $farmerId');

      final data = await _supabase
          .from('appointments')
          .select()
          .eq('farmer_id', farmerId)
          .order('date', ascending: false);

      final appointments = (data as List)
          .map((item) => AppointmentModel.fromMap(item))
          .toList();

      print('📊 Found ${appointments.length} appointments');

      final List<AppointmentModel> result = [];

      for (final appt in appointments) {
        if (appt.vetId.isNotEmpty) {
          try {
            final vetData = await _supabase
                .from('vet_profiles')
                .select('full_name, specialization, profile_image_url')
                .eq('user_id', appt.vetId)
                .maybeSingle();

            if (vetData != null) {
              print('👨‍⚕️ Vet found: ${vetData['full_name']}');
              result.add(
                appt.copyWith(
                  vetName: vetData['full_name'],
                  vetImageUrl: vetData['profile_image_url'],
                  vetSpecialization: vetData['specialization'],
                ),
              );
              continue;
            }

            final profileData = await _supabase
                .from('profiles')
                .select('full_name, specialization, profile_image_url')
                .eq('id', appt.vetId)
                .maybeSingle();

            if (profileData != null) {
              print('👨‍⚕️ Vet (from profiles): ${profileData['full_name']}');
              result.add(
                appt.copyWith(
                  vetName: profileData['full_name'],
                  vetImageUrl: profileData['profile_image_url'],
                  vetSpecialization: profileData['specialization'],
                ),
              );
            } else {
              print('⚠️ No vet profile for vet_id: ${appt.vetId}');
              result.add(appt);
            }
          } catch (e) {
            print('❌ Error loading vet: $e');
            result.add(appt);
          }
        } else {
          result.add(appt);
        }
      }

      print('✅ Loaded ${result.length} appointments with vet details');
      return result;
    } catch (e) {
      print('❌ Get farmer appointments error: $e');
      return [];
    }
  }

  // ================= ✅ READ (Farmer Consultations with Vet Details) =================
  Future<List<AppointmentModel>> getFarmerConsultations(String farmerId) async {
    try {
      print('🔍 Loading consultations for farmer: $farmerId');

      final data = await _supabase
          .from('consultations')
          .select()
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      final consultations = (data as List)
          .map((item) => AppointmentModel.fromMap(item))
          .toList();

      print('📊 Found ${consultations.length} consultations');

      final List<AppointmentModel> result = [];

      for (final consult in consultations) {
        if (consult.vetId.isNotEmpty) {
          try {
            final vetData = await _supabase
                .from('vet_profiles')
                .select('full_name, specialization, profile_image_url')
                .eq('user_id', consult.vetId)
                .maybeSingle();

            if (vetData != null) {
              print('👨‍⚕️ Vet found: ${vetData['full_name']}');
              result.add(
                consult.copyWith(
                  vetName: vetData['full_name'],
                  vetImageUrl: vetData['profile_image_url'],
                  vetSpecialization: vetData['specialization'],
                ),
              );
            } else {
              print('⚠️ No vet profile for vet_id: ${consult.vetId}');
              result.add(consult);
            }
          } catch (e) {
            print('❌ Error loading vet: $e');
            result.add(consult);
          }
        } else {
          result.add(consult);
        }
      }

      print('✅ Loaded ${result.length} consultations with vet details');
      return result;
    } catch (e) {
      print('❌ Get farmer consultations error: $e');
      return [];
    }
  }

  // ================= READ (Vet Appointments) =================
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

  // ================= READ (Vet Consultations) =================
  Future<List<AppointmentModel>> getVetConsultations(String vetId) async {
    try {
      final data = await _supabase
          .from('consultations')
          .select()
          .eq('vet_id', vetId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => AppointmentModel.fromMap(item))
          .toList();
    } catch (e) {
      print('❌ Get vet consultations error: $e');
      return [];
    }
  }

  // ================= READ (All) =================
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
      final result = await _supabase
          .from('appointments')
          .update({'status': status})
          .eq('id', appointmentId)
          .select();

      if ((result as List).isEmpty) {
        await _supabase
            .from('consultations')
            .update({'status': status})
            .eq('id', appointmentId);
      }

      return true;
    } catch (e) {
      print('❌ Update appointment status error: $e');
      return false;
    }
  }

  // ================= ✅ UPDATE DATE + TIME =================
  Future<bool> updateAppointmentDateTime({
    required String appointmentId,
    required DateTime date,
    required String time,
  }) async {
    try {
      print('📝 Updating appointment date/time:');
      print('   id: $appointmentId');
      print('   date: ${date.toIso8601String().split('T')[0]}');
      print('   time: $time');

      // ✅ Try appointments table first
      final result = await _supabase
          .from('appointments')
          .update({'date': date.toIso8601String().split('T')[0], 'time': time})
          .eq('id', appointmentId)
          .select();

      // ✅ If no record, try consultations table
      if ((result as List).isEmpty) {
        print('⚠️ Not in appointments table, trying consultations...');
        await _supabase
            .from('consultations')
            .update({
              'date': date.toIso8601String().split('T')[0],
              'time': time,
            })
            .eq('id', appointmentId);
      }

      print('✅ Date/time updated successfully');
      return true;
    } catch (e) {
      print('❌ Update date/time error: $e');
      return false;
    }
  }

  // ================= UPDATE TYPE =================
  Future<bool> updateAppointmentType({
    required String appointmentId,
    required String type,
  }) async {
    try {
      final result = await _supabase
          .from('appointments')
          .update({'type': type})
          .eq('id', appointmentId)
          .select();

      if ((result as List).isEmpty) {
        await _supabase
            .from('consultations')
            .update({'consultation_type': type})
            .eq('id', appointmentId);
      }

      return true;
    } catch (e) {
      print('❌ Update appointment type error: $e');
      return false;
    }
  }

  // ================= DELETE =================
  Future<bool> deleteAppointment(String appointmentId) async {
    try {
      final result = await _supabase
          .from('appointments')
          .delete()
          .eq('id', appointmentId)
          .select();

      if ((result as List).isEmpty) {
        await _supabase.from('consultations').delete().eq('id', appointmentId);
      }

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
          .maybeSingle();

      if (data != null) {
        return AppointmentModel.fromMap(data);
      }

      final consultData = await _supabase
          .from('consultations')
          .select()
          .eq('id', appointmentId)
          .maybeSingle();

      if (consultData != null) {
        return AppointmentModel.fromMap(consultData);
      }

      return null;
    } catch (e) {
      print('❌ Get appointment error: $e');
      return null;
    }
  }
}
