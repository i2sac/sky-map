import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_map/phone/bloc/phone_event.dart';
import 'package:sky_map/phone/bloc/phone_state.dart';

class PhoneBloc extends Bloc<PhoneEvent, PhoneRotatedState> {
  double _azimuth = 0, _pitch = 0, _roll = 0;
  PhoneBloc() : super(const PhoneRotatedState(0, 0, 0)) {
    on<PhoneOrientationEvent>(_phoneRotated);
  }

  Future<void> _phoneRotated(
    PhoneOrientationEvent event,
    Emitter<PhoneRotatedState> emit,
  ) async {
    double ax = event.acc.x;
    double ay = event.acc.y;
    double az = event.acc.z;
    double mx = event.mag.x;
    double my = event.mag.y;
    double mz = event.mag.z;

    // 1. Calcul du roulis et du tangage à partir de l'accéléromètre
    _roll = atan2(ay, az) * 180 / pi;
    _pitch = atan2(-ax, sqrt(ay * ay + az * az)) * 180 / pi;
    
    // 2. Calcul du lacet (azimut) avec compensation magnétique
    final double rollRad = _roll * pi / 180;
    final double pitchRad = _pitch * pi / 180;
    
    final double cosRoll = cos(rollRad);
    final double sinRoll = sin(rollRad);
    final double cosPitch = cos(pitchRad);
    final double sinPitch = sin(pitchRad);
    
    // Composantes magnétiques compensées
    final double magX = mx * cosPitch + mz * sinPitch;
    final double magY = mx * sinRoll * sinPitch + 
                        my * cosRoll - 
                        mz * sinRoll * cosPitch;
    
    // 3. Calcul de l'azimut
    _azimuth = atan2(-magY, magX) * 180 / pi;
    
    // Normaliser entre 0-360°
    if (_azimuth < 0) _azimuth += 360;

    emit(PhoneRotatedState(_azimuth, _pitch, _roll));
  }
}

double radToDeg(double radians) {
  return radians * (180 / 3.141592653589793);
}
