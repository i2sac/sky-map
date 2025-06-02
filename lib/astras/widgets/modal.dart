import 'package:flutter/material.dart';

class PlanetModal extends StatelessWidget {
  final String name;
  final double altitude;
  final double distanceInKM;
  final double diameter;
  final Color color;

  const PlanetModal({
    required this.name,
    required this.altitude,
    required this.distanceInKM,
    required this.diameter,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Altitude', value: '${altitude.toStringAsFixed(2)}°'),
          _InfoRow(
            label: 'Distance',
            value: '${(distanceInKM / 1000000).toStringAsFixed(2)} millions km',
          ),
          _InfoRow(
            label: 'Diamètre',
            value: '${(diameter / 1000).toStringAsFixed(0)} km',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}