// lib/services/emergency_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/emergency_alert_model.dart';

class EmergencyService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // ============================================================
  // ✅ GET ACTIVE ALERTS FOR A VET
  // ============================================================
  Future<List<EmergencyAlertModel>> getActiveAlerts(String vetId) async {
    try {
      print('🔍 EmergencyService: Loading alerts for vet: $vetId');

      if (vetId.isEmpty) {
        print('⚠️ vetId is empty!');
        return [];
      }

      final data = await _supabase
          .from('vet_emergency_alerts')
          .select()
          .eq('vet_id', vetId)
          .neq('status', 'resolved')
          .order('created_at', ascending: false);

      print(
        '📊 EmergencyService: Found ${(data as List).length} active alerts',
      );

      return (data as List).map((json) {
        print('   🚨 Alert: ${json['animal_name']} | ${json['status']}');
        return EmergencyAlertModel.fromMap(json);
      }).toList();
    } catch (e) {
      print('❌ EmergencyService: Error loading alerts: $e');
      return [];
    }
  }

  // ============================================================
  // ✅ GET ALL ALERTS (including resolved)
  // ============================================================
  Future<List<EmergencyAlertModel>> getAllAlerts(String vetId) async {
    try {
      final data = await _supabase
          .from('vet_emergency_alerts')
          .select()
          .eq('vet_id', vetId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((json) => EmergencyAlertModel.fromMap(json))
          .toList();
    } catch (e) {
      print('❌ EmergencyService: Error loading all alerts: $e');
      return [];
    }
  }

  // ============================================================
  // ✅ GET FARMER'S ALERTS
  // ============================================================
  Future<List<EmergencyAlertModel>> getFarmerAlerts(String farmerId) async {
    try {
      final data = await _supabase
          .from('vet_emergency_alerts')
          .select()
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((json) => EmergencyAlertModel.fromMap(json))
          .toList();
    } catch (e) {
      print('❌ Error loading farmer alerts: $e');
      return [];
    }
  }

  // ============================================================
  // ✅ REALTIME STREAM - Active alerts
  // ============================================================
  Stream<List<EmergencyAlertModel>> streamActiveAlerts(String vetId) {
    return _supabase
        .from('vet_emergency_alerts')
        .stream(primaryKey: ['id'])
        .eq('vet_id', vetId)
        .order('created_at')
        .map((data) {
          final activeAlerts = data
              .where((json) => json['status'] != 'resolved')
              .map((json) => EmergencyAlertModel.fromMap(json))
              .toList();

          return activeAlerts;
        });
  }

  // ============================================================
  // ✅ GET SINGLE ALERT BY ID
  // ============================================================
  Future<EmergencyAlertModel?> getAlertById(String alertId) async {
    try {
      final data = await _supabase
          .from('vet_emergency_alerts')
          .select()
          .eq('id', alertId)
          .maybeSingle();

      if (data == null) return null;
      return EmergencyAlertModel.fromMap(data);
    } catch (e) {
      print('❌ Error getting alert: $e');
      return null;
    }
  }

  // ============================================================
  // ✅ UPDATE ALERT STATUS
  // ============================================================
  Future<bool> updateAlertStatus(String alertId, String status) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status.toLowerCase() == 'resolved') {
        updates['resolved_at'] = DateTime.now().toIso8601String();
      }

      await _supabase
          .from('vet_emergency_alerts')
          .update(updates)
          .eq('id', alertId);

      print('✅ Alert status updated to: $status');
      return true;
    } catch (e) {
      print('❌ Error updating alert status: $e');
      return false;
    }
  }

  // ============================================================
  // ✅ COUNT ACTIVE ALERTS
  // ============================================================
  Future<int> getActiveAlertsCount(String vetId) async {
    try {
      if (vetId.isEmpty) return 0;

      final data = await _supabase
          .from('vet_emergency_alerts')
          .select('id')
          .eq('vet_id', vetId)
          .neq('status', 'resolved');

      return (data as List).length;
    } catch (e) {
      print('❌ Error counting alerts: $e');
      return 0;
    }
  }

  // ============================================================
  // ✅ CREATE ALERT (farmer → single vet)
  // ============================================================
  Future<bool> createAlert({
    required String farmerId,
    required String vetId,
    required String animalName,
    required String description,
    required String location,
    required String urgency,
    String? farmerName,
    String? farmerPhone,
    String? condition,
    String? farmName,
  }) async {
    try {
      final data = <String, dynamic>{
        'id': _uuid.v4(), // ✅ ID generate
        'farmer_id': farmerId,
        'vet_id': vetId,
        'animal_name': animalName,
        'description': description,
        'location': location,
        'urgency': urgency,
        'status': 'active',
      };

      if (farmerName != null) data['farmer_name'] = farmerName;
      if (farmerPhone != null) data['farmer_phone'] = farmerPhone;
      if (condition != null) data['condition'] = condition;
      if (farmName != null) data['farm_name'] = farmName;

      await _supabase.from('vet_emergency_alerts').insert(data);
      return true;
    } catch (e) {
      print('❌ Error creating alert: $e');
      return false;
    }
  }

  // ============================================================
  // ✅ BROADCAST ALERT TO ALL AVAILABLE VETS
  // ============================================================
  Future<bool> broadcastAlert({
    required String farmerId,
    required String animalName,
    required String description,
    required String location,
    required String urgency,
    String? farmerName,
    String? farmerPhone,
    String? condition,
    String? farmName,
    String? animalId,
  }) async {
    try {
      print('📢 Broadcasting alert to all vets...');
      print('   farmerId: $farmerId');
      print('   animalName: $animalName');
      print('   urgency: $urgency');

      // ✅ 1. Available vets
      final vets = await _supabase
          .from('vet_profiles')
          .select('user_id, full_name')
          .eq('is_available', true)
          .not('user_id', 'is', null);

      if ((vets as List).isEmpty) {
        print('⚠️ No available vets found');
        return false;
      }

      print('📊 Found ${vets.length} available vets');

      // ✅ 2. Build alerts list
      final alerts = <Map<String, dynamic>>[];

      for (final vet in vets) {
        final vetId = vet['user_id'];

        if (vetId == null) {
          print('⚠️ Skipping vet with null user_id');
          continue;
        }

        final vetIdStr = vetId.toString();

        if (vetIdStr.isEmpty || vetIdStr.length < 30) {
          print('⚠️ Skipping invalid UUID: $vetIdStr');
          continue;
        }

        print('   ✅ Adding alert for: ${vet['full_name']} | $vetIdStr');

        final alertData = <String, dynamic>{
          'id': _uuid.v4(), // ✅ ID generate
          'farmer_id': farmerId,
          'vet_id': vetIdStr,
          'animal_name': animalName,
          'description': description,
          'location': location,
          'urgency': urgency,
          'status': 'active',
        };

        if (farmerName != null) alertData['farmer_name'] = farmerName;
        if (farmerPhone != null) alertData['farmer_phone'] = farmerPhone;
        if (condition != null) alertData['condition'] = condition;
        if (farmName != null) alertData['farm_name'] = farmName;
        if (animalId != null) alertData['animal_id'] = animalId;

        alerts.add(alertData);
      }

      if (alerts.isEmpty) {
        print('⚠️ No valid alerts to insert');
        return false;
      }

      // ✅ 3. Bulk insert alerts
      await _supabase.from('vet_emergency_alerts').insert(alerts);

      // ✅ 4. Notifications to each vet (with ID + created_at)
      final notifications = <Map<String, dynamic>>[];
      for (final alert in alerts) {
        notifications.add({
          'id': _uuid.v4(), // ✅ ID generate
          'user_id': alert['vet_id'],
          'title': '🚨 Emergency Alert',
          'message':
              '$animalName - ${description.length > 50 ? '${description.substring(0, 50)}...' : description}',
          'type': 'emergency',
          'reference_id': alert['id'], // ✅ Alert ID reference
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (notifications.isNotEmpty) {
        try {
          await _supabase.from('notifications').insert(notifications);
          print('✅ ${notifications.length} vet notifications created');
        } catch (e) {
          print('⚠️ Notifications failed: $e');
        }
      }

      print('✅ Alert broadcasted to ${alerts.length} vets');
      return true;
    } catch (e) {
      print('❌ Broadcast alert error: $e');
      return false;
    }
  }

  // ============================================================
  // ✅ CLAIM ALERT (Vet Accept කරනකොට)
  // ============================================================
  Future<bool> claimAlert({
    required String alertId,
    required String vetId,
    required String farmerId,
    required String animalName,
    String? vetName,
  }) async {
    try {
      print('🎯 Vet $vetId claiming alert $alertId');
      print('   farmerId: $farmerId');
      print('   animalName: $animalName');
      print('   vetName: $vetName');

      // ✅ 1. Alert එක claim කරන්න
      await _supabase
          .from('vet_emergency_alerts')
          .update({
            'status': 'in_progress',
            'claimed_by': vetId,
            'claimed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId);

      print('✅ Alert marked as in_progress');

      // ✅ 2. අනිත් vet ලාගේ alerts auto-resolve
      await _supabase
          .from('vet_emergency_alerts')
          .update({
            'status': 'resolved',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('farmer_id', farmerId)
          .eq('animal_name', animalName)
          .eq('status', 'active')
          .neq('id', alertId);

      print('✅ Other vet alerts resolved');

      // ✅ 3. Farmer ට notification (with ID + created_at)
      try {
        final notifData = {
          'id': _uuid.v4(), // ✅ ID generate
          'user_id': farmerId,
          'title': '✅ Vet Accepted Emergency',
          'message':
              '${vetName ?? 'A vet'} has accepted your emergency for $animalName',
          'type': 'emergency',
          'reference_id': alertId, // ✅ Alert reference
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        };

        print('📤 Creating farmer notification:');
        print('   user_id: $farmerId');
        print('   title: ${notifData['title']}');

        final result = await _supabase
            .from('notifications')
            .insert(notifData)
            .select();

        print('✅ Farmer notification created: $result');
      } catch (e) {
        print('⚠️ Farmer notification failed: $e');
      }

      print('✅ Alert claimed successfully');
      return true;
    } catch (e) {
      print('❌ Claim alert error: $e');
      return false;
    }
  }
}
