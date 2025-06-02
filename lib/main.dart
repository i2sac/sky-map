import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sky_map/astras/bloc/astra_bloc.dart';
import 'package:sky_map/astras/bloc/astra_event.dart';
import 'package:sky_map/astras/models/astra.dart';
import 'package:sky_map/phone/bloc/phone_bloc.dart';
import 'package:sky_map/phone/bloc/phone_event.dart';
import 'package:sky_map/phone/view/canvas.dart';

import 'astras/bloc/astra_state.dart';

Future main() async {
  // Variables d'environnement
  await dotenv.load(fileName: '.env');

  // Observer
  Bloc.observer = CustomBlocObserver();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sky Map',
      debugShowCheckedModeBanner: false,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AstraBloc>(
            create: (context) => AstraBloc(data: [])..add(AppOpened()),
          ),
          BlocProvider<PhoneBloc>(create: (context) => PhoneBloc()),
        ],
        child: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription? _orientationStream;

  @override
  void initState() {
    super.initState();
    // Listen to orientation changes
    RotationSensor.samplingPeriod = SensorInterval.gameInterval;
    _orientationStream = RotationSensor.orientationStream.listen((event) {
      if (mounted && context.read<AstraBloc>().state.props.isNotEmpty) {
        context.read<PhoneBloc>().add(PhoneOrientationEvent(event));
      } 
    });
  }

  @override
  void dispose() {
    _orientationStream?.cancel();
    super.dispose();
  }

  // Méthode pour afficher la modale d'information de l'astre
  void _showAstraModal(Astra astra) {
    // Trouver la couleur et le diamètre pour l'affichage
    // Ces maps sont dans MyPainter, il faudrait peut-être les rendre plus accessibles
    // Pour l'instant, on peut les dupliquer ou les passer.
    // Pour simplifier ici, utilisons des valeurs par défaut ou passons-les.
    // Idéalement, MyPainter pourrait avoir une méthode statique ou on crée une classe utilitaire.
    
    // Duplication temporaire pour l'exemple de la modale
    final Map<String, Color> planetColors = {
      'Mercury': Color(0xFF9F9F9F), 'Venus': Color(0xFFE6E6BA), 'Mars': Color(0xFFE67A50),
      'Jupiter': Color(0xFFF3D3A8), 'Saturn': Color(0xFFEDD59F), 'Uranus': Color(0xFF9FE3E3),
      'Neptune': Color(0xFF4B70DD), 'Sun': Color(0xFFFFDF00), 'Moon': Color(0xFFF4F6F0),
    };
    Color displayColor = planetColors[astra.name] ?? Colors.lightBlueAccent;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Wrap(
            runSpacing: 15,
            children: <Widget>[
              Center(
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: displayColor,
                  // Vous pourriez ajouter une image/texture ici plus tard
                ),
              ),
              Center(
                child: Text(
                  astra.name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Divider(color: Colors.grey[700]),
              _buildInfoRow('Constellation:', astra.constellation),
              _buildInfoRow('Altitude:', '${astra.altitude.toStringAsFixed(2)}°'),
              _buildInfoRow('Azimut:', '${astra.azimuth.toStringAsFixed(2)}°'),
              _buildInfoRow('Distance (km):', astra.distanceInKM.toStringAsFixed(0)),
              _buildInfoRow('Distance (UA):', astra.distanceInAU.toStringAsFixed(2)),
              _buildInfoRow('Magnitude:', astra.magnitude.toStringAsFixed(2)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 16)),
        Text(value, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<AstraBloc, AstraState>(
        builder: (context, state) {
          final notLoaded = state.props.isEmpty;
          return Stack(
            children: [
              BlackCanvas(onAstraTapped: _showAstraModal),
              if (notLoaded)
                Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Sky Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      SpinKitFadingCircle(size: 40, color: Colors.white),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// CustomBlocObserver pour le débogage (peut rester tel quel)
class CustomBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    // print('${bloc.runtimeType} $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    // print('${bloc.runtimeType} $error $stackTrace');
  }
}
