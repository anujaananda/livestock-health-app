// lib/screens/emergency/my_emergencies_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/emergency_alert_model.dart';
import '../../services/auth_service.dart';
import '../../services/emergency_service.dart';

class MyEmergenciesScreen extends StatefulWidget {
  const MyEmergenciesScreen({super.key});

  @override
  State<MyEmergenciesScreen> createState() => _MyEmergenciesScreenState();
}

class _MyEmergenciesScreenState extends State<MyEmergenciesScreen> {
  static const Color primaryGreen = Color(0xFF20B769);

  final EmergencyService _emergencyService = EmergencyService();
  List<EmergencyAlertModel> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  // ============================================================
  // LOAD ALERTS
  // ============================================================
  Future<void> _loadAlerts() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final farmerId = authService.currentUser!.id;

    try {
      final alerts = await _emergencyService.getFarmerAlerts(farmerId);
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load emergencies: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _loadAlerts();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Emergencies',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _alerts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _alerts.length,
                      itemBuilder: (context, index) {
                        return _buildAlertCard(_alerts[index]);
                      },
                    ),
            ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Icon(
            Icons.emergency_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'No emergencies yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3027),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Your emergency requests will appear here',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ALERT CARD — uses ACTUAL EmergencyAlertModel fields
  // ============================================================
  Widget _buildAlertCard(EmergencyAlertModel alert) {
    final urgencyColor = _urgencyColor(alert.urgency);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5F0E9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER ROW =================
          Row(
            children: [
              // Icon (urgency color)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warning_amber_rounded, color: urgencyColor),
              ),
              const SizedBox(width: 12),

              // Condition + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.condition.isEmpty
                          ? 'Emergency Alert'
                          : alert.condition,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3027),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(alert.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF697A71),
                      ),
                    ),
                  ],
                ),
              ),

              // Status chip
              _statusChip(alert.status),
            ],
          ),

          const SizedBox(height: 10),

          // ================= URGENCY + ANIMAL =================
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  alert.urgency.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: urgencyColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (alert.animalName.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🐾 ${alert.animalName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF697A71),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),

          // ================= DESCRIPTION =================
          if (alert.description.isNotEmpty ||
              alert.farmerDescription.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              alert.farmerDescription.isNotEmpty
                  ? alert.farmerDescription
                  : alert.description,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF697A71),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // ================= LOCATION =================
          if (alert.location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    alert.location,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // URGENCY COLOR
  // ============================================================
  Color _urgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return const Color(0xFFD75A5A); // red
      case 'high':
        return const Color(0xFFE8883A); // orange
      case 'medium':
        return const Color(0xFFD88719); // amber
      case 'low':
        return const Color(0xFF159957); // green
      default:
        return const Color(0xFFE8883A);
    }
  }

  // ============================================================
  // STATUS CHIP (lowercase values from model)
  // ============================================================
  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'resolved':
        bg = const Color(0xFFE0F7E8);
        fg = const Color(0xFF159957);
        label = 'Resolved';
        break;
      case 'in_progress':
      case 'inprogress':
        bg = const Color(0xFFFFF1D8);
        fg = const Color(0xFFD88719);
        label = 'In Progress';
        break;
      case 'active':
      default:
        bg = const Color(0xFFFFE5E5);
        fg = const Color(0xFFD75A5A);
        label = 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}
