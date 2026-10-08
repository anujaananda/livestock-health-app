import 'package:flutter/material.dart';

import '../widgets/animal_header.dart';
import '../widgets/health_status_tab.dart';
import '../widgets/treatment_history_tab.dart';
import '../widgets/vaccination_history_tab.dart';
import '../widgets/medical_records_tab.dart';
import 'add_health_record_screen.dart';

import '../../../screens/home/farmer_home_screen.dart';
import '../../../screens/vet_booking/find_vet_screen.dart';
import '../../../screens/vet_booking/my_appointments_screen.dart';
import '../../../screens/vet_booking/farmer_profile_screen.dart';

class AnimalProfileScreen extends StatefulWidget {
  final Map<String, dynamic> animal;

  const AnimalProfileScreen({super.key, required this.animal});

  @override
  State<AnimalProfileScreen> createState() => _AnimalProfileScreenState();
}

class _AnimalProfileScreenState extends State<AnimalProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openFarmerHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const FarmerHomeScreen()),
      (route) => false,
    );
  }

  void _openFindVet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindVetScreen()),
    );
  }

  void _openMyAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyAppointmentsScreen()),
    );
  }

  void _openFarmerProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FarmerProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Animal Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.green),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          AnimalHeader(animal: widget.animal),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
            tabs: const [
              Tab(text: 'Health Records'),
              Tab(text: 'Treatment History'),
              Tab(text: 'Vaccination History'),
              Tab(text: 'Medical Records'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                HealthStatusTab(
                  key: ValueKey('health_status_$_refreshKey'),
                  animal: widget.animal,
                ),
                TreatmentHistoryTab(animal: widget.animal),
                VaccinationHistoryTab(animal: widget.animal),
                MedicalRecordsTab(animal: widget.animal),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddHealthRecordScreen(animal: widget.animal),
                  ),
                );
                if (result == true) {
                  setState(() {
                    _refreshKey++;
                  });
                }
              },
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Animals is active
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF20B769), // primaryGreen from home
        unselectedItemColor: const Color(0xFF7D8B83),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          if (index == 0) {
            _openFarmerHome();
          } else if (index == 1) {
            Navigator.pop(context); // Go back to My Animals screen
          } else if (index == 2) {
            _openFindVet();
          } else if (index == 3) {
            _openMyAppointments();
          } else if (index == 4) {
            _openFarmerProfile();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_rounded),
            label: 'Animals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            label: 'Consult',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
