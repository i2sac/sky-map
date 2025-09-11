import 'package:equatable/equatable.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:sky_map/phone/bloc/phone_bloc.dart';

class PhoneEvent extends Equatable {
  @override
  List<Object> get props => [];
}

final class PhoneOrientationEvent extends PhoneEvent {
  final OrientationEvent orientation;

  PhoneOrientationEvent(this.orientation);

  @override
  List<Object> get props => [orientation];

  OrientationEvent get val => orientation;

  Quaternion simplifiedQuaternion() {
    return Quaternion(
      simplify(val.quaternion.x),
      simplify(val.quaternion.y),
      simplify(val.quaternion.z),
      simplify(val.quaternion.w),
    );
  }

  EulerAngles simplifiedEulerAngles() {
    return EulerAngles(
      simplify(val.eulerAngles.azimuth),
      simplify(val.eulerAngles.pitch),
      simplify(val.eulerAngles.roll),
    );
  }
}

final class PhonePositionEvent extends PhoneEvent {
  final double latitude, longitude;
  final List<dynamic> constellationData;

  PhonePositionEvent({
    required this.latitude,
    required this.longitude,
    required this.constellationData,
  });
}
