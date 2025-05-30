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
    return Center(
      child: BlocBuilder<PhoneBloc, PhoneRotatedState>(
        builder: (context, state) {
          return Transform.rotate(
            angle: 0,
            child: BlocBuilder<AstraBloc, AstraState>(
              builder: (astraContext, astraState) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: MyPainter(astraContext, astraState),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
