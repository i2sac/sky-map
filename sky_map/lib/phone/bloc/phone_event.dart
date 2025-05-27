import 'package:equatable/equatable.dart';
import 'package:sensors_plus/sensors_plus.dart';

class PhoneEvent extends Equatable {
  @override
  List<Object> get props => [];
}

final class PhoneAccelerometerEvent extends PhoneEvent {
  final AccelerometerEvent event;

  PhoneAccelerometerEvent(this.event);

  @override
  List<double> get props => [event.x, event.y, event.z];
}
