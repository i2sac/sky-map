import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sky_map/astras/bloc/astra_bloc.dart';
import 'package:sky_map/astras/bloc/astra_state.dart';
import 'package:sky_map/astras/models/astra.dart';
import 'package:sky_map/astras/widgets/painter.dart';
import 'package:sky_map/phone/bloc/phone_bloc.dart';
import 'package:sky_map/phone/bloc/phone_state.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class BlackCanvas extends StatefulWidget {
  final Function(Astra) onAstraTapped;
  const BlackCanvas({super.key, required this.onAstraTapped});

  @override
  State<BlackCanvas> createState() => _BlackCanvasState();
}

class _BlackCanvasState extends State<BlackCanvas> {
  MyPainter? _painter;

  void _handleTap(BuildContext context, TapUpDetails details, PhoneRotatedState phoneState) {
    if (_painter == null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(details.globalPosition);

    double ox = renderBox.size.width / 2;
    double oy = renderBox.size.height / 2;
    double rollForTransform = _painter!.radians(phoneState.roll);

    final Matrix4 transform = Matrix4.identity()
      ..translate(ox, oy)
      ..rotateZ(rollForTransform)
      ..translate(-ox, -oy);
    
    final vm.Vector3 tapVector = vm.Vector3(localPosition.dx, localPosition.dy, 0);
    final vm.Vector3 transformedTapVector = transform.perspectiveTransform(tapVector);
    Offset transformedTapPosition = Offset(transformedTapVector.x, transformedTapVector.y);

    Astra? tappedAstra = _painter!.getAstraAtPoint(transformedTapPosition);
    if (tappedAstra != null) {
      widget.onAstraTapped(tappedAstra);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhoneBloc, PhoneRotatedState>(
      builder: (context, phoneState) {
        return BlocBuilder<AstraBloc, AstraState>(
          builder: (context, astraState) {
            _painter = MyPainter(
              context, 
              astraState, 
              phoneState, 
              onAstraTapped: widget.onAstraTapped
            );
            return GestureDetector(
              onTapUp: (details) => _handleTap(context, details, phoneState),
              child: CustomPaint(
                size: Size.infinite,
                painter: _painter,
              ),
            );
          },
        );
      },
    );
  }
}
