import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_map/phone/bloc/phone_event.dart';
import 'package:sky_map/phone/bloc/phone_state.dart';

class PhoneBloc extends Bloc<PhoneEvent, PhoneRotatedState> {
  double _angle = 0;
  PhoneBloc() : super(const PhoneRotatedState(0)) {
    on<PhoneAccelerometerEvent>(_phoneRotated);
  }

  Future<void> _phoneRotated(
    PhoneAccelerometerEvent event,
    Emitter<PhoneRotatedState> emit,
  ) async {
    double eventAngle = math.atan2(event.props[0], event.props[1]);
    if (eventAngle != _angle) {
      _angle = eventAngle;
      print('Rotated: ${radToDeg(_angle)}°');
    }
    emit(PhoneRotatedState(_angle));
  }
}

double radToDeg(double radians) {
  return radians * (180 / 3.141592653589793);
}
