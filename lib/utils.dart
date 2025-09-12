import 'dart:math';
import 'dart:ui';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sky_map/astras/models/astra.dart';
import 'package:sky_map/phone/bloc/phone_state.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

final Map<String, Color> planetColors = {
  'Mercury': Color(0xFF9F9F9F), // Gris métallique
  'Venus': Color(0xFFE6E6BA), // Jaune pâle
  'Mars': Color(0xFFE67A50), // Rouge-orange rouillé
  'Jupiter': Color(0xFFF3D3A8), // Beige strié
  'Saturn': Color(0xFFEDD59F), // Jaune doré
  'Uranus': Color(0xFF9FE3E3), // Bleu-vert glacé
  'Neptune': Color(0xFF4B70DD), // Bleu profond
  'Sun': Color(0xFFFFDF00), // Jaune solaire
  'Moon': Color(0xFFF4F6F0), // Blanc lunaire
};

final Map<String, double> solarSystemPlanets = {
  'Moon': 3474.8, // Diamètre en km
  'Mercury': 4879.4,
  'Venus': 12104.0,
  'Mars': 6779.0,
  'Jupiter': 139820.0,
  'Saturn': 116460.0, // Diamètre sans les anneaux
  'Uranus': 50724.0,
  'Neptune': 49244.0,
  'Sun': 1392700.0, // Ajout du Soleil
};

/// Exemple de fonction pour calculer l'heure sidérale locale (approximation)
double calculateLST(DateTime date, double longitude) {
  // Cette formule est simplifiée.
  // Vous pouvez consulter des formules plus précises.
  final JD = date.millisecondsSinceEpoch / 86400000 + 2440587.5; // Julian Date
  final T = (JD - 2451545.0) / 36525.0;
  // GMST en degrés (formule approchée)
  final GMST =
      280.46061837 +
      360.98564736629 * (JD - 2451545) +
      T * T * 0.000387933 -
      T * T * T / 38710000;
  // LST
  double LST = (GMST + longitude) % 360;
  if (LST < 0) LST += 360;
  return LST;
}

/// Conversion de RA/dec en altitude et azimut.
Map<String, double> equatorialToHorizontal({
  required double raDeg, // en degrés
  required double decDeg, // en degrés
  required DateTime date,
  required double latitude, // en degrés
  required double longitude, // en degrés
}) {
  // Calcul de l'heure sidérale locale en degrés
  double LSTDeg = calculateLST(date, longitude);
  // Calcul de l'angle horaire en degrés
  double HADeg = LSTDeg - raDeg;
  // Normalisation de l'angle horaire
  HADeg = HADeg % 360;
  if (HADeg > 180) HADeg -= 360;

  // Conversion en radians
  double decRad = degToRad(decDeg);
  double latRad = degToRad(latitude);
  double HARad = degToRad(HADeg);

  // Calcul de l'altitude
  double altRad = asin(
    sin(decRad) * sin(latRad) + cos(decRad) * cos(latRad) * cos(HARad),
  );
  // Calcul de l'azimut
  double azRad = atan2(
    sin(HARad),
    cos(HARad) * sin(latRad) - tan(decRad) * cos(latRad),
  );
  // Ajustement de l'azimut pour obtenir une valeur entre 0 et 360 degrés
  double azDeg = (radToDeg(azRad) + 360) % 360;
  double altDeg = radToDeg(altRad);

  return {'alt': altDeg, 'az': azDeg};
}

List<dynamic> parseConstellationsCoords(
  List<dynamic> constellations,
  lat,
  long,
) {
  for (var constellation in constellations) {
    var newCoords = [];
    for (var figure in constellation['coordinates']) {
      List<dynamic> path = [];
      for (var star in figure) {
        double ra = star[0]; // Ascension droite en degrés
        double dec = star[1]; // Déclinaison en degrés
        var result = equatorialToHorizontal(
          raDeg: ra,
          decDeg: dec,
          date: DateTime.now().toUtc(),
          latitude: lat,
          longitude: long,
        );
        path.add([result['alt'], result['az']]);
      }
      newCoords.add(path);
    }
    constellation['coordinates'] = newCoords;
  }

  return constellations;
}

