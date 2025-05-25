import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_map/astras/bloc/astra_bloc.dart';
import 'package:sky_map/astras/bloc/astra_state.dart';
import 'package:sky_map/astras/widgets/painter.dart';

class BlackCanvas extends StatelessWidget {
  const BlackCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BlocBuilder<AstraBloc, AstraState>(
        builder: (context, state) {
          return CustomPaint(
            size: Size.infinite,
            painter: MyPainter(context, state),
          );
        },
      ),
    );
  }
}
