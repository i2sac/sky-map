import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sky_map/astras/bloc/astra_state.dart';

class MyPainter extends CustomPainter {
  final BuildContext context;
  final AstraState data;
  final double phoneAzimuth; // Azimut du téléphone
  final double phonePitch; // Inclinaison verticale
  final double phoneRoll; // Rotation
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

  MyPainter(
    this.context,
    this.data,
    this.phoneAzimuth,
    this.phonePitch,
    this.phoneRoll,
  );

  @override
  bool shouldRepaint(MyPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.phoneAzimuth != phoneAzimuth ||
        oldDelegate.phonePitch != phonePitch ||
        oldDelegate.phoneRoll != phoneRoll;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Point central de l'écran
    double ox = MediaQuery.of(context).size.width / 2;
    double oy = MediaQuery.of(context).size.height / 2;

    // Facteur d'échelle pour convertir les degrés en pixels
    // Un champ de vision de 90° correspondra à la largeur/hauteur de l'écran
    double scaleX = MediaQuery.of(context).size.width / 90.0;
    double scaleY = MediaQuery.of(context).size.height / 90.0;

    if (data.props.isNotEmpty) {
      for (var astra in data.props) {
        if (astra.name == 'Earth') continue;

        // 1. Calculer la position relative par rapport à l'orientation du téléphone
        double relativeAz = astra.azimuth - phoneAzimuth;
        double relativeAlt = astra.altitude - phonePitch;

        // Normaliser l'azimut entre -180° et +180°
        if (relativeAz > 180) relativeAz -= 360;
        if (relativeAz < -180) relativeAz += 360;

        // 2. Convertir les coordonnées sphériques en coordonnées cartésiennes
        // L'azimut détermine la position X, l'altitude détermine la position Y
        double x = ox + (relativeAz * scaleX * cos(radians(relativeAlt)));
        double y = oy - (relativeAlt * scaleY);

        // 3. Appliquer la rotation du téléphone (roll)
        double rotatedX = ox + (x - ox) * cos(radians(phoneRoll)) - (y - oy) * sin(radians(phoneRoll));
        double rotatedY = oy + (x - ox) * sin(radians(phoneRoll)) + (y - oy) * cos(radians(phoneRoll));

        // 4. Calculer la taille apparente en utilisant l'angle sous-tendu
        double planetDiameter = solarSystemPlanets[astra.name] ?? 0.0;
        double distanceKm = astra.distanceInKM;
        // Formule : angle = 2 * arctan(rayon / distance)
        double apparentAngle = 2 * atan((planetDiameter/2) / distanceKm);
        // Convertir l'angle en degrés et ajuster l'échelle
        double apparentSize = (apparentAngle * 180 / pi) * scale;
        // Limiter la taille pour ne pas avoir d'objets trop grands ou trop petits
        apparentSize = apparentSize.clamp(2.0, 50.0);

        // 5. Dessiner l'astre seulement s'il est dans le champ de vision
        if (relativeAz.abs() <= 90 && relativeAlt.abs() <= 90) {
            canvas.drawCircle(
                Offset(rotatedX, rotatedY),
                apparentSize,
                Paint()
                    ..color = planetColors[astra.name] ?? Colors.lightBlueAccent
                    ..maskFilter = MaskFilter.blur(BlurStyle.solid, 5),
            );

            // Afficher le nom
            TextPainter textPainter = TextPainter(
                text: TextSpan(
                    text: astra.name,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                textDirection: TextDirection.ltr,
            );
            textPainter.layout();
            textPainter.paint(canvas, 
                Offset(rotatedX - textPainter.width/2, rotatedY + apparentSize + 5));
        }
      }
    }

    // canvas.drawCircle(
    //   Offset(ox, oy),
    //   8,
    //   Paint()
    //     ..color = Colors.lightBlueAccent
    //     ..maskFilter = MaskFilter.blur(BlurStyle.solid, 5),
    // );
  }

  double radians(double degrees) {
    return degrees * pi / 180;
  }
}
