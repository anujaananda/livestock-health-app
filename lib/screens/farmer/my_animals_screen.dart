import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_animal_screen.dart';
import 'animal_profile_screen.dart';

class MyAnimalsScreen extends StatefulWidget {
  const MyAnimalsScreen({super.key});

  @override
  State<MyAnimalsScreen> createState() => _MyAnimalsScreenState();
}

class _MyAnimalsScreenState extends State<MyAnimalsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  bool _isLoading = true;

  String? _errorMessage;

  List<Map<String, dynamic>> _animals = [];

  @override
  void initState() {
    super.initState();

    _loadAnimals();
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD ANIMALS FROM SUPABASE
  // ============================================================

  Future<void> _loadAnimals() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _animals = [];
        _isLoading = false;
        _errorMessage = 'Please login to view your animals.';
      });

      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await Supabase.instance.client
          .from('animals')
          .select(
            'id, owner_id, animal_id_tag, name, species, breed, '
            'age, gender, date_of_birth, image_url, '
            'health_status, created_at',
          )
          .eq('owner_id', user.id)
          .order(
            'created_at',
            ascending: false,
          );

      final animals = List<Map<String, dynamic>>.from(response);

      if (!mounted) return;

      setState(() {
        _animals = animals;
        _isLoading = false;
        _errorMessage = null;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Could not load animals. Please try again.';
      });
    }
  }

  // ============================================================
  // FILTER ANIMALS
  // ============================================================

  List<Map<String, dynamic>> get _filteredAnimals {
    if (_searchText.trim().isEmpty) {
      return _animals;
    }

    final search = _searchText.toLowerCase().trim();

    return _animals.where((animal) {
      final name =
          (animal['name'] ?? '').toString().toLowerCase();

      final animalId =
          (animal['animal_id_tag'] ?? '')
              .toString()
              .toLowerCase();

      final species =
          (animal['species'] ?? '')
              .toString()
              .toLowerCase();

      final breed =
          (animal['breed'] ?? '')
              .toString()
              .toLowerCase();

      return name.contains(search) ||
          animalId.contains(search) ||
          species.contains(search) ||
          breed.contains(search);
    }).toList();
  }

  // ============================================================
  // OPEN ADD ANIMAL
  // ============================================================

  Future<void> _openAddAnimalScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddAnimalScreen(),
      ),
    );

    if (!mounted) return;

    // Refresh after adding animal
    await _loadAnimals();
  }

  // ============================================================
  // OPEN ANIMAL PROFILE
  // ============================================================

  Future<void> _openAnimalProfile(
    Map<String, dynamic> animal,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimalProfileScreen(
          animal: animal,
        ),
      ),
    );

    if (!mounted) return;

    // IMPORTANT:
    // Refresh list after Edit / Delete / Back
    await _loadAnimals();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filteredAnimals = _filteredAnimals;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                12,
                12,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Animals',
                          style: TextStyle(
                            color: Color(0xFF176B43),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          'Manage your livestock',
                          style: TextStyle(
                            color: Color(0xFF7B8A82),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: 'Refresh',
                    onPressed:
                        _isLoading ? null : _loadAnimals,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF176B43),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // SEARCH BAR
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                5,
                20,
                14,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText:
                      'Search by name, ID, species or breed',

                  hintStyle: const TextStyle(
                    color: Color(0xFF9AA69F),
                    fontSize: 12,
                  ),

                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF617068),
                    size: 21,
                  ),

                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();

                            setState(() {
                              _searchText = '';
                            });
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 19,
                            color: Color(0xFF7B8A82),
                          ),
                        )
                      : null,

                  filled: true,

                  fillColor: Colors.white,

                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFDDE7E1),
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF24B86A),
                      width: 1.3,
                    ),
                  ),
                ),
              ),
            ),

            // ==================================================
            // BODY
            // ==================================================

            Expanded(
              child: _buildBody(filteredAnimals),
            ),
          ],
        ),
      ),

      // ========================================================
      // ADD ANIMAL BUTTON
      // ========================================================

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddAnimalScreen,

        backgroundColor: const Color(0xFF24B86A),

        foregroundColor: Colors.white,

        elevation: 2,

        icon: const Icon(
          Icons.add_rounded,
        ),

        label: const Text(
          'Add Animal',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BODY STATES
  // ============================================================

  Widget _buildBody(
    List<Map<String, dynamic>> filteredAnimals,
  ) {
    // Loading
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF24B86A),
        ),
      );
    }

    // Error
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFE15B5B),
                size: 50,
              ),

              const SizedBox(height: 12),

              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF65736B),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 18),

              ElevatedButton.icon(
                onPressed: _loadAnimals,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF24B86A),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No animals
    if (_animals.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF24B86A),
        onRefresh: _loadAnimals,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height:
                  MediaQuery.of(context).size.height * 0.48,
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF7EF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      size: 40,
                      color: Color(0xFF24B86A),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'No animals yet',
                    style: TextStyle(
                      color: Color(0xFF234C37),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Add your first animal to get started.',
                    style: TextStyle(
                      color: Color(0xFF7B8A82),
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _openAddAnimalScreen,
                    icon: const Icon(
                      Icons.add_rounded,
                    ),
                    label: const Text(
                      'Add Animal',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF24B86A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // No search results
    if (filteredAnimals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: Color(0xFF9AA69F),
              size: 50,
            ),

            const SizedBox(height: 12),

            const Text(
              'No animals found',
              style: TextStyle(
                color: Color(0xFF234C37),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'No results for "$_searchText"',
              style: const TextStyle(
                color: Color(0xFF7B8A82),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Animal list
    return RefreshIndicator(
      color: const Color(0xFF24B86A),

      onRefresh: _loadAnimals,

      child: ListView.separated(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(
          20,
          4,
          20,
          100,
        ),

        itemCount: filteredAnimals.length,

        separatorBuilder: (
          context,
          index,
        ) {
          return const SizedBox(height: 12);
        },

        itemBuilder: (
          context,
          index,
        ) {
          final animal = filteredAnimals[index];

          return _animalCard(
            animal: animal,

            // ==========================================
            // OPEN PROFILE
            // ==========================================

            onTap: () async {
              await _openAnimalProfile(animal);
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // ANIMAL CARD
  // ============================================================

  Widget _animalCard({
    required Map<String, dynamic> animal,
    required VoidCallback onTap,
  }) {
    final String name =
        (animal['name'] ?? 'Unnamed').toString();

    final String animalId =
        (animal['animal_id_tag'] ?? 'No ID')
            .toString();

    final String species =
        (animal['species'] ?? 'Unknown').toString();

    final String breed =
        (animal['breed'] ?? '').toString();

    final String gender =
        (animal['gender'] ?? 'Unknown').toString();

    final String status =
        (animal['health_status'] ?? 'Healthy')
            .toString();

    final String imageUrl =
        (animal['image_url'] ?? '').toString();

    final dynamic ageValue = animal['age'];

    final String age = ageValue == null
        ? 'Age unknown'
        : '$ageValue ${ageValue.toString() == '1' ? 'year' : 'years'}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(18),

        child: Container(
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color: const Color(0xFFE0E9E4),
            ),

            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),

          child: Row(
            children: [
              // ========================================
              // ANIMAL PHOTO
              // ========================================

              Container(
                width: 76,
                height: 76,

                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EF),
                  borderRadius:
                      BorderRadius.circular(14),
                ),

                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(14),

                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,

                          fit: BoxFit.cover,

                          loadingBuilder: (
                            context,
                            child,
                            loadingProgress,
                          ) {
                            if (loadingProgress ==
                                null) {
                              return child;
                            }

                            return const Center(
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Color(0xFF24B86A),
                                strokeWidth: 2,
                              ),
                            );
                          },

                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Icon(
                              Icons.pets_rounded,
                              color:
                                  Color(0xFF24B86A),
                              size: 34,
                            );
                          },
                        )
                      : const Icon(
                          Icons.pets_rounded,
                          color: Color(0xFF24B86A),
                          size: 34,
                        ),
                ),
              ),

              const SizedBox(width: 14),

              // ========================================
              // ANIMAL DETAILS
              // ========================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color:
                                  Color(0xFF1E3027),
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        _healthStatusTag(status),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'ID: $animalId',
                      style: const TextStyle(
                        color: Color(0xFF75837B),
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _smallInfo(
                          Icons.pets_outlined,
                          species,
                        ),

                        _smallInfo(
                          Icons
                              .calendar_month_outlined,
                          age,
                        ),

                        _smallInfo(
                          Icons.transgender_rounded,
                          gender,
                        ),
                      ],
                    ),

                    if (breed.isNotEmpty) ...[
                      const SizedBox(height: 7),

                      Text(
                        'Breed: $breed',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64736B),
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 5),

              // ========================================
              // PROFILE ARROW
              // ========================================

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8B9891),
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEALTH STATUS TAG
  // ============================================================

  Widget _healthStatusTag(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'need attention':
        backgroundColor =
            const Color(0xFFFFF1D8);

        textColor =
            const Color(0xFFD88719);

        break;

      case 'under treatment':
        backgroundColor =
            const Color(0xFFFFE5E5);

        textColor =
            const Color(0xFFD75A5A);

        break;

      case 'healthy':
      default:
        backgroundColor =
            const Color(0xFFE0F7E8);

        textColor =
            const Color(0xFF159957);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: backgroundColor,

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        status,

        style: TextStyle(
          color: textColor,

          fontSize: 9,

          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // SMALL INFO
  // ============================================================

  Widget _smallInfo(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        Icon(
          icon,
          size: 13,
          color: const Color(0xFF7B8A82),
        ),

        const SizedBox(width: 3),

        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF6D7B73),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}