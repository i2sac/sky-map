import 'package:equatable/equatable.dart';
// import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart'; // Plus besoin de OrientationEvent ici directement
import 'package:vector_math/vector_math_64.dart' as vm;

class PhoneRotatedState extends Equatable {
  final vm.Vector3 backVector, rightVector, upVector; // Utilisation de vm.Vector3
  final double azimuth, altitude, roll;

  const PhoneRotatedState({
    required this.backVector,
    required this.rightVector,
    required this.upVector,
    required this.azimuth,
    required this.altitude,
    required this.roll,
  });

  @override
  List<Object> get props => [backVector, rightVector, upVector, azimuth, altitude, roll];
}
