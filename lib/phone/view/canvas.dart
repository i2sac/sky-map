import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_map/astras/bloc/astra_bloc.dart';
import 'package:sky_map/astras/bloc/astra_state.dart';
import 'package:sky_map/astras/widgets/painter.dart';
import 'package:sky_map/phone/bloc/phone_bloc.dart';
import 'package:sky_map/phone/bloc/phone_state.dart';

class BlackCanvas extends StatelessWidget {
  const BlackCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhoneBloc, PhoneRotatedState>(
      builder: (context, phoneState) {
        return BlocBuilder<AstraBloc, AstraState>(
          builder: (context, astraState) {
            return CustomPaint(
              size: Size.infinite,
              painter: MyPainter(context, astraState, phoneState),
            );
          },
        );
      },
    );
  }
}
