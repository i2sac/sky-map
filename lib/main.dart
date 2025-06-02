import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sky_map/astras/bloc/astra_bloc.dart';
import 'package:sky_map/astras/bloc/astra_event.dart';
import 'package:sky_map/phone/bloc/phone_bloc.dart';
import 'package:sky_map/phone/bloc/phone_event.dart';
import 'package:sky_map/phone/view/canvas.dart';

import 'astras/bloc/astra_state.dart';

Future main() async {
  // Variables d'environnement
  await dotenv.load(fileName: '.env');

  // Observer
  Bloc.observer = CustomBlocObserver(); // Assurez-vous que CustomBlocObserver est défini quelque part
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<AstraBloc, AstraState>(
        builder: (context, state) {
          final notLoaded = state.props.isEmpty;
          return RefreshIndicator(
            color: Colors.white,
            backgroundColor: Colors.blueAccent,
            onRefresh: () async {
              // Déclencher l'événement pour récupérer les données des astres
              context.read<AstraBloc>().add(AppOpened());
              // Attendre que le bloc traite et émette un nouvel état.
              // Une approche simple est de retourner un Future complété après un court délai
              // ou, mieux, attendre une confirmation spécifique du bloc si possible.
              // Pour cet exemple, le simple fait de déclencher l'événement est souvent suffisant
              // car le RefreshIndicator s'arrêtera et le BlocBuilder mettra à jour l'UI.
            },
            child: Stack(
              children: [
                const BlackCanvas(),
                if (notLoaded)
                  Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.black,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Sky Map',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const SpinKitFadingCircle(size: 40, color: Colors.white),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
