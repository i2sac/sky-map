import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:sky_map/astras/bloc/astra_state.dart';
import 'package:sky_map/phone/bloc/phone_bloc.dart';
import 'package:sky_map/phone/bloc/phone_state.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

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
    double ox = size.width / 2;
    double oy = size.height / 2;

    // Champ de vision
    const double fovDegrees = 90.0;
    const double fovHalfDegrees = fovDegrees / 2.0;

    // Échelles pour convertir les degrés d'angle de vue en pixels sur l'écran
    double scaleDegToPixX = size.width / fovDegrees;
    double scaleDegToPixY = size.height / fovDegrees;

    if (data.props.isNotEmpty) {
      // Les vecteurs du téléphone sont déjà dans le référentiel du monde.
      // rightVector = X du téléphone dans le monde
      // upVector    = Y du téléphone dans le monde
      // backVector  = Z du téléphone dans le monde (pointe vers l'arrière)

      // La matrice de rotation du téléphone (monde -> téléphone) est formée
      // par les vecteurs des axes du téléphone comme lignes.
      final vm.Vector3 phoneX = vm.Vector3(
        phoneState.rightVector.x, phoneState.rightVector.y, phoneState.rightVector.z
      );
      final vm.Vector3 phoneY = vm.Vector3(
        phoneState.upVector.x, phoneState.upVector.y, phoneState.upVector.z
      );
      final vm.Vector3 phoneZ = vm.Vector3(
        phoneState.backVector.x, phoneState.backVector.y, phoneState.backVector.z
      );

      // Matrice pour transformer du monde vers les coordonnées du téléphone (View Matrix)
      // Si R est la matrice dont les colonnes sont les axes du téléphone dans le monde,
      // alors R transpose transforme du monde vers le téléphone.
      // Ici, phoneX, phoneY, phoneZ sont déjà des vecteurs lignes pour la matrice inverse.
      final vm.Matrix3 viewMatrix = vm.Matrix3.zero();
      viewMatrix.setRow(0, phoneX); // L'axe X du téléphone devient la première ligne
      viewMatrix.setRow(1, phoneY); // L'axe Y du téléphone devient la deuxième ligne
      viewMatrix.setRow(2, phoneZ); // L'axe Z du téléphone (arrière) devient la troisième ligne

      for (var astra in data.props) {
        if (astra.name == 'Earth') continue;

        // 1. Coordonnées de l'astre dans le système du monde (Est, Nord, Zénith)
        double azRad = radians(astra.azimuth); // Azimut: Est=0, Nord=90, Ouest=180, Sud=270
        double altRad = radians(astra.altitude); // Altitude
        double distKm = astra.distanceInKM;

        // Conversion en coordonnées cartésiennes du monde
        // X = Est, Y = Nord, Z = Zénith
        // Azimut 0 (Est): sin(0)=0, cos(0)=1 -> (0, dist*cos(alt), dist*sin(alt))
        // Azimut 90 (Nord): sin(pi/2)=1, cos(pi/2)=0 -> (dist*cos(alt), 0, dist*sin(alt))
        // Il semble y avoir une convention commune où: X pointe vers le Nord, Y vers l'Est, Z vers le Zénith
        // Ou X vers l'Est, Y vers le Nord, Z vers le Zénith. Votre code initial pour xWorld, yWorld:
        // double xWorld = distKm * cos(altRad) * sin(azRad); // Est
        // double yWorld = distKm * cos(altRad) * cos(azRad); // Nord
        // double zWorld = distKm * sin(altRad);             // Zénith
        // Cela semble correct: azimut 0 (Est) => sin(azRad)=0, cos(azRad)=1 => xWorld=0, yWorld = distKm*cos(altRad)
        // NON, si Azimut 0 est Est: sin(0)=0 (pour X), cos(0)=1 (pour Y)
        // Si on veut X=Est, Y=Nord, Z=Zénith:
        // xWorld = distKm * cos(altRad) * cos(astra.azimuth - 90) // ou sin(azimuth) si azimut est de l'axe Y (Nord)
        // yWorld = distKm * cos(altRad) * sin(astra.azimuth - 90)
        // Utilisons la convention: X: Est, Y: Nord, Z: Zénith
        double xWorld = distKm * cos(altRad) * sin(azRad); // Devrait être Est
        double yWorld = distKm * cos(altRad) * cos(azRad); // Devrait être Nord
        double zWorld = distKm * sin(altRad);             // Zénith

        vm.Vector3 pWorld = vm.Vector3(xWorld, yWorld, zWorld);

        // 2. Transformer en coordonnées de la caméra/téléphone
        vm.Vector3 pCamera = viewMatrix.transform(pWorld);

        // Les coordonnées pCamera sont maintenant dans le repère du téléphone:
        // pCamera.x: coordonnée le long de l'axe "droite" du téléphone
        // pCamera.y: coordonnée le long de l'axe "haut" du téléphone
        // pCamera.z: coordonnée le long de l'axe "arrière" du téléphone (pointe hors de l'écran)

        // 3. Vérifier si l'astre est devant la "caméra" (càd, a une coordonnée Z positive dans le repère du téléphone)
        // Puisque notre axe Z du téléphone (phoneZ / pCamera.z) pointe vers l'arrière,
        // les objets DEVANT la caméra (dans la direction du dos du tel) auront pCamera.z > 0.
        if (pCamera.z <= 0) {
          continue; // L'astre est derrière l'écran du téléphone
        }

        // 4. Calculer les angles de vue par rapport à l'axe de visée du téléphone (Z de la caméra)
        // L'axe de visée est l'axe Z positif de la caméra (pCamera.z).
        // Angle horizontal: atan2(pCamera.x, pCamera.z)
        // Angle vertical:   atan2(pCamera.y, pCamera.z)
        double angleHorizontalRad = atan2(pCamera.x, pCamera.z);
        double angleVerticalRad = atan2(pCamera.y, pCamera.z);

        double angleHorizontalDeg = angleHorizontalRad * 180 / pi;
        double angleVerticalDeg = angleVerticalRad * 180 / pi;

        // 5. Vérifier si dans le champ de vision
        if (angleHorizontalDeg.abs() > fovHalfDegrees || angleVerticalDeg.abs() > fovHalfDegrees) {
          continue;
        }

        // 6. Calculer les coordonnées sur l'écran
        // L'axe X positif de la caméra (pCamera.x) correspond à la droite de l'écran.
        // L'axe Y positif de la caméra (pCamera.y) correspond au haut de l'écran.
        // Le canvas a (0,0) en haut à gauche, Y augmente vers le bas.
        double x = ox + angleHorizontalDeg * scaleDegToPixX;
        double y = oy - angleVerticalDeg * scaleDegToPixY; // Inversion pour l'axe Y du canvas

        // 7. Calcul de la taille apparente
        double planetDiameter = solarSystemPlanets[astra.name] ?? 0.0;
        double distanceToPlanet = pCamera.length; // Distance réelle de la caméra à la planète
        double apparentAngleRad = 2 * atan((planetDiameter / 2) / distanceToPlanet);
        double apparentSize = (apparentAngleRad * 180 / pi) * scale;
        apparentSize = apparentSize.clamp(10.0, 50.0);

        // 8. Dessin de l'astre
        canvas.drawCircle(
          Offset(x, y),
          apparentSize,
          Paint()
            ..color = planetColors[astra.name] ?? Colors.lightBlueAccent
            ..maskFilter = MaskFilter.blur(BlurStyle.solid, 5),
        );

        // Affichage du nom
        String displayText = '${astra.name}\n${astra.altitude.toStringAsFixed(1)}°';
        if (astra.name == 'Sun' || astra.name == 'Moon') {
           displayText += '\nAz:${astra.azimuth.toStringAsFixed(1)}°';
        }

        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: displayText,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y + apparentSize + 5),
        );
      }
    }
  }

  double radians(double degrees) {
    return degrees * pi / 180;
  }
}
