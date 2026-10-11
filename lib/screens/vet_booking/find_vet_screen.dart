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

  // Location filter (Sri Lanka districts)
  String _selectedDistrict = 'All Districts';
  bool _showFilterPanel = false;

  // Sri Lanka 25 districts
  static const List<String> _sriLankaDistricts = [
    'All Districts',
    'Ampara',
    'Anuradhapura',
    'Badulla',
    'Batticaloa',
    'Colombo',
    'Galle',
    'Gampaha',
    'Hambantota',
    'Jaffna',
    'Kalutara',
    'Kandy',
    'Kegalle',
    'Kilinochchi',
    'Kurunegala',
    'Mannar',
    'Matale',
    'Matara',
    'Monaragala',
    'Mullaitivu',
    'Nuwara Eliya',
    'Polonnaruwa',
    'Puttalam',
    'Ratnapura',
    'Trincomalee',
    'Vavuniya',
  ];

  @override
  void initState() {
    super.initState();
    _loadVets();
    _searchController.addListener(_filterVets);
  }

  Future<void> _loadVets() async {
    final vets = await _vetService.getAllVets();
    setState(() {
      _vets = vets;
      _filteredVets = vets;
      _isLoading = false;
    });
  }

  void _filterVets() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      _filteredVets = _vets.where((vet) {
        // Search query filter (name / location / district)
        final matchesSearch =
            query.isEmpty ||
            vet.name.toLowerCase().contains(query) ||
            vet.location.toLowerCase().contains(query) ||
            vet.district.toLowerCase().contains(query);

        // District filter (exact match on district field)
        final matchesDistrict =
            _selectedDistrict == 'All Districts' ||
            vet.district.toLowerCase() == _selectedDistrict.toLowerCase();

        return matchesSearch && matchesDistrict;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedDistrict = 'All Districts';
      _filteredVets = _vets;
    });
  }

  bool get _hasActiveFilters => _selectedDistrict != 'All Districts';

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
            icon: Icon(
              _showFilterPanel ? Icons.tune : Icons.tune_outlined,
              color: _hasActiveFilters ? Colors.amber : Colors.white,
            ),
            onPressed: () {
              setState(() => _showFilterPanel = !_showFilterPanel);
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
                decoration: InputDecoration(
                  hintText: 'Search by name or location',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF697A71),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 18,
                            color: Color(0xFF697A71),
                          ),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // ================= FILTER PANEL =================
          if (_showFilterPanel) _buildFilterPanel(),

          // ================= ACTIVE FILTER CHIPS =================
          if (_hasActiveFilters) _buildActiveFilters(),

          // ================= SECTION TITLE =================
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Livestock Vets',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3027),
                  ),
                ),
                Text(
                  '${_filteredVets.length} found',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF697A71),
                  ),
                ),
              ],
            ),
          ),

          // ================= VET LIST =================
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVets.isEmpty
                ? _buildEmptyState()
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

  // ================= FILTER PANEL (District Dropdown) =================
  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5F0E9))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: primaryGreen),
              SizedBox(width: 6),
              Text(
                'Filter by District',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3027),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FCF9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5F0E9)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDistrict,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF697A71),
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1E3027),
                  fontWeight: FontWeight.w500,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(10),
                menuMaxHeight: 350,
                items: _sriLankaDistricts.map((district) {
                  return DropdownMenuItem<String>(
                    value: district,
                    child: Text(
                      district,
                      style: TextStyle(
                        fontSize: 13,
                        color: district == 'All Districts'
                            ? primaryGreen
                            : const Color(0xFF1E3027),
                        fontWeight: district == _selectedDistrict
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedDistrict = value);
                  _filterVets();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ACTIVE FILTER CHIPS =================
  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: Color(0xFF697A71)),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildFilterChip(_selectedDistrict, () {
                  setState(() => _selectedDistrict = 'All Districts');
                  _filterVets();
                }),
              ],
            ),
          ),
          GestureDetector(
            onTap: _clearFilters,
            child: const Text(
              'Clear all',
              style: TextStyle(
                fontSize: 12,
                color: primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F7EA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: primaryGreen),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close, size: 12, color: primaryGreen),
          ),
        ],
      ),
    );
  }

  // ================= EMPTY STATE =================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: const Color(0xFF697A71).withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No vets found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3027),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting your search or filter',
            style: TextStyle(fontSize: 13, color: Color(0xFF697A71)),
          ),
          const SizedBox(height: 20),
          if (_hasActiveFilters || _searchController.text.isNotEmpty)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Clear Filters'),
              style: TextButton.styleFrom(foregroundColor: primaryGreen),
            ),
        ],
      ),
    );
  }

  // ================= VET CARD =================
  Widget _buildVetCard(VetModel vet) {
    // ✅ Profile image URL - null-safe
    final String imageUrl =
        (vet.profileImageUrl != null && vet.profileImageUrl!.isNotEmpty)
        ? vet.profileImageUrl!
        : 'https://i.pravatar.cc/150?img=${10 + vet.name.hashCode % 10}';

    // ✅ District + Location display
    final String locationText =
        vet.district.isNotEmpty && vet.district != 'Unknown'
        ? '${vet.district}, ${vet.location}'
        : vet.location;

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
              backgroundImage: NetworkImage(imageUrl),
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
