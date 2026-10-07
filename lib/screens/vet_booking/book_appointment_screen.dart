import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/vet_model.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import 'request_consultation_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  final VetModel vet;

  const BookAppointmentScreen({super.key, required this.vet});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  static const Color primaryGreen = Color(0xFF20B769);

  final List<Map<String, dynamic>> _dates = [
    {'day': 'Mon', 'date': 12},
    {'day': 'Tue', 'date': 13},
    {'day': 'Wed', 'date': 14},
    {'day': 'Thu', 'date': 15},
    {'day': 'Fri', 'date': 16},
  ];

  final List<String> _times = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
  ];

  int _selectedDateIndex = 1;
  int _selectedTimeIndex = 1;
  bool _isLoading = false;

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final appointmentService = AppointmentService();

    final selectedDate = DateTime.now().add(
      Duration(days: _dates[_selectedDateIndex]['date'] - DateTime.now().day),
    );

    final success = await appointmentService.createAppointment(
      farmerId: authService.currentUser!.id,
      vetId: widget.vet.id,
      animalName: 'Animal',
      date: selectedDate,
      time: _times[_selectedTimeIndex],
      notes: '',
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // ================= NAVIGATE TO REQUEST CONSULTATION =================
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RequestConsultationScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to book appointment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book Appointment',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vet Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5F0E9)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE5F7EA),
                    backgroundImage: const NetworkImage(
                      'https://i.pravatar.cc/150?img=12',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.vet.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3027),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.vet.specialization,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF697A71),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.vet.location,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF697A71),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Select Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3027),
                  ),
                ),
                Text(
                  'October 2026',
                  style: TextStyle(
                    fontSize: 13,
                    color: primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 75,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                itemBuilder: (context, index) {
                  final date = _dates[index];
                  final isSelected = _selectedDateIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDateIndex = index),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryGreen : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? primaryGreen
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            date['day'],
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF697A71),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date['date']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF1E3027),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Select Time
            const Text(
              'Select Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3027),
              ),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3.0,
              ),
              itemCount: _times.length,
              itemBuilder: (context, index) {
                final time = _times[index];
                final isSelected = _selectedTimeIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTimeIndex = index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? primaryGreen : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? primaryGreen
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1E3027),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Confirm Booking
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
