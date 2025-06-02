import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_map/astras/bloc/astra_bloc.dart';
import 'package:sky_map/astras/bloc/astra_state.dart';
import 'package:sky_map/astras/models/astra.dart';
import 'package:sky_map/astras/widgets/painter.dart';
import 'package:sky_map/phone/bloc/phone_bloc.dart';
import 'package:sky_map/phone/bloc/phone_state.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
// Importer le futur modal
import 'package:sky_map/astras/widgets/planet_info_modal.dart';

class BlackCanvas extends StatelessWidget {
  const BlackCanvas({super.key});

  // Copier les maps depuis MyPainter ou les rendre accessibles globalement/via le state
  // Pour l'instant, je vais les copier ici pour la logique de détection.
  // Idéalement, celles-ci pourraient être dans un service ou un état partagé.
  static const Map<String, double> solarSystemPlanets = {
    'Moon': 3474.8,
    'Mercury': 4879.4,
    'Venus': 12104.0,
    'Mars': 6779.0,
    'Jupiter': 139820.0,
    'Saturn': 116460.0,
    'Uranus': 50724.0,
    'Neptune': 49244.0,
    'Sun': 1392700.0,
  };
   static const Map<String, Color> planetColors = {
    'Mercury': Color(0xFF9F9F9F),
    'Venus': Color(0xFFE6E6BA),
    'Mars': Color(0xFFE67A50),
    'Jupiter': Color(0xFFF3D3A8),
    'Saturn': Color(0xFFEDD59F),
    'Uranus': Color(0xFF9FE3E3),
    'Neptune': Color(0xFF4B70DD),
    'Sun': Color(0xFFFFDF00),
    'Moon': Color(0xFFF4F6F0),
  };
  static const double scaleFactorForApparentSize = 100.0; // Le même 'scale' que dans MyPainter

  void _handleTap(BuildContext context, TapUpDetails details, AstraState astraState, PhoneRotatedState phoneState, Size screenSize) {
    final Offset tapPosition = details.localPosition;
    double ox = screenSize.width / 2;
    double oy = screenSize.height / 2;

    const double fovDegrees = 90.0;
    const double fovHalfDegrees = fovDegrees / 2.0;
    double scaleDegToPixX = screenSize.width / fovDegrees;
    double scaleDegToPixY = screenSize.height / fovDegrees;

    if (astraState.props.isNotEmpty) {
      final vm.Vector3 phoneX = vm.Vector3(phoneState.rightVector.x, phoneState.rightVector.y, phoneState.rightVector.z);
      final vm.Vector3 phoneY = vm.Vector3(phoneState.upVector.x, phoneState.upVector.y, phoneState.upVector.z);
      final vm.Vector3 phoneZ = vm.Vector3(phoneState.backVector.x, phoneState.backVector.y, phoneState.backVector.z);

      final vm.Matrix3 viewMatrix = vm.Matrix3.zero();
      viewMatrix.setRow(0, phoneX);
      viewMatrix.setRow(1, phoneY);
      viewMatrix.setRow(2, phoneZ);

      Astra? tappedAstra;

      for (var astra in astraState.astras) {
        if (astra.name == 'Earth') continue;

        double azRad = radians(astra.azimuth);
        double altRad = radians(astra.altitude);
        double distKm = astra.distanceInKM;

        double xWorld = distKm * cos(altRad) * sin(azRad);
        double yWorld = distKm * cos(altRad) * cos(azRad);
        double zWorld = distKm * sin(altRad);
        vm.Vector3 pWorld = vm.Vector3(xWorld, yWorld, zWorld);
        vm.Vector3 pCamera = viewMatrix.transform(pWorld);

        if (pCamera.z <= 0) continue;

        double angleHorizontalRad = atan2(pCamera.x, pCamera.z);
        double angleVerticalRad = atan2(pCamera.y, pCamera.z);
        double angleHorizontalDeg = angleHorizontalRad * 180 / pi;
        double angleVerticalDeg = angleVerticalRad * 180 / pi;

        if (angleHorizontalDeg.abs() > fovHalfDegrees || angleVerticalDeg.abs() > fovHalfDegrees) {
          continue;
        }

        double projectedX = ox + angleHorizontalDeg * scaleDegToPixX;
        double projectedY = oy - angleVerticalDeg * scaleDegToPixY;

        double planetDiameter = solarSystemPlanets[astra.name] ?? 0.0;
        double distanceToPlanet = pCamera.length;
        double apparentAngleRad = 2 * atan((planetDiameter / 2) / distanceToPlanet);
        double apparentSize = (apparentAngleRad * 180 / pi) * scaleFactorForApparentSize;
        apparentSize = apparentSize.clamp(10.0, 50.0);

        // Vérifier si le clic est dans le cercle de l'astre
        final double distanceToAstraCenter = (Offset(projectedX, projectedY) - tapPosition).distance;
        if (distanceToAstraCenter <= apparentSize) {
          tappedAstra = astra;
          break; // Prendre le premier astre trouvé (le plus en avant en cas de superposition)
        }
      }

      if (tappedAstra != null) {
        // Afficher le modal
        // Pour l'instant, un simple print, nous créerons le modal ensuite.
        // print('Tapped on: ${tappedAstra.name}');
        showDialog(
          context: context,
          builder: (_) => PlanetInfoModal(
              astra: tappedAstra!,
              planetColors: planetColors,
              solarSystemPlanets: solarSystemPlanets,
          ),
        );
      }
    }
  }

  double radians(double degrees) {
    return degrees * pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return BlocBuilder<PhoneBloc, PhoneRotatedState>(
      builder: (context, phoneState) {
        return BlocBuilder<AstraBloc, AstraState>(
          builder: (context, astraState) {
            return GestureDetector(
              onTapUp: (details) => _handleTap(context, details, astraState, phoneState, screenSize),
              child: CustomPaint(
                size: Size.infinite, // ou screenSize pour être plus précis
                painter: MyPainter(context, astraState, phoneState),
              ),
            );
          },
        );
      },
    );
  }
}
