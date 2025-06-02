import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sky_map/astras/bloc/astra_state.dart';
import 'package:sky_map/phone/bloc/phone_state.dart';

class MyPainter extends CustomPainter {
  final BuildContext context;
  final AstraState data;
  final PhoneRotatedState phoneState;
  final double scale = 100.0; // Scaling factor for apparent size
  final Map<String, double> solarSystemPlanets = {
    'Moon': 3474.8,      // Diamètre en km
    'Mercury': 4879.4,
    'Venus': 12104.0,
    'Mars': 6779.0,
    'Jupiter': 139820.0,
    'Saturn': 116460.0,   // Diamètre sans les anneaux
    'Uranus': 50724.0,
    'Neptune': 49244.0,
    'Sun': 1392700.0,    // Ajout du Soleil
  };

  final Map<String, Color> planetColors = {
    'Mercury': Color(0xFF9F9F9F),   // Gris métallique
    'Venus': Color(0xFFE6E6BA),     // Jaune pâle
    'Mars': Color(0xFFE67A50),      // Rouge-orange rouillé
    'Jupiter': Color(0xFFF3D3A8),   // Beige strié
    'Saturn': Color(0xFFEDD59F),    // Jaune doré
    'Uranus': Color(0xFF9FE3E3),    // Bleu-vert glacé
    'Neptune': Color(0xFF4B70DD),   // Bleu profond
    'Sun': Color(0xFFFFDF00),       // Jaune solaire
    'Moon': Color(0xFFF4F6F0),      // Blanc lunaire
  };

  final List<AstraPaintData> paintedAstras = [];

  MyPainter(
    this.context,
    this.data,
    this.phoneState,
  );

  @override
  bool shouldRepaint(MyPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.phoneState != phoneState;
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintedAstras.clear();
    double ox = size.width / 2;
    double oy = size.height / 2;

    // Facteur d'échelle pour le champ de vision
    double scaleX = size.width / 90.0;  // 90° de champ de vision horizontal
    double scaleY = size.height / 90.0; // 90° de champ de vision vertical

    if (data.props.isNotEmpty) {
      for (var astra in data.props) {
        if (astra.name == 'Earth') continue;

        // Calcul des positions relatives
        double relativeAz = astra.azimuth - phoneState.azimuth;
        double relativeAlt = astra.altitude - phoneState.altitude;

        // Normalisation de l'azimuth
        if (relativeAz > 180) relativeAz -= 360;
        if (relativeAz < -180) relativeAz += 360;

        // Conversion en coordonnées cartésiennes
        double x = ox + relativeAz * scaleX;
        double y = oy - relativeAlt * scaleY;

        // Calcul de la taille apparente
        double planetDiameter = solarSystemPlanets[astra.name] ?? 0.0;
        double distanceKm = astra.distanceInKM;
        double apparentAngle = 2 * atan((planetDiameter/2) / distanceKm);
        double apparentSize = (apparentAngle * 180 / pi) * scale;
        apparentSize = apparentSize.clamp(10.0, 50.0);

        // Affichage si dans le champ de vision
        if (relativeAz.abs() <= 45 && relativeAlt.abs() <= 45) {
          // Dessin de l'astre
          canvas.drawCircle(
            Offset(x, y),
            apparentSize,
            Paint()
              ..color = planetColors[astra.name] ?? Colors.lightBlueAccent
              ..maskFilter = MaskFilter.blur(BlurStyle.solid, 5),
          );

          // Stockage des données pour l'interactivité
          paintedAstras.add(AstraPaintData(
            name: astra.name,
            position: Offset(x, y),
            radius: apparentSize,
            altitude: astra.altitude,
            distanceInKM: astra.distanceInKM,
            diameter: solarSystemPlanets[astra.name] ?? 0.0,
            color: planetColors[astra.name] ?? Colors.lightBlueAccent,
          ));
        }
      }
    }
  }

  double radians(double degrees) {
    return degrees * pi / 180;
  }
}

class AstraPaintData {
  final String name;
  final Offset position;
  final double radius;
  final double altitude;
  final double distanceInKM;
  final double diameter;
  final Color color;

  AstraPaintData({
    required this.name,
    required this.position,
    required this.radius,
    required this.altitude,
    required this.distanceInKM,
    required this.diameter,
    required this.color,
  });
}
