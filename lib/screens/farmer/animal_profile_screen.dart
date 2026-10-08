import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'edit_animal_screen.dart';

class AnimalProfileScreen extends StatefulWidget {
  final Map<String, dynamic> animal;

  const AnimalProfileScreen({
    super.key,
    required this.animal,
  });

  @override
  State<AnimalProfileScreen> createState() =>
      _AnimalProfileScreenState();
}

class _AnimalProfileScreenState
    extends State<AnimalProfileScreen> {
  late Map<String, dynamic> _animal;

  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    _animal =
        Map<String, dynamic>.from(widget.animal);
  }

  // ============================================================
  // EDIT ANIMAL
  // ============================================================

  Future<void> _editAnimal() async {
    final updatedAnimal =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditAnimalScreen(
          animal: _animal,
        ),
      ),
    );

    if (updatedAnimal != null && mounted) {
      setState(() {
        _animal = updatedAnimal;
      });
    }
  }

  // ============================================================
  // HEALTH RECORDS
  // ============================================================

  void _openHealthRecords() {
    final animalId = _animal['id'];

    if (animalId == null) {
      _showMessage(
        'Animal ID not found.',
        isError: true,
      );
      return;
    }

    // ==========================================================
    // TEMPORARY
    // ==========================================================
    //
    // Health Records member ge screen eka ready unama
    // me kotasa replace karanna.
    //
    // Example:
    //
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => HealthRecordsScreen(
    //       animalId: animalId.toString(),
    //     ),
    //   ),
    // );
    //
    // ==========================================================

    _showMessage(
      'Health Records will be connected here.',
    );
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  Future<void> _confirmDelete() async {
    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),

          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFE15B5B),
              ),
              SizedBox(width: 10),
              Text(
                'Delete Animal?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),

          content: Text(
            'Are you sure you want to delete '
            '${_animal['name'] ?? 'this animal'}? '
            'This action cannot be undone.',
            style: const TextStyle(
              color: Color(0xFF65736B),
              fontSize: 13,
              height: 1.5,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color:
                      Color(0xFF68776F),
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFE15B5B),
                foregroundColor:
                    Colors.white,
                elevation: 0,
              ),

              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteAnimal();
    }
  }

  // ============================================================
  // DELETE ANIMAL
  // ============================================================

  Future<void> _deleteAnimal() async {
    final animalId = _animal['id'];

    if (animalId == null) {
      _showMessage(
        'Animal ID not found.',
        isError: true,
      );
      return;
    }

    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please login again.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await Supabase.instance.client
          .from('animals')
          .delete()
          .eq(
            'id',
            animalId,
          )
          .eq(
            'owner_id',
            user.id,
          );

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not delete animal: ${e.message}',
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not delete animal. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor: isError
            ? const Color(0xFFE15B5B)
            : const Color(0xFF176B43),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final String name =
        (_animal['name'] ?? 'Unnamed')
            .toString();

    final String animalTag =
        (_animal['animal_id_tag'] ?? 'No ID')
            .toString();

    final String species =
        (_animal['species'] ?? 'Unknown')
            .toString();

    final String breed =
        (_animal['breed'] ?? 'Not provided')
            .toString();

    final String gender =
        (_animal['gender'] ?? 'Unknown')
            .toString();

    final String healthStatus =
        (_animal['health_status'] ?? 'Healthy')
            .toString();

    final String imageUrl =
        (_animal['image_url'] ?? '')
            .toString();

    final String dateOfBirth =
        _formatDate(
      _animal['date_of_birth']?.toString(),
    );

    final dynamic ageValue =
        _animal['age'];

    final String age =
        ageValue == null
            ? 'Unknown'
            : '$ageValue '
                '${ageValue.toString() == '1' ? 'year' : 'years'}';

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FBF9),

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                10,
                10,
                12,
                5,
              ),

              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    icon: const Icon(
                      Icons
                          .arrow_back_ios_new_rounded,
                      size: 20,
                      color:
                          Color(0xFF234C37),
                    ),
                  ),

                  const Expanded(
                    child: Text(
                      'Animal Profile',
                      style: TextStyle(
                        color:
                            Color(0xFF176B43),
                        fontSize: 21,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),

                  IconButton(
                    tooltip: 'Edit Animal',

                    onPressed:
                        _isDeleting
                            ? null
                            : _editAnimal,

                    icon: const Icon(
                      Icons.edit_outlined,
                      color:
                          Color(0xFF176B43),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(
                  22,
                  10,
                  22,
                  35,
                ),

                child: Column(
                  children: [
                    // ==========================================
                    // PHOTO
                    // ==========================================

                    Container(
                      width: 145,
                      height: 145,

                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFEAF7EF),

                        shape: BoxShape.circle,

                        border: Border.all(
                          color:
                              const Color(0xFFC5E8D2),
                          width: 3,
                        ),

                        boxShadow: const [
                          BoxShadow(
                            color:
                                Color(0x0D000000),
                            blurRadius: 15,
                            offset:
                                Offset(0, 5),
                          ),
                        ],
                      ),

                      child: ClipOval(
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit:
                                    BoxFit.cover,

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
                                      strokeWidth:
                                          2,
                                    ),
                                  );
                                },

                                errorBuilder: (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return const Icon(
                                    Icons
                                        .pets_rounded,
                                    size: 60,
                                    color:
                                        Color(0xFF24B86A),
                                  );
                                },
                              )
                            : const Icon(
                                Icons
                                    .pets_rounded,
                                size: 60,
                                color:
                                    Color(0xFF24B86A),
                              ),
                      ),
                    ),

                    const SizedBox(height: 17),

                    // ==========================================
                    // NAME
                    // ==========================================

                    Text(
                      name,

                      textAlign:
                          TextAlign.center,

                      style: const TextStyle(
                        color:
                            Color(0xFF1E3027),
                        fontSize: 24,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Animal ID: $animalTag',

                      style: const TextStyle(
                        color:
                            Color(0xFF7B8A82),
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _healthStatusTag(
                      healthStatus,
                    ),

                    const SizedBox(height: 27),

                    // ==========================================
                    // ANIMAL INFORMATION
                    // ==========================================

                    _sectionTitle(
                      'Animal Information',
                    ),

                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,

                      padding:
                          const EdgeInsets.all(
                              17),

                      decoration:
                          _cardDecoration(),

                      child: Column(
                        children: [
                          _informationRow(
                            icon:
                                Icons.pets_outlined,
                            label: 'Species',
                            value: species,
                          ),

                          _divider(),

                          _informationRow(
                            icon: Icons
                                .workspace_premium_outlined,
                            label: 'Breed',
                            value: breed,
                          ),

                          _divider(),

                          _informationRow(
                            icon: Icons
                                .calendar_month_outlined,
                            label: 'Age',
                            value: age,
                          ),

                          _divider(),

                          _informationRow(
                            icon: Icons
                                .transgender_rounded,
                            label: 'Gender',
                            value: gender,
                          ),

                          _divider(),

                          _informationRow(
                            icon: Icons
                                .cake_outlined,
                            label:
                                'Date of Birth',
                            value:
                                dateOfBirth,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==========================================
                    // HEALTH RECORDS
                    // ==========================================

                    _sectionTitle(
                      'Health & Medical',
                    ),

                    const SizedBox(height: 10),

                    Material(
                      color:
                          Colors.transparent,

                      child: InkWell(
                        onTap:
                            _openHealthRecords,

                        borderRadius:
                            BorderRadius.circular(
                                18),

                        child: Container(
                          width:
                              double.infinity,

                          padding:
                              const EdgeInsets.all(
                                  17),

                          decoration:
                              BoxDecoration(
                            color: const Color(
                                0xFFF0FAF4),

                            borderRadius:
                                BorderRadius.circular(
                                    18),

                            border:
                                Border.all(
                              color:
                                  const Color(
                                      0xFFCDEBD8),
                            ),

                            boxShadow: const [
                              BoxShadow(
                                color: Color(
                                    0x08000000),
                                blurRadius:
                                    10,
                                offset:
                                    Offset(0, 3),
                              ),
                            ],
                          ),

                          child: Row(
                            children: [
                              // ICON

                              Container(
                                width: 52,
                                height: 52,

                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(
                                          15),
                                ),

                                child:
                                    const Icon(
                                  Icons
                                      .medical_information_outlined,
                                  color:
                                      Color(0xFF20A961),
                                  size: 27,
                                ),
                              ),

                              const SizedBox(
                                  width: 14),

                              // TEXT

                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [
                                    Text(
                                      'Health Records',
                                      style:
                                          TextStyle(
                                        color:
                                            Color(0xFF205B3A),
                                        fontSize:
                                            15,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),

                                    SizedBox(
                                        height: 4),

                                    Text(
                                      'View vaccinations, treatments and medical history',
                                      style:
                                          TextStyle(
                                        color:
                                            Color(0xFF718078),
                                        fontSize:
                                            10.5,
                                        height:
                                            1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(
                                  width: 8),

                              const Icon(
                                Icons
                                    .chevron_right_rounded,
                                color:
                                    Color(0xFF54A978),
                                size: 27,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==========================================
                    // EDIT BUTTON
                    // ==========================================

                    SizedBox(
                      width: double.infinity,
                      height: 52,

                      child:
                          ElevatedButton.icon(
                        onPressed:
                            _isDeleting
                                ? null
                                : _editAnimal,

                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 19,
                        ),

                        label: const Text(
                          'Edit Animal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(
                                  0xFF24B86A),

                          foregroundColor:
                              Colors.white,

                          elevation: 0,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==========================================
                    // DELETE BUTTON
                    // ==========================================

                    SizedBox(
                      width: double.infinity,
                      height: 52,

                      child:
                          OutlinedButton.icon(
                        onPressed:
                            _isDeleting
                                ? null
                                : _confirmDelete,

                        icon: _isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,

                                child:
                                    CircularProgressIndicator(
                                  color:
                                      Color(0xFFE15B5B),
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .delete_outline_rounded,
                                size: 20,
                              ),

                        label: Text(
                          _isDeleting
                              ? 'Deleting...'
                              : 'Delete Animal',

                          style:
                              const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(
                                  0xFFE15B5B),

                          side:
                              const BorderSide(
                            color:
                                Color(0xFFE8BABA),
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
    String title,
  ) {
    return Align(
      alignment:
          Alignment.centerLeft,

      child: Text(
        title,

        style: const TextStyle(
          color:
              Color(0xFF285F42),
          fontSize: 15,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _informationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,

          decoration: BoxDecoration(
            color:
                const Color(0xFFEAF7EF),

            borderRadius:
                BorderRadius.circular(11),
          ),

          child: Icon(
            icon,
            size: 19,
            color:
                const Color(0xFF24B86A),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            label,

            style: const TextStyle(
              color:
                  Color(0xFF75837B),
              fontSize: 12,
            ),
          ),
        ),

        Flexible(
          child: Text(
            value,

            textAlign:
                TextAlign.right,

            style: const TextStyle(
              color:
                  Color(0xFF263B30),
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _divider() {
    return const Padding(
      padding:
          EdgeInsets.symmetric(
        vertical: 10,
      ),

      child: Divider(
        height: 1,
        color:
            Color(0xFFEDF2EF),
      ),
    );
  }

  // ============================================================
  // HEALTH STATUS TAG
  // ============================================================

  Widget _healthStatusTag(
    String status,
  ) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'need attention':
        backgroundColor =
            const Color(0xFFFFF1D8);
        textColor =
            const Color(0xFFD88719);
        icon =
            Icons.warning_amber_rounded;
        break;

      case 'under treatment':
        backgroundColor =
            const Color(0xFFFFE5E5);
        textColor =
            const Color(0xFFD75A5A);
        icon =
            Icons.medical_services_outlined;
        break;

      case 'healthy':
      default:
        backgroundColor =
            const Color(0xFFE0F7E8);
        textColor =
            const Color(0xFF159957);
        icon =
            Icons.check_circle_outline;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 7,
      ),

      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            BorderRadius.circular(25),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            icon,
            color: textColor,
            size: 15,
          ),

          const SizedBox(width: 6),

          Text(
            status,

            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD DECORATION
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,

      borderRadius:
          BorderRadius.circular(18),

      border: Border.all(
        color:
            const Color(0xFFE0E9E4),
      ),

      boxShadow: const [
        BoxShadow(
          color:
              Color(0x08000000),
          blurRadius: 10,
          offset:
              Offset(0, 3),
        ),
      ],
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
    String? date,
  ) {
    if (date == null ||
        date.isEmpty) {
      return 'Not provided';
    }

    try {
      final parsed =
          DateTime.parse(date);

      final day =
          parsed.day
              .toString()
              .padLeft(2, '0');

      final month =
          parsed.month
              .toString()
              .padLeft(2, '0');

      return '$day/$month/${parsed.year}';
    } catch (_) {
      return date;
    }
  }
}