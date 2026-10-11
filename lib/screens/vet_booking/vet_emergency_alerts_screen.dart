import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/emergency_alert_model.dart';
import '../../services/auth_service.dart';
import '../../services/emergency_service.dart';

class VetEmergencyAlertsScreen extends StatefulWidget {
  final bool showBackButton;

  const VetEmergencyAlertsScreen({super.key, this.showBackButton = true});

  @override
  State<VetEmergencyAlertsScreen> createState() =>
      _VetEmergencyAlertsScreenState();
}

class _VetEmergencyAlertsScreenState extends State<VetEmergencyAlertsScreen> {
  static const Color primaryGreen = Color(0xFF20B769);

  final EmergencyService _emergencyService = EmergencyService();
  List<EmergencyAlertModel> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  // ================= LOAD ALERTS =================
  Future<void> _loadAlerts() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final alerts = await _emergencyService.getActiveAlerts(
      authService.currentUser!.id,
    );

    if (!mounted) return;
    setState(() {
      _alerts = alerts;
      _isLoading = false;
    });
  }

  // ================= UPDATE STATUS (Resolve) =================
  Future<void> _updateStatus(EmergencyAlertModel alert, String status) async {
    final success = await _emergencyService.updateAlertStatus(alert.id, status);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert marked as $status'),
          backgroundColor: primaryGreen,
        ),
      );
      _loadAlerts();
    }
  }

  // ================= ACCEPT ALERT (Claim) =================
  Future<void> _acceptAlert(EmergencyAlertModel alert) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Accept Emergency?'),
        content: const Text(
          'Other vets will no longer see this alert. Are you sure you want to accept?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Accept',
              style: TextStyle(
                color: Color(0xFF20B769),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final vetId = authService.currentUser!.id;

    setState(() => _isLoading = true);

    final success = await _emergencyService.claimAlert(
      alertId: alert.id,
      vetId: vetId,
      farmerId: alert.farmerId ?? '',
      animalName: alert.animalName,
      vetName: authService.currentUser?.email ?? 'Vet',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency accepted! Farmer has been notified.'),
          backgroundColor: Color(0xFF20B769),
        ),
      );
      _loadAlerts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to accept emergency'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= CALL FARMER =================
  Future<void> _callFarmer(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Cannot call $phone')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF9),
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Emergency Alerts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadAlerts();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAlerts,
        color: primaryGreen,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _alerts.isEmpty
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

  // ================= EMPTY STATE =================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFE5F7EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: primaryGreen,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Emergency Alerts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3027),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'All clear! No urgent cases right now.',
            style: TextStyle(fontSize: 13, color: Color(0xFF697A71)),
          ),
        ],
      ),
    );
  }

  // ================= ALERT CARD =================
  Widget _buildAlertCard(EmergencyAlertModel alert) {
    // Urgency color
    Color urgencyColor;
    switch (alert.urgency.toLowerCase()) {
      case 'critical':
        urgencyColor = const Color(0xFFD32F2F);
        break;
      case 'high':
        urgencyColor = const Color(0xFFF59E0B);
        break;
      case 'medium':
        urgencyColor = const Color(0xFF3B82F6);
        break;
      default:
        urgencyColor = const Color(0xFF6B7280);
    }

    // Status badge
    Color statusBg;
    Color statusText;
    String statusLabel;
    switch (alert.status.toLowerCase()) {
      case 'active':
        statusBg = const Color(0xFFFFE5E5);
        statusText = const Color(0xFFD32F2F);
        statusLabel = 'Active';
        break;
      case 'in_progress':
        statusBg = const Color(0xFFFFF4E5);
        statusText = const Color(0xFFF59E0B);
        statusLabel = 'In Progress';
        break;
      case 'resolved':
        statusBg = const Color(0xFFE5F7EA);
        statusText = const Color(0xFF20B769);
        statusLabel = 'Resolved';
        break;
      default:
        statusBg = const Color(0xFFF3F4F6);
        statusText = const Color(0xFF6B7280);
        statusLabel = alert.status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: urgencyColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP SECTION
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Urgency + Status + Time
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: urgencyColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: urgencyColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            alert.urgency.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: urgencyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusText,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(alert.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Row 2: Animal + Condition
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F7EA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.pets,
                        color: primaryGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.animalName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3027),
                            ),
                          ),
                          if (alert.condition.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              alert.condition,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF697A71),
                              ),
                            ),
                          ],
                          if (alert.farmName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.agriculture_outlined,
                                  size: 12,
                                  color: Color(0xFF697A71),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  alert.farmName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF697A71),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Description
                if (alert.description.isNotEmpty ||
                    alert.farmerDescription.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FCF9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      alert.description.isNotEmpty
                          ? alert.description
                          : alert.farmerDescription,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                        height: 1.4,
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF697A71),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        alert.location,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF697A71),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if (alert.farmerName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Color(0xFF697A71),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          alert.farmerName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF697A71),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // IMAGE
          if (alert.imageUrl != null && alert.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
              ),
              child: Image.network(
                alert.imageUrl!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          // ACTION BUTTONS
          if (alert.status.toLowerCase() != 'resolved')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  // Call farmer button
                  if (alert.farmerPhone.isNotEmpty)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F7EA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.phone,
                          color: primaryGreen,
                          size: 20,
                        ),
                        onPressed: () => _callFarmer(alert.farmerPhone),
                      ),
                    ),
                  if (alert.farmerPhone.isNotEmpty) const SizedBox(width: 8),

                  // Accept button (only if active)
                  if (alert.status.toLowerCase() == 'active')
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _acceptAlert(alert), // ✅ NEW
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF59E0B),
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Accept',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                  if (alert.status.toLowerCase() == 'active' ||
                      alert.status.toLowerCase() == 'in_progress')
                    const SizedBox(width: 8),

                  // Resolve button
                  if (alert.status.toLowerCase() == 'active' ||
                      alert.status.toLowerCase() == 'in_progress')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateStatus(alert, 'resolved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Resolve',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // RESOLVED FOOTER
          if (alert.status.toLowerCase() == 'resolved' &&
              alert.resolvedAt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F7EA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: primaryGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Resolved ${_formatTime(alert.resolvedAt!)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= FORMAT TIME =================
  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour(s) ago';
    if (diff.inDays < 7) return '${diff.inDays} day(s) ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
