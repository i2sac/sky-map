import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart'
    show Vector3;
import 'package:sky_map/astras/bloc/astra_bloc.dart';
import 'package:sky_map/astras/bloc/astra_state.dart';
import 'package:sky_map/astras/models/astra.dart';
import 'package:sky_map/astras/widgets/painter.dart';
import 'package:sky_map/phone/bloc/phone_bloc.dart';
import 'package:sky_map/phone/bloc/phone_state.dart';
import 'package:sky_map/utils.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
// Importer le futur modal
import 'package:sky_map/astras/widgets/planet_info_modal.dart';

class BlackCanvas extends StatefulWidget {
  const BlackCanvas({super.key});

  @override
  State<BlackCanvas> createState() => _BlackCanvasState();
}

class _BlackCanvasState extends State<BlackCanvas> {
  PhonePositionState? _lastPosition;

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

  void _handleTap(
    BuildContext context,
    TapUpDetails details,
    AstraState astraState,
    PhoneRotatedState phoneState,
    Size screenSize,
  ) {
    if (astraState.props.isEmpty) {
      return;
    }

    final Offset tapPosition = details.localPosition;
    double ox, oy, fovHalfDegrees, scaleDegToPixX, scaleDegToPixY;
    vm.Matrix3 viewMatrix;

    (
      ox,
      oy,
      fovHalfDegrees,
      scaleDegToPixX,
      scaleDegToPixY,
      viewMatrix,
    ) = viewConfigs(screenSize, phoneState);

    Astra? tappedAstra;
    double? tappedRawSize; // apparent size before clamp, for better ordering
    double? tappedHitDistance; // distance from tap to center
    double? tappedDepth; // distance to camera for tie-break
    const double eps = 1e-3;

    for (var astra in astraState.astras) {
      if (astra.name == 'Earth') continue;

      double azRad = degToRad(astra.azimuth);
      double altRad = degToRad(astra.altitude);
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

      if (angleHorizontalDeg.abs() > fovHalfDegrees ||
          angleVerticalDeg.abs() > fovHalfDegrees) {
        continue;
      }

      double projectedX = ox + angleHorizontalDeg * scaleDegToPixX;
      double projectedY = oy - angleVerticalDeg * scaleDegToPixY;

      double planetDiameter = solarSystemPlanets[astra.name] ?? 0.0;
      double distanceToPlanet = pCamera.length;
      double apparentAngleRad =
          2 * atan((planetDiameter / 2) / distanceToPlanet);
      // raw on-screen size before clamp (use same scale as painter/config)
      final double scale = double.parse(dotenv.env['SCALE'] ?? '100.0');
      double rawApparentSize = (apparentAngleRad * 180 / pi) * scale;
      double apparentSize = rawApparentSize.clamp(10.0, 50.0);

      // Vérifier si le clic est dans le cercle de l'astre
      final double distanceToAstraCenter =
          (Offset(projectedX, projectedY) - tapPosition).distance;
      if (distanceToAstraCenter <= apparentSize) {
        if (tappedRawSize == null) {
          tappedRawSize = rawApparentSize;
          tappedHitDistance = distanceToAstraCenter;
          tappedDepth = distanceToPlanet;
          tappedAstra = astra;
        } else {
          // Prefer the smallest on-screen size
          if (rawApparentSize + eps < tappedRawSize!) {
            tappedRawSize = rawApparentSize;
            tappedHitDistance = distanceToAstraCenter;
            tappedDepth = distanceToPlanet;
            tappedAstra = astra;
          } else if ((rawApparentSize - tappedRawSize!).abs() <= eps) {
            // Tie-breaker 1: closer to tap center
            if (distanceToAstraCenter + eps <
                (tappedHitDistance ?? double.infinity)) {
              tappedRawSize = rawApparentSize;
              tappedHitDistance = distanceToAstraCenter;
              tappedDepth = distanceToPlanet;
              tappedAstra = astra;
            } else if ((distanceToAstraCenter -
                        (tappedHitDistance ?? double.infinity))
                    .abs() <=
                eps) {
              // Tie-breaker 2: the one closer to the camera (on top)
              if (distanceToPlanet + eps < (tappedDepth ?? double.infinity)) {
                tappedRawSize = rawApparentSize;
                tappedHitDistance = distanceToAstraCenter;
                tappedDepth = distanceToPlanet;
                tappedAstra = astra;
              }
            }
          }
        }
      }
    }

    if (tappedAstra != null) {
      showDialog(
        context: context,
        builder:
            (_) => PlanetInfoModal(
              astra: tappedAstra!,
              planetColors: planetColors,
              solarSystemPlanets: solarSystemPlanets,
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return BlocListener<PhoneBloc, PhoneState>(
      listenWhen: (prev, curr) => curr is PhonePositionState,
      listener: (context, state) {
        if (state is PhonePositionState) {
          _lastPosition = state; // cache la dernière position valide
        }
      },
      child: BlocBuilder<PhoneBloc, PhoneState>(
        builder: (context, phoneState) {
          // État d'orientation (toujours disponible à ~60Hz)
          final phoneRotatedState =
              phoneState is PhoneRotatedState
                  ? phoneState
                  : PhoneRotatedState(
                    backVector: Vector3(0, 0, -1),
                    rightVector: Vector3(1, 0, 0),
                    upVector: Vector3(0, 1, 0),
                    azimuth: 0,
                    altitude: -180,
                  );

          return BlocBuilder<AstraBloc, AstraState>(
            builder: (context, astraState) {
              return GestureDetector(
                onTapUp:
                    (details) => _handleTap(
                      context,
                      details,
                      astraState,
                      phoneRotatedState,
                      screenSize,
                    ),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: MyPainter(
                    context,
                    astraState,
                    phoneRotatedState,
                    _lastPosition, // passer la dernière position connue (peut être null tant qu'aucune n'est reçue)
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
