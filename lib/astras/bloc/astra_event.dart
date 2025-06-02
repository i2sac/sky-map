import 'dart:async'; // Importer Completer
import 'package:equatable/equatable.dart';

sealed class AstraEvent extends Equatable {
  const AstraEvent();
}

final class AppOpened extends AstraEvent {
  final Completer<void>? completer;

  const AppOpened({this.completer});

  @override
  List<Object?> get props => [completer];
}
