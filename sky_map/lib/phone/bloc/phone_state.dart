import 'package:equatable/equatable.dart';

class PhoneRotatedState extends Equatable {
  final double angle;

  const PhoneRotatedState(this.angle);

  @override
  List<Object> get props => [angle];
}
