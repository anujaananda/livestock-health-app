import 'package:flutter/material.dart';

import '../../models/vet_model.dart';
import '../../services/vet_service.dart';
import 'vet_profile_screen.dart';

class FindVetScreen extends StatefulWidget {
  const FindVetScreen({super.key});

  @override
  State<FindVetScreen> createState() => _FindVetScreenState();
}

class _FindVetScreenState extends State<FindVetScreen> {
  static const Color primaryGreen = Color(0xFF20B769);

  final VetService _vetService = VetService();
  final TextEditingController _searchController = TextEditingController();

  List<VetModel> _vets = [];
  List<VetModel> _filteredVets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVets();
    _searchController.addListener(_filterVets);
  }

  Future<void> _loadVets() async {
    print('🔄 _loadVets() called');

    final vets = await _vetService.getAllVets();

    print('📊 Vets in screen: ${vets.length}');
    for (var v in vets) {
      print('  👤 ${v.name} | ${v.specialization} | ${v.location}');
    }

    setState(() {
      _vets = vets;
      _filteredVets = vets;
      _isLoading = false;
    });
  }

  void _filterVets() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredVets = _vets;
      } else {
        _filteredVets = _vets.where((vet) {
          return vet.name.toLowerCase().contains(query) ||
              vet.specialization.toLowerCase().contains(query) ||
              vet.location.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF9),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Find a Vet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter coming soon')),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // ================= SEARCH BAR =================
          Container(
            color: primaryGreen,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by name or location',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF697A71)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // ================= SECTION TITLE =================
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Available Livestock Vets',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3027),
                ),
              ),
            ),
          ),

          // ================= VET LIST =================
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVets.isEmpty
                ? const Center(
                    child: Text(
                      'No vets available',
                      style: TextStyle(fontSize: 14, color: Color(0xFF697A71)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredVets.length,
                    itemBuilder: (context, index) {
                      final vet = _filteredVets[index];
                      return _buildVetCard(vet);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ================= VET CARD =================
  Widget _buildVetCard(VetModel vet) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VetProfileScreen(vet: vet)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
              backgroundImage: NetworkImage(
                'https://i.pravatar.cc/150?img=${10 + vet.name.hashCode % 10}',
              ),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vet.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3027),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vet.specialization,
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
                      Text(
                        vet.location,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF697A71),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}
