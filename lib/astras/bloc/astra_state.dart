import 'package:equatable/equatable.dart';
import 'package:sky_map/astras/models/astra.dart';

class AstraState extends Equatable {
  final List<Astra> astras;

  const AstraState(this.astras);

  @override
  List<Astra> get props => astras;
}
