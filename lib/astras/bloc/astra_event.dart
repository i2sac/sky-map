import 'dart:async'; // Importer Completer
import 'package:equatable/equatable.dart';

sealed class AstraEvent extends Equatable {
  const AstraEvent();
}

final class AppOpened extends AstraEvent {
  const AppOpened();

  @override
  List<Object?> get props => [];
}

final class ResetAstras extends AstraEvent {
  const ResetAstras();

  @override
  List<Object?> get props => [];
}