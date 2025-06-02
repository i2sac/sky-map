import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart' as sensor;
import 'package:sky_map/phone/bloc/phone_event.dart';
import 'package:sky_map/phone/bloc/phone_state.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class PhoneBloc extends Bloc<PhoneEvent, PhoneRotatedState> {
  PhoneOrientationEvent? _orientationEvent;

  PhoneBloc() : super(PhoneRotatedState(backVector: vm.Vector3(0, 0, -1), rightVector: vm.Vector3(1, 0, 0), upVector: vm.Vector3(0, 1, 0), azimuth: 0, altitude: -180, roll: 0)) {
    on<PhoneOrientationEvent>(_phoneRotated);
  }

  Future<void> _phoneRotated(
    PhoneOrientationEvent event,
    Emitter<PhoneRotatedState> emit,
  ) async {
    // Convertir le quaternion du capteur en quaternion vector_math
    final sensor.Quaternion sensorQuaternion = event.val.quaternion;
    final vm.Quaternion q = vm.Quaternion(sensorQuaternion.x, sensorQuaternion.y, sensorQuaternion.z, sensorQuaternion.w);

    if (_orientationEvent != null &&
        equalQuaternion(
          // Comparer avec le quaternion de l'événement précédent (qui serait aussi converti si stocké)
          // Pour l'instant, on compare le nouveau q avec le quaternion brut du précédent event.
          // Idéalement, _orientationEvent.val.quaternion devrait aussi être converti pour une comparaison équitable.
          // Simplifions : on stocke le vm.Quaternion s'il change.
          vm.Quaternion(_orientationEvent!.val.quaternion.x, _orientationEvent!.val.quaternion.y, _orientationEvent!.val.quaternion.z, _orientationEvent!.val.quaternion.w),
          q,
        ))
      {return;}
    _orientationEvent = event; // On stocke toujours l'événement original

    vm.Vector3 rightVector = vm.Vector3(1, 0, 0);
    vm.Vector3 upVector = vm.Vector3(0, 1, 0);
    vm.Vector3 backVector = vm.Vector3(0, 0, -1);

    // Utiliser le quaternion vm.Quaternion q normalisé
    final vm.Quaternion qNormalized = q.normalized();
    vm.Vector3 rotatedRight = qNormalized.rotateVector(rightVector);
    vm.Vector3 rotatedUp = qNormalized.rotateVector(upVector);
    vm.Vector3 rotatedBack = qNormalized.rotateVector(backVector);

    double azimuth = atan2(rotatedBack.x, rotatedBack.z) * (180 / pi);
    double altitude = asin(rotatedBack.y) * (180 / pi);

    if (azimuth < 0) azimuth += 360;

    // Convertir EulerAngles du capteur en degrés pour le roll
    // sensor.EulerAngles eulerAngles = event.val.eulerAngles;
    double phoneRoll = event.val.eulerAngles.roll * (180 / pi);

    emit(PhoneRotatedState(
      backVector: rotatedBack,
      rightVector: rotatedRight,
      upVector: rotatedUp,
      azimuth: azimuth,
      altitude: altitude,
      roll: phoneRoll,
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

// Doit utiliser sensor.EulerAngles si c'est ce que event.val.eulerAngles est.
bool equalEulerAngles(sensor.EulerAngles a, sensor.EulerAngles b) {
  return format(a.azimuth) == format(b.azimuth) &&
      format(a.pitch) == format(b.pitch) &&
      format(a.roll) == format(b.roll);
}

// Doit utiliser vm.Quaternion pour la comparaison interne.
bool equalQuaternion(vm.Quaternion a, vm.Quaternion b) {
  return format(a.x) == format(b.x) &&
      format(a.y) == format(b.y) &&
      format(a.z) == format(b.z) &&
      format(a.w) == format(b.w);
}

extension QuaternionRotation on vm.Quaternion {
  vm.Vector3 rotateVector(vm.Vector3 vLocal) {
    final tempQuaternion = vm.Quaternion(vLocal.x, vLocal.y, vLocal.z, 0.0);
    final qNormalized = this.normalized(); // `this` est le vm.Quaternion
    final qInverse = qNormalized.conjugated(); // Conjugate pour vm.Quaternion
    final result = qNormalized * tempQuaternion * qInverse;
    return vm.Vector3(result.x, result.y, result.z);
  }
}