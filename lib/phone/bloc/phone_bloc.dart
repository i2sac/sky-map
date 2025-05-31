import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sky_map/phone/bloc/phone_event.dart';
import 'package:sky_map/phone/bloc/phone_state.dart';

class PhoneBloc extends Bloc<PhoneEvent, PhoneRotatedState> {
  double _azimuth = 0, _pitch = 0, _roll = 0;
  AccelerometerEvent? _accEv;
  MagnetometerEvent? _magEv;

  PhoneBloc() : super(const PhoneRotatedState(0, 0, 90)) {
    on<PhoneOrientationEvent>(_phoneRotated);
  }

  Future<void> _phoneRotated(
    PhoneOrientationEvent event,
    Emitter<PhoneRotatedState> emit,
  ) async {
    bool equals = _accEv != null && _magEv != null &&
        _accEv!.x == event.acc.x &&
        _accEv!.y == event.acc.y &&
        _accEv!.z == event.acc.z &&
        _magEv!.x == event.mag.x &&
        _magEv!.y == event.mag.y &&
        _magEv!.z == event.mag.z;
        
    if (equals) {
      // Si le téléphone n'a pas bougé, on ne fait rien
      return;
    }

    // Mettre à jour les événements
    _accEv = event.acc;
    _magEv = event.mag;

    double ax = event.acc.x;
    double ay = event.acc.y;
    double az = event.acc.z;
    double mx = event.mag.x;
    double my = event.mag.y;
    double mz = event.mag.z;

    // 1. Calcul du rawPitch (rotation autour de l'axe X)
    double rawPitch = atan2(ay, az) * 180 / pi;
    
    // 2. Calcul du rawAzimuth (rotation autour de l'axe Z)
    double rawAzimuth = atan2(-ax, sqrt(ay * ay + az * az)) * 180 / pi;
    
    // 3. Calcul du rawRoll (rotation autour de l'axe Y) grâce aux composantes magnétiques compensées
    final double rollRad = rawAzimuth * pi / 180;
    final double pitchRad = rawPitch * pi / 180;

    final double cosRoll = cos(rollRad);
    final double sinRoll = sin(rollRad);
    final double cosPitch = cos(pitchRad);
    final double sinPitch = sin(pitchRad);

    double rawRoll = atan2(
      - (mx * sinRoll * sinPitch + my * cosRoll - mz * sinRoll * cosPitch),
      (mx * cosPitch + mz * sinPitch)
    ) * 180 / pi;

    // Nouvelle attribution après permutation des axes (point de référence: 0,0,90) :
    // - La rotation autour de l'axe X (rawPitch) contrôle la translation horizontale (newAzimuth)
    // - La rotation autour de l'axe Z (rawAzimuth) contrôle la translation verticale (newPitch)
    // - La rotation autour de l'axe Y (rawRoll) contrôle l'orientation du canvas (newRoll)
    double newAzimuth = rawAzimuth;            // X -> horizontal
    double newPitch   = rawPitch;           // Z -> vertical
    double newRoll    = (-rawRoll) + 90;        // Y -> canvas orientation, avec compensation

    print(
      'Azimuth: ${format(newAzimuth)}, '
      'Pitch: ${format(newPitch)}, '
      'Roll: ${format(newRoll)}',
    );

    emit(PhoneRotatedState(newAzimuth, newPitch, newRoll));
  }
}

double radToDeg(double radians) {
  return radians * (180 / pi);
}

String format(double value) {
  return value.toStringAsFixed(2);
}
