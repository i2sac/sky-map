import 'package:equatable/equatable.dart';
import 'package:sensors_plus/sensors_plus.dart';

class PhoneEvent extends Equatable {
  @override
  List<Object> get props => [];
}

final class PhoneOrientationEvent extends PhoneEvent {
  final AccelerometerEvent acc;
  final MagnetometerEvent mag;

  PhoneOrientationEvent(this.acc, this.mag);

  @override
  List<Object> get props => [acc, mag];
}
