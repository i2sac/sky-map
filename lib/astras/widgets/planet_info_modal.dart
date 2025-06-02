import 'package:flutter/material.dart';
import 'package:sky_map/astras/models/astra.dart';

class PlanetInfoModal extends StatelessWidget {
  final Astra astra;
  final Map<String, Color> planetColors;
  final Map<String, double> solarSystemPlanets;

  const PlanetInfoModal({
    super.key,
    required this.astra,
    required this.planetColors,
    required this.solarSystemPlanets,
  });

  @override
  Widget build(BuildContext context) {
    final Color astraColor = planetColors[astra.name] ?? Colors.grey;
    final double? diameterKm = solarSystemPlanets[astra.name];

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      title: Text(
        astra.name,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: astraColor,
                // Vous pourriez ajouter une image/texture ici plus tard
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Altitude:', '${astra.altitude.toStringAsFixed(2)}°'),
            _buildInfoRow('Azimuth:', '${astra.azimuth.toStringAsFixed(2)}°'),
            _buildInfoRow('Distance (KM):', '${astra.distanceInKM.toStringAsFixed(0)} km'),
            _buildInfoRow('Distance (AU):', '${astra.distanceAU.toStringAsFixed(0)} AU'),
            if (diameterKm != null)
              _buildInfoRow('Diamètre:', '${diameterKm.toStringAsFixed(0)} km'),
            // Ajoutez d'autres informations si nécessaire
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Fermer', style: TextStyle(color: Colors.amberAccent)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
} 