(double, double, double, double, double, vm.Matrix3) viewConfigs(
  Size size,
  PhoneRotatedState phoneRotatedState,
) {
  double ox = size.width / 2;
  double oy = size.height / 2;

  // Champ de vision
  const double fovDegrees = 90.0;
  const double fovHalfDegrees = fovDegrees / 2.0;

  // Échelles pour convertir les degrés d'angle de vue en pixels sur l'écran
  double scaleDegToPixX = size.width / fovDegrees;
  double scaleDegToPixY = size.height / fovDegrees;

  // Les vecteurs du téléphone sont déjà dans le référentiel du monde.
  // rightVector = X du téléphone dans le monde
  // upVector    = Y du téléphone dans le monde
  // backVector  = Z du téléphone dans le monde (pointe vers l'arrière)

  // La matrice de rotation du téléphone (monde -> téléphone) est formée
  // par les vecteurs des axes du téléphone comme lignes.
  final vm.Vector3 phoneX = vm.Vector3(
    phoneRotatedState.rightVector.x,
    phoneRotatedState.rightVector.y,
    phoneRotatedState.rightVector.z,
  );
  final vm.Vector3 phoneY = vm.Vector3(
    phoneRotatedState.upVector.x,
    phoneRotatedState.upVector.y,
    phoneRotatedState.upVector.z,
  );
  final vm.Vector3 phoneZ = vm.Vector3(
    phoneRotatedState.backVector.x,
    phoneRotatedState.backVector.y,
    phoneRotatedState.backVector.z,
  );

  // Matrice pour transformer du monde vers les coordonnées du téléphone (View Matrix)
  // Si R est la matrice dont les colonnes sont les axes du téléphone dans le monde,
  // alors R transpose transforme du monde vers le téléphone.
  // Ici, phoneX, phoneY, phoneZ sont déjà des vecteurs lignes pour la matrice inverse.
  final vm.Matrix3 viewMatrix = vm.Matrix3.zero();
  viewMatrix.setRow(
    0,
    phoneX,
  ); // L'axe X du téléphone devient la première ligne
  viewMatrix.setRow(
    1,
    phoneY,
  ); // L'axe Y du téléphone devient la deuxième ligne
  viewMatrix.setRow(
    2,
    phoneZ,
  ); // L'axe Z du téléphone (arrière) devient la troisième ligne

  return (ox, oy, fovHalfDegrees, scaleDegToPixX, scaleDegToPixY, viewMatrix);
}

double degToRad(double degrees) {
  return degrees * pi / 180;
}

double radToDeg(double radians) {
  return radians * 180 / pi;
}

(double?, double?, double?) astraCoordsOnCanvas(
  Astra astra,
  double ox,
  double oy,
  double fovHalfDegrees,
  double scaleDegToPixX,
  double scaleDegToPixY,
  vm.Matrix3 viewMatrix,
) {
  // 1. Coordonnées de l'astre dans le système du monde (Est, Nord, Zénith)
  double azRad = degToRad(
    astra.azimuth,
  ); // Azimut: Est=0, Nord=90, Ouest=180, Sud=270
  double altRad = degToRad(astra.altitude); // Altitude
  double distKm = astra.distanceInKM;

  // Conversion en coordonnées cartésiennes du monde
  // X = Est, Y = Nord, Z = Zénith
  // Azimut 0 (Est): sin(0)=0, cos(0)=1 -> (0, dist*cos(alt), dist*sin(alt))
  // Azimut 90 (Nord): sin(pi/2)=1, cos(pi/2)=0 -> (dist*cos(alt), 0, dist*sin(alt))
  // Il y a une convention commune où: X pointe vers le Nord, Y vers l'Est, Z vers le Zénith
  double xWorld = distKm * cos(altRad) * sin(azRad); // Est
  double yWorld = distKm * cos(altRad) * cos(azRad); // Nord
  double zWorld = distKm * sin(altRad); // Zénith

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
    return (null, null, null); // L'astre est derrière l'écran du téléphone
  }

  // 4. Calculer les angles de vue par rapport à l'axe de visée du téléphone (Z de la caméra)
  // L'axe de visée est l'axe Z positif de la caméra (pCamera.z).
  // Angle horizontal: atan2(pCamera.x, pCamera.z)
  // Angle vertical:   atan2(pCamera.y, pCamera.z)
  double angleHorizontalDeg = radToDeg(atan2(pCamera.x, pCamera.z));
  double angleVerticalDeg = radToDeg(atan2(pCamera.y, pCamera.z));

  // 5. Vérifier si dans le champ de vision
  if (angleHorizontalDeg.abs() > fovHalfDegrees ||
      angleVerticalDeg.abs() > fovHalfDegrees) {
    return (null, null, null);
  }

  // 6. Calculer les coordonnées sur l'écran
  // L'axe X positif de la caméra (pCamera.x) correspond à la droite de l'écran.
  // L'axe Y positif de la caméra (pCamera.y) correspond au haut de l'écran.
  // Le canvas a (0,0) en haut à gauche, Y augmente vers le bas.
  double x = ox + angleHorizontalDeg * scaleDegToPixX;
  double y =
      oy -
      angleVerticalDeg * scaleDegToPixY; // Inversion pour l'axe Y du canvas

  // 7. Calcul de la taille apparente
  double planetDiameter = solarSystemPlanets[astra.name] ?? 0.0;
  double distanceToPlanet =
      pCamera.length; // Distance réelle de la caméra à la planète
  double apparentAngleRad = 2 * atan((planetDiameter / 2) / distanceToPlanet);
  double scale = double.tryParse(dotenv.env['SCALE'] ?? '100.0') ?? 100.0;
  double apparentSize = (apparentAngleRad * 180 / pi) * scale;
  apparentSize = apparentSize.clamp(10.0, 60.0);
  return (x, y, apparentSize);
}

(double?, double?, double?) constellationPoint(
  double alt,
  double az,
  String constellation,
  double ox,
  double oy,
  double fovHalfDegrees,
  double scaleDegToPixX,
  double scaleDegToPixY,
  vm.Matrix3 viewMatrix,
) {
  Astra astra = Astra(
    name: 'Star',
    distanceAU: 20,
    distanceKM: 999999999,
    altitude: alt,
    azimuth: az,
    constellation: constellation,
    magnitude: 0,
  );

  return astraCoordsOnCanvas(
    astra,
    ox,
    oy,
    fovHalfDegrees,
    scaleDegToPixX,
    scaleDegToPixY,
    viewMatrix,
  );
}
