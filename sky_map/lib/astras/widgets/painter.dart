import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sky_map/astras/bloc/astra_state.dart';

class MyPainter extends CustomPainter {
  BuildContext context;
  AstraState data;

  MyPainter(this.context, this.data);

  @override
  bool shouldRepaint(MyPainter oldDelegate) {
    return oldDelegate.data !=
        data; // Always repaint to reflect changes in data
  }

  @override
  void paint(Canvas canvas, Size size) {
    double ox = MediaQuery.of(context).size.width / 2,
        oy = MediaQuery.of(context).size.height / 2;
    Offset origin = Offset(ox, oy);

    if (data.props.isNotEmpty) {
      for (var astra in data.props) {
        if (astra.name == 'Earth') {
          continue; // Skip Earth
        }

        double magnitude = astra.magnitude; // Magnitude de l'astre
        double taille = 10.0; // Taille par défaut

        // Calculer la taille seulement si la magnitude est valide
        if (magnitude != 0 && magnitude.isFinite) {
          taille = 10 * pow(2.512, (0 - magnitude)).toDouble();
        }

        // Limiter la taille pour éviter des valeurs extrêmes
        taille = taille.clamp(5.0, 50.0); // Min 5, Max 50

        print('Data');
        print(
          '${astra.name}: alt = ${astra.altitude}, az = ${astra.azimuth}, mag = ${astra.magnitude}',
        );
        canvas.drawCircle(
          Offset((ox + astra.azimuth) * 2, oy + astra.altitude),
          taille,
          Paint()
            ..color = Colors.lightBlueAccent
            ..maskFilter = MaskFilter.blur(BlurStyle.solid, 5),
        );
      }
    }

    canvas.drawCircle(
      origin,
      8,
      Paint()
        ..color = Colors.lightBlueAccent
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, 5),
    );
  }
}
