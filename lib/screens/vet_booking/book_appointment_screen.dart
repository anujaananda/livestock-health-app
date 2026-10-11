// lib/screens/vet_booking/book_appointment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/animal_model.dart';
import '../../models/vet_model.dart';
import '../../services/animal_service.dart';
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
  static const Color primaryGreen = Color(0xFF24B86A);

  late List<DateTime> _dates;

  final List<String> _times = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
  ];

  int _selectedDateIndex = 0;
  int _selectedTimeIndex = 1;
  bool _isLoading = false;

  // ✅ Animal selector
  final AnimalService _animalService = AnimalService();
  List<AnimalModel> _animals = [];
  AnimalModel? _selectedAnimal;
  bool _isLoadingAnimals = true;

  @override
  void initState() {
    super.initState();
    _generateDates();
    _loadAnimals();
  }

  // ================= GENERATE NEXT 7 DAYS =================
  void _generateDates() {
    final now = DateTime.now();
    _dates = List.generate(7, (index) {
      return DateTime(now.year, now.month, now.day + index);
    });
  }

  // ================= LOAD FARMER'S ANIMALS =================
  Future<void> _loadAnimals() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final farmerId = authService.currentUser!.id;

    try {
      final animals = await _animalService.getFarmerAnimals(farmerId);
      if (!mounted) return;
      setState(() {
        _animals = animals;
        if (animals.isNotEmpty) {
          _selectedAnimal = animals.first;
        }
        _isLoadingAnimals = false;
      });
      debugPrint('✅ Loaded ${animals.length} animals');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingAnimals = false);
      debugPrint('❌ Load animals error: $e');
    }
  }

  // ================= DAY NAME =================
  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  // ================= MONTH NAME =================
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  // ================= SHORT MONTH NAME =================
  String _getShortMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  // ================= CONFIRM BOOKING =================
  Future<void> _confirmBooking() async {
    if (_selectedAnimal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an animal first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final vetId = widget.vet.effectiveUserId;

    if (vetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid vet data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final appointmentService = AppointmentService();
    final selectedDate = _dates[_selectedDateIndex];

    final success = await appointmentService.createAppointment(
      farmerId: authService.currentUser!.id,
      vetId: vetId,
      animalName: _selectedAnimal!.displayName,
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

      // ✅ Pass selected animal to request consultation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RequestConsultationScreen(
            vet: widget.vet,
            selectedAnimal: _selectedAnimal, // ✅ Pass animal
          ),
        ),
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
    final firstDate = _dates.first;
    final monthYearText = '${_getMonthName(firstDate.month)} ${firstDate.year}';

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
            _buildVetCard(),

            const SizedBox(height: 24),

            // ================= SELECT ANIMAL =================
            const Text(
              'Select Animal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3027),
              ),
            ),
            const SizedBox(height: 12),

            if (_isLoadingAnimals)
              _buildAnimalLoading()
            else if (_animals.isEmpty)
              _buildNoAnimalsCard()
            else
              _buildAnimalDropdown(),

            const SizedBox(height: 24),

            // ================= SELECT DATE =================
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
                  monthYearText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                itemBuilder: (context, index) {
                  final date = _dates[index];
                  final isSelected = _selectedDateIndex == index;
                  final isToday = index == 0;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDateIndex = index),
                    child: Container(
                      width: 62,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryGreen : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? primaryGreen
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isToday ? 'Today' : _getDayName(date),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF697A71),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF1E3027),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getShortMonthName(date.month),
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected
                                  ? Colors.white70
                                  : const Color(0xFF9CA3AF),
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

            // ================= SELECT TIME =================
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

            const SizedBox(height: 24),

            // ⚠️ Consultation Type අයින් කළා — Request Consultation එකේ තියෙනවා
            _buildBookingSummary(),

            const SizedBox(height: 32),

            // ================= CONFIRM BOOKING =================
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

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ================= ✅ ANIMAL DROPDOWN =================
  Widget _buildAnimalDropdown() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AnimalModel>(
          value: _selectedAnimal,
          isExpanded: true,
          isDense: true,
          itemHeight: null,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: _animals.map<DropdownMenuItem<AnimalModel>>((animal) {
            return DropdownMenuItem<AnimalModel>(
              value: animal,
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    _buildAnimalAvatar(animal, radius: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            animal.displayName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3027),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            animal.description,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF697A71),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedAnimal = value);
          },
        ),
      ),
    );
  }

  // ================= ✅ ANIMAL AVATAR =================
  Widget _buildAnimalAvatar(AnimalModel animal, {double radius = 18}) {
    final hasImage = animal.imageUrl != null && animal.imageUrl!.isNotEmpty;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryGreen.withValues(alpha: 0.12),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                animal.imageUrl!,
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: radius * 0.6,
                      height: radius * 0.6,
                      child: const CircularProgressIndicator(
                        color: primaryGreen,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.pets, color: primaryGreen, size: radius * 0.9),
              )
            : Icon(Icons.pets, color: primaryGreen, size: radius * 0.9),
      ),
    );
  }

  Widget _buildAnimalLoading() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildNoAnimalsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No animals found. Please add an animal first.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  // ================= VET CARD =================
  Widget _buildVetCard() {
    final String imageUrl =
        (widget.vet.profileImageUrl != null &&
            widget.vet.profileImageUrl!.isNotEmpty)
        ? widget.vet.profileImageUrl!
        : 'https://i.pravatar.cc/150?img=12';

    final String locationText =
        widget.vet.district.isNotEmpty && widget.vet.district != 'Unknown'
        ? '${widget.vet.district}, ${widget.vet.location}'
        : widget.vet.location;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5F0E9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFE5F7EA),
                backgroundImage: NetworkImage(imageUrl),
                onBackgroundImageError: (_, __) {},
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Color(0xFF697A71),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF697A71),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_money, color: primaryGreen, size: 20),
                const SizedBox(width: 6),
                const Text(
                  'Consultation Fee',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF697A71),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  'Rs. ${widget.vet.consultationFee?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= BOOKING SUMMARY =================
  Widget _buildBookingSummary() {
    final selectedDate = _dates[_selectedDateIndex];
    final selectedTime = _times[_selectedTimeIndex];

    final dateText =
        '${_getDayName(selectedDate)}, ${selectedDate.day} ${_getShortMonthName(selectedDate.month)} ${selectedDate.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5F0E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 18, color: primaryGreen),
              SizedBox(width: 8),
              Text(
                'Booking Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3027),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5F0E9)),
          const SizedBox(height: 12),

          _buildSummaryRow(
            icon: Icons.pets_outlined,
            label: 'Animal',
            value: _selectedAnimal?.displayName ?? 'Not selected',
          ),
          const SizedBox(height: 8),

          _buildSummaryRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: dateText,
          ),
          const SizedBox(height: 8),

          _buildSummaryRow(
            icon: Icons.access_time,
            label: 'Time',
            value: selectedTime,
          ),
          const SizedBox(height: 8),

          _buildSummaryRow(
            icon: Icons.person_outline,
            label: 'Vet',
            value: widget.vet.name,
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5F0E9)),
          const SizedBox(height: 12),

          Row(
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3027),
                ),
              ),
              const Spacer(),
              Text(
                'Rs. ${widget.vet.consultationFee?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF697A71)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF697A71)),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3027),
            ),
          ),
        ),
      ],
    );
  }
}
