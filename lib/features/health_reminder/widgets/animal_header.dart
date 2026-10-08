import 'package:flutter/material.dart';

import '../models/models.dart';

class AnimalHeader extends StatelessWidget {
  final DemoAnimal animal;

  const AnimalHeader({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.brown[300], // Placeholder color
              // TODO: The animal image will later come from the real selected Animal data (Animal Management module).
              // child: Image.network(animal.imagePath, fit: BoxFit.cover),
              child: const Icon(Icons.pets, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        animal.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: animal.status.toLowerCase().contains('health')
                            ? Colors.green[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        animal.status,
                        style: TextStyle(
                          color: animal.status.toLowerCase().contains('health')
                              ? Colors.green[800]
                              : Colors.orange[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${animal.id}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'Species: ${animal.species}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'Breed: ${animal.breed}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'Age: ${animal.age} years',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'Gender: ${animal.gender}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
