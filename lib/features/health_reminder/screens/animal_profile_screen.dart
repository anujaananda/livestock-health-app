import 'package:flutter/material.dart';

import '../widgets/animal_header.dart';
import '../widgets/health_status_tab.dart';
import '../widgets/treatment_history_tab.dart';
import '../widgets/vaccination_history_tab.dart';
import '../widgets/medical_records_tab.dart';
import 'add_health_record_screen.dart';

class AnimalProfileScreen extends StatefulWidget {
  final Map<String, dynamic> animal;

  const AnimalProfileScreen({super.key, required this.animal});

  @override
  State<AnimalProfileScreen> createState() => _AnimalProfileScreenState();
}

class _AnimalProfileScreenState extends State<AnimalProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                HealthStatusTab(animal: widget.animal),
                TreatmentHistoryTab(animal: widget.animal),
                VaccinationHistoryTab(animal: widget.animal),
                MedicalRecordsTab(animal: widget.animal),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddHealthRecordScreen(
                animalId: widget.animal['id'].toString(),
              ),
            ),
          );
          // Refresh state if needed
          setState(() {});
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
