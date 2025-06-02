import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:sky_map/phone/bloc/phone_event.dart';
import 'package:sky_map/phone/bloc/phone_state.dart';

class PhoneBloc extends Bloc<PhoneEvent, PhoneRotatedState> {
  PhoneOrientationEvent? _orientationEvent;

  PhoneBloc() : super(PhoneRotatedState(backVector: Vector3(0, 0, -1), rightVector: Vector3(1, 0, 0), upVector: Vector3(0, 1, 0), azimuth: 0, altitude: -180)) {
    on<PhoneOrientationEvent>(_phoneRotated);
  }

  Future<void> _phoneRotated(
    PhoneOrientationEvent event,
    Emitter<PhoneRotatedState> emit,
  ) async {
    if (_orientationEvent != null &&
        equalQuaternion(
          _orientationEvent!.val.quaternion,
          event.val.quaternion,
        ))
      {return;}
    _orientationEvent = event;

    Vector3 rightVector = Vector3(1, 0, 0);
    Vector3 upVector = Vector3(0, 1, 0);
    Vector3 backVector = Vector3(0, 0, -1);

    // Rotation des vecteurs selon le quaternion
    Vector3 rotatedRight = event.val.quaternion.rotateVector(rightVector);
    Vector3 rotatedUp = event.val.quaternion.rotateVector(upVector);
    Vector3 rotatedBack = event.val.quaternion.rotateVector(backVector);

    // Calcul de l'azimuth et de l'altitude à partir du backVector
    double azimuth = atan2(rotatedBack.x, rotatedBack.z) * (180 / pi);
    double altitude = asin(rotatedBack.y) * (180 / pi);

    // Normalisation de l'azimuth entre -180° et 180°
    if (azimuth > 180) azimuth -= 360;
    if (azimuth < -180) azimuth += 360;

    print('Right Vecor: (${format(rotatedRight.x)}, ${format(rotatedRight.y)}, ${format(rotatedRight.z)})');
    print('Up Vector: (${format(rotatedUp.x)}, ${format(rotatedUp.y)}, ${format(rotatedUp.z)})');

    emit(PhoneRotatedState(
      backVector: rotatedBack,
      rightVector: rotatedRight,
      upVector: rotatedUp,
      azimuth: azimuth,
      altitude: altitude
    ));
  }
}

double radToDeg(double radians) {
  return radians * (180 / pi);
}

String format(double value) {
  return value.toStringAsFixed(2);
}

double simplify(double value) {
  return (value * 100).round() / 100;
}

bool equalEulerAngles(EulerAngles a, EulerAngles b) {
  return format(a.azimuth) == format(b.azimuth) &&
      format(a.pitch) == format(b.pitch) &&
      format(a.roll) == format(b.roll);
}

bool equalQuaternion(Quaternion a, Quaternion b) {
  return format(a.x) == format(b.x) &&
      format(a.y) == format(b.y) &&
      format(a.z) == format(b.z) &&
      format(a.w) == format(b.w);
}

extension QuaternionRotation on Quaternion {
  /// Fait tourner le vecteur local [vLocal] (format [x,y,z]) par ce quaternion.
  /// Renvoie [vx′, vy′, vz′] dans le référentiel global.
  Vector3 rotateVector(Vector3 vLocal) {
    // 1) On construit vQuat = (vLocal.x, vLocal.y, vLocal.z, 0)
    final vQuat = Quaternion(vLocal.x, vLocal.y, vLocal.z, 0);

    // 2) On normalise ce quaternion de rotation (sécurité)
    final qNorm = normalize();

    // 3) Son inverse (pour un quaternion unitaire, l’inverse = conjugué)
    final qInv = qNorm.conjugate();

    // 4) application :  v′ = qNorm × vQuat × qInv
    final r = qNorm.multiply(vQuat).multiply(qInv);

    // 5) on prend seulement x,y,z (la partie “w” doit être ≈ 0)
    return Vector3(r.x, r.y, r.z);
  }
}