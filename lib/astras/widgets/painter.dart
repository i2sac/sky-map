import 'dart:math';

import 'package:flutter/material.dart';
// import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart'; // Supprimé car non utilisé directement
import 'package:sky_map/astras/bloc/astra_state.dart';
// import 'package:sky_map/phone/bloc/phone_bloc.dart'; // Supprimé car non utilisé directement
import 'package:sky_map/phone/bloc/phone_state.dart';
import 'package:sky_map/astras/models/astra.dart'; // Importer Astra
import 'package:vector_math/vector_math_64.dart' as vm;

// Classe pour stocker les informations d'une zone cliquable
class ClickableAstraRegion {
  final Astra astra;
  final Rect rect;
  final Offset center;
  final double radius;

  ClickableAstraRegion({required this.astra, required this.rect, required this.center, required this.radius});
}

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

  // Liste pour stocker les régions cliquables des astres dessinés
  final List<ClickableAstraRegion> clickableRegions = [];
  // Callback pour quand un astre est cliqué
  final Function(Astra)? onAstraTapped;

  MyPainter(
    this.context,
    this.data,
    this.phoneState, {
    this.onAstraTapped, // Ajouter le callback au constructeur
  });

  @override
  bool shouldRepaint(MyPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.phoneState != phoneState ||
        oldDelegate.onAstraTapped != onAstraTapped;
  }

  @override
  void paint(Canvas canvas, Size size) {
    clickableRegions.clear(); // Vider les régions à chaque repaint
    double ox = size.width / 2;
    double oy = size.height / 2;

    canvas.save(); // Sauvegarder l'état du canvas avant la rotation

    // Appliquer la contre-rotation due au roll du téléphone
    // L'angle de roll est en degrés, convertir en radians pour la rotation du canvas.
    // Le centre de rotation est le centre du canvas (ox, oy).
    double rollRadians = radians(-phoneState.roll); // Inverser le roll pour la contre-rotation
    canvas.translate(ox, oy);
    canvas.rotate(rollRadians);
    canvas.translate(-ox, -oy);

    const double fovDegrees = 90.0;
    const double fovHalfDegrees = fovDegrees / 2.0;
    double scaleDegToPixX = size.width / fovDegrees;
    double scaleDegToPixY = size.height / fovDegrees;

    if (data.props.isNotEmpty) {
      final vm.Vector3 phoneX = vm.Vector3(
        phoneState.rightVector.x, phoneState.rightVector.y, phoneState.rightVector.z
      );
      final vm.Vector3 phoneY = vm.Vector3(
        phoneState.upVector.x, phoneState.upVector.y, phoneState.upVector.z
      );
      final vm.Vector3 phoneZ = vm.Vector3(
        phoneState.backVector.x, phoneState.backVector.y, phoneState.backVector.z
      );
      final vm.Matrix3 viewMatrix = vm.Matrix3.zero();
      viewMatrix.setRow(0, phoneX);
      viewMatrix.setRow(1, phoneY);
      viewMatrix.setRow(2, phoneZ);

      for (var astra in data.props) {
        if (astra.name == 'Earth') continue;

        double azRad = radians(astra.azimuth);
        double altRad = radians(astra.altitude);
        double distKm = astra.distanceInKM;
        double xWorld = distKm * cos(altRad) * sin(azRad);
        double yWorld = distKm * cos(altRad) * cos(azRad);
        double zWorld = distKm * sin(altRad);
        vm.Vector3 pWorld = vm.Vector3(xWorld, yWorld, zWorld);
        vm.Vector3 pCamera = viewMatrix.transform(pWorld);

        if (pCamera.z <= 0) {
          continue;
        }

        double angleHorizontalRad = atan2(pCamera.x, pCamera.z);
        double angleVerticalRad = atan2(pCamera.y, pCamera.z);
        double angleHorizontalDeg = angleHorizontalRad * 180 / pi;
        double angleVerticalDeg = angleVerticalRad * 180 / pi;

        if (angleHorizontalDeg.abs() > fovHalfDegrees || angleVerticalDeg.abs() > fovHalfDegrees) {
          continue;
        }

        double x = ox + angleHorizontalDeg * scaleDegToPixX;
        double y = oy - angleVerticalDeg * scaleDegToPixY;

        double planetDiameter = solarSystemPlanets[astra.name] ?? 0.0;
        double distanceToPlanet = pCamera.length;
        double apparentAngleRad = 2 * atan((planetDiameter / 2) / distanceToPlanet);
        double apparentSize = (apparentAngleRad * 180 / pi) * scale;
        apparentSize = apparentSize.clamp(10.0, 50.0);

        // Stocker la région cliquable
        // Le Rect doit être en coordonnées du canvas *avant* la rotation due au roll,
        // car le GestureDetector recevra les coordonnées du tap dans ce système.
        // Cependant, la détection de hit se fera sur les coordonnées transformées.
        // Pour simplifier, nous allons stocker les coordonnées X, Y (centre) et la taille APPARENTE (rayon)
        // telles qu'elles sont sur le canvas APRES la rotation de stabilisation.
        // Le GestureDetector devra transformer le point de contact inversement par le roll.
        Offset astraCenter = Offset(x,y);
        clickableRegions.add(
          ClickableAstraRegion(
            astra: astra,
            // Le Rect est utile pour un test rapide, mais le test cercle est plus précis
            rect: Rect.fromCircle(center: astraCenter, radius: apparentSize),
            center: astraCenter,
            radius: apparentSize
          )
        );

        canvas.drawCircle(
          astraCenter,
          apparentSize, // rayon
          Paint()
            ..color = planetColors[astra.name] ?? Colors.lightBlueAccent
            ..maskFilter = MaskFilter.blur(BlurStyle.solid, 5),
        );

        // // Affichage du nom (Supprimé comme demandé)
        // String displayText = '${astra.name}\n${astra.altitude.toStringAsFixed(1)}°';
        // if (astra.name == 'Sun' || astra.name == 'Moon') {
        //    displayText += '\nAz:${astra.azimuth.toStringAsFixed(1)}°';
        // }
        // TextPainter textPainter = TextPainter(
        //   text: TextSpan(
        //     text: displayText,
        //     style: TextStyle(color: Colors.white, fontSize: 12),
        //   ),
        //   textAlign: TextAlign.center,
        //   textDirection: TextDirection.ltr,
        // );
        // textPainter.layout();
        // textPainter.paint(
        //   canvas,
        //   Offset(x - textPainter.width / 2, y + apparentSize + 5),
        // );
      }
    }
    canvas.restore(); // Restaurer l'état du canvas
  }

  // Méthode pour vérifier si un point touche un astre
  // Le point est dans les coordonnées du canvas (après la rotation de stabilisation)
  Astra? getAstraAtPoint(Offset point) {
    // Le point est déjà dans le système de coordonnées du canvas rotaté.
    // Itérer en sens inverse pour que les objets dessinés en dernier (au-dessus) soient testés en premier.
    for (var region in clickableRegions.reversed) {
      // Test de distance par rapport au centre du cercle
      if ((point - region.center).distanceSquared <= region.radius * region.radius) {
        return region.astra;
      }
    }
    return null;
  }

  double radians(double degrees) {
    return degrees * pi / 180;
  }
}
