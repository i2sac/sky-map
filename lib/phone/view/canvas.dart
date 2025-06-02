import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_map/astras/bloc/astra_bloc.dart';
import 'package:sky_map/astras/bloc/astra_state.dart';
import 'package:sky_map/astras/widgets/painter.dart';
import 'package:sky_map/phone/bloc/phone_bloc.dart';
import 'package:sky_map/phone/bloc/phone_state.dart';

class BlackCanvas extends StatelessWidget {
  const BlackCanvas({super.key});

  void _showPlanetInfo(BuildContext context, AstraPaintData astra) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              astra.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Altitude',
              value: '${astra.altitude.toStringAsFixed(2)}°',
            ),
            _InfoRow(
              label: 'Distance',
              value: '${(astra.distanceInKM / 1000000).toStringAsFixed(2)} millions km',
            ),
            _InfoRow(
              label: 'Diamètre',
              value: '${(astra.diameter / 1000).toStringAsFixed(0)} km',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhoneBloc, PhoneRotatedState>(
      builder: (context, phoneState) {
        double canvasRotation = atan2(phoneState.upVector.x, phoneState.upVector.y);
        
        return BlocBuilder<AstraBloc, AstraState>(
          builder: (context, astraState) {
            final painter = MyPainter(context, astraState, phoneState);
            
            return Stack(
              fit: StackFit.expand,  // Ajout pour s'assurer que le Stack remplit l'espace
              children: [
                // Le canvas principal avec rotation
                Transform.rotate(
                  angle: canvasRotation,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: painter,
                  ),
                ),
                // Les zones cliquables pour chaque planète
                ...painter.paintedAstras.map((astra) {
                  return Positioned(
                    left: astra.position.dx - astra.radius,
                    top: astra.position.dy - astra.radius,
                    child: GestureDetector(
                      onTap: () => _showPlanetInfo(context, astra),
                      behavior: HitTestBehavior.opaque,  // Ajout pour améliorer la détection des clics
                      child: Container(
                        width: astra.radius * 2,
                        height: astra.radius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  );
                }),
                // Les textes avec rotation inversée
                ...painter.paintedAstras.map((astra) {
                  return Positioned(
                    left: astra.position.dx - 40,
                    top: astra.position.dy + astra.radius + 5,
                    child: Transform.rotate(
                      angle: -canvasRotation,  // Contre-rotation pour garder le texte droit
                      child: GestureDetector(
                        onTap: () => _showPlanetInfo(context, astra),
                        child: SizedBox(
                          width: 80,
                          child: Text(
                            '${astra.name}\n${astra.altitude.toStringAsFixed(1)}°',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
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
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
