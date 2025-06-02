import 'package:equatable/equatable.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';

class PhoneRotatedState extends Equatable {
  final Vector3 backVector, rightVector, upVector;
  final double azimuth, altitude;

  const PhoneRotatedState({
    required this.backVector,
    required this.rightVector,
    required this.upVector,
    required this.azimuth,
    required this.altitude,
  });

  @override
  List<Object> get props => [backVector, rightVector, upVector, azimuth, altitude];
}
