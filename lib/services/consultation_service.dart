// lib/services/consultation_service.dart
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/appointment_model.dart';

class ConsultationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ================= CREATE CONSULTATION (with photos) =================
  Future<bool> createConsultation({
    required String farmerId,
    required String symptoms,
    required String urgency,
    String? vetId,
    String consultationType = 'online',
    String? animalName,
    String? animalId,
    List<File>? photos, // ✅ NEW
  }) async {
    try {
      print('📝 Creating consultation...');
      print('   farmerId: $farmerId');
      print('   vetId: $vetId');
      print('   animalName: $animalName');
      print('   consultationType: $consultationType');
      print('   photos: ${photos?.length ?? 0}');

      final consultationId = const Uuid().v4();

      // ✅ 1. Upload photos to Supabase Storage
      List<String> photoUrls = [];
      if (photos != null && photos.isNotEmpty) {
        print('📤 Uploading ${photos.length} photos...');

        for (int i = 0; i < photos.length; i++) {
          try {
            final file = photos[i];
            final ext = file.path.split('.').last;
            final fileName = 'consultations/$consultationId/photo_$i.$ext';

            await _supabase.storage
                .from('avatars')
                .upload(
                  fileName,
                  file,
                  fileOptions: const FileOptions(upsert: true),
                );

            final url = _supabase.storage
                .from('avatars')
                .getPublicUrl(fileName);

            photoUrls.add(url);
            print('   ✅ Photo $i uploaded: $url');
          } catch (e) {
            print('   ❌ Photo $i upload failed: $e');
          }
        }
      }

      // ✅ 2. Insert consultation with photos
      final Map<String, dynamic> data = {
        'id': consultationId,
        'farmer_id': farmerId,
        'symptoms': symptoms,
        'urgency': urgency,
        'consultation_type': consultationType,
        'animal_name': animalName,
        'animal_id': animalId,
        'status': 'pending',
        'photos': photoUrls, // ✅ Save photo URLs
      };

      if (vetId != null && vetId.isNotEmpty && vetId != 'null') {
        data['vet_id'] = vetId;
        print('   ✅ vet_id added: $vetId');
      } else {
        print('   ⚠️ vet_id skipped (empty/null)');
      }

      await _supabase.from('consultations').insert(data);

      print('✅ Consultation created with ${photoUrls.length} photos');
      return true;
    } catch (e) {
      print('❌ Create consultation error: $e');
      return false;
    }
  }

  // ================= GET FARMER CONSULTATIONS =================
  Future<List<AppointmentModel>> getFarmerConsultations(String farmerId) async {
    try {
      final data = await _supabase
          .from('consultations')
          .select()
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((json) => AppointmentModel.fromMap(json))
          .toList();
    } catch (e) {
      print('❌ Get farmer consultations error: $e');
      return [];
    }
  }

  // ================= GET VET CONSULTATIONS =================
  Future<List<AppointmentModel>> getVetConsultations(String vetId) async {
    try {
      final data = await _supabase
          .from('consultations')
          .select()
          .eq('vet_id', vetId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((json) => AppointmentModel.fromMap(json))
          .toList();
    } catch (e) {
      print('❌ Get vet consultations error: $e');
      return [];
    }
  }

  // ================= GET BY ID =================
  Future<Map<String, dynamic>?> getConsultationById(
    String consultationId,
  ) async {
    try {
      final data = await _supabase
          .from('consultations')
          .select()
          .eq('id', consultationId)
          .maybeSingle();
      return data;
    } catch (e) {
      print('❌ Get consultation error: $e');
      return null;
    }
  }

  // ================= UPDATE STATUS =================
  Future<bool> updateConsultationStatus({
    required String consultationId,
    required String status,
  }) async {
    try {
      await _supabase
          .from('consultations')
          .update({'status': status})
          .eq('id', consultationId);
      return true;
    } catch (e) {
      print('❌ Update consultation status error: $e');
      return false;
    }
  }

  // ================= DELETE =================
  Future<bool> deleteConsultation(String consultationId) async {
    try {
      await _supabase.from('consultations').delete().eq('id', consultationId);
      return true;
    } catch (e) {
      print('❌ Delete consultation error: $e');
      return false;
    }
  }
}
