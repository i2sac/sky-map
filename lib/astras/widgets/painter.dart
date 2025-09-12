import 'package:flutter/material.dart';
import 'package:sky_map/astras/bloc/astra_state.dart';
import 'package:sky_map/phone/bloc/phone_state.dart';
import 'package:sky_map/utils.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class MyPainter extends CustomPainter {
  final BuildContext context;
  final AstraState data;
  final PhoneRotatedState phoneRotatedState;
  PhonePositionState? oldPhonePositionState;
  PhonePositionState? phonePositionState;

  MyPainter(
    this.context,
    this.data,
    this.phoneRotatedState,
    this.phonePositionState,
  );

  @override
  bool shouldRepaint(MyPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.phoneRotatedState != phoneRotatedState;
  }

  @override
  Future<void> paint(Canvas canvas, Size size) async {
    double ox, oy, fovHalfDegrees, scaleDegToPixX, scaleDegToPixY;
    vm.Matrix3 viewMatrix;

    (
      ox,
      oy,
      fovHalfDegrees,
      scaleDegToPixX,
      scaleDegToPixY,
      viewMatrix,
    ) = viewConfigs(size, phoneRotatedState);

    // Dessiner les constellations à chaque frame si une position est connue
    if (phonePositionState != null) {
      final List<dynamic> constData = phonePositionState!.constellationData;
      for (final constellation in constData) {
        final figures = constellation['coordinates'];
        Offset? labelPos; // first visible point to anchor the label
        for (final List<dynamic> figure in figures) {
          if (figure.length > 1) {
            for (var i = 0; i < figure.length - 1; i++) {
              double? p1x1, p1x2, p2x1, p2x2;
              (p1x1, p1x2, _) = constellationPoint(
                figure[i][0],
                figure[i][1],
                constellation['name'],
                ox,
                oy,
                fovHalfDegrees,
                scaleDegToPixX,
                scaleDegToPixY,
                viewMatrix,
              );
              (p2x1, p2x2, _) = constellationPoint(
                figure[i + 1][0],
                figure[i + 1][1],
                constellation['name'],
                ox,
                oy,
                fovHalfDegrees,
                scaleDegToPixX,
                scaleDegToPixY,
                viewMatrix,
              );

              if (p1x1 != null &&
                  p1x2 != null &&
                  p2x1 != null &&
                  p2x2 != null) {
                // Save first visible point for label anchor
                labelPos ??= Offset(p1x1, p1x2);
                canvas.drawLine(
                  Offset(p1x1, p1x2),
                  Offset(p2x1, p2x2),
                  Paint()
                    ..strokeWidth = 0.5
                    ..color = Colors.white
                    ..style = PaintingStyle.stroke,
                );
              }
            }
          }
        }

        // Draw the constellation name once per constellation
        if (labelPos != null) {
          final textSpan = TextSpan(
            text: constellation['name']?.toString() ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black54,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          );
          final tp = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: '…',
          );
          tp.layout(minWidth: 0, maxWidth: double.infinity);

          // Offset a bit so the text doesn't sit on the line
          final textOffset = labelPos.translate(6, -6);

          // Optional: draw a subtle background for readability
          final bgRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              textOffset.dx - 4,
              textOffset.dy - 2,
              tp.width + 8,
              tp.height + 4,
            ),
            const Radius.circular(4),
          );
          final bgPaint =
              Paint()
                ..color = Colors.black.withOpacity(0.35)
                ..style = PaintingStyle.fill;
          canvas.drawRRect(bgRect, bgPaint);

          tp.paint(canvas, textOffset);
        }
      }
    }

    // Si aucune donnée d'astre n'est disponible (chargement), on peut quand même afficher les constellations ci-dessus.
    if (data.props.isEmpty) {
      return Future.value();
    }

    for (var astra in data.props) {
      if (astra.name == 'Earth') continue;

      double? x, y, apparentSize;
      (x, y, apparentSize) = astraCoordsOnCanvas(
        astra,
        ox,
        oy,
        fovHalfDegrees,
        scaleDegToPixX,
        scaleDegToPixY,
        viewMatrix,
      );

      if (x == null || y == null || apparentSize == null) {
        continue;
      }

      // 8. Dessin de l'astre
      canvas.drawCircle(
        Offset(x, y),
        apparentSize,
        Paint()
          ..color = planetColors[astra.name] ?? Colors.lightBlueAccent
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, 5),
      );
    }
  }
}
