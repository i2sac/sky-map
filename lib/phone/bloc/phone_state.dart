import 'package:equatable/equatable.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';

abstract class PhoneState extends Equatable {
  const PhoneState();
}

class PhoneRotatedState extends PhoneState {
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
  List<Object> get props => [
    backVector,
    rightVector,
    upVector,
    azimuth,
    altitude,
  ];
}

class PhonePositionState extends PhoneState {
  final double latitude, longitude;
  final List<dynamic> constellationData;

  const PhonePositionState({
    required this.latitude,
    required this.longitude,
    required this.constellationData,
  });

  @override
  List<Object> get props => [latitude, longitude, constellationData];
}
