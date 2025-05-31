import 'package:equatable/equatable.dart';

class PhoneRotatedState extends Equatable {
  final double azimuth, pitch, roll;

  const PhoneRotatedState(this.azimuth, this.pitch, this.roll);

  @override
  List<Object> get props => [azimuth, pitch, roll];
}
