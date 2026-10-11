import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all notifications for a user
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((json) => NotificationModel.fromMap(json))
          .toList();
    } catch (e) {
      print('❌ Error loading notifications: $e');
      return [];
    }
  }

  /// Realtime stream
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map(
          (data) =>
              data.map((json) => NotificationModel.fromMap(json)).toList(),
        );
  }

  /// Unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final data = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Mark as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark all as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
