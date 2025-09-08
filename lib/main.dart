import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sky_map/astras/bloc/astra_bloc.dart';
import 'package:sky_map/astras/bloc/astra_event.dart';
import 'package:sky_map/astras/bloc/astra_state.dart';
import 'package:sky_map/phone/bloc/phone_bloc.dart';
import 'package:sky_map/phone/bloc/phone_event.dart';
import 'package:sky_map/phone/view/canvas.dart';

Future main() async {
  // Variables d'environnement
  await dotenv.load(fileName: '.env');

  // Observer
  Bloc.observer = CustomBlocObserver();

  // Initialisation de l'application
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
            create: (context) => AstraBloc()..add(const AppOpened()),
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
    RotationSensor.samplingPeriod = Duration(milliseconds: 14); // ~60Hz
    _orientationStream = RotationSensor.orientationStream.listen((event) {
      // Vérifier si AstraBloc a des données avant d'envoyer des événements PhoneBloc
      // Cela évite d'envoyer des PhoneOrientationEvent pendant le chargement initial/rafraîchissement
      // où astraState.props pourrait être vide temporairement.
      if (mounted) {
        final astraState = context.read<AstraBloc>().state;
        if (astraState.astras.isNotEmpty) {
          context.read<PhoneBloc>().add(PhoneOrientationEvent(event));
        }
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
        builder: (context, astraState) {
          // Afficher le preloader si l'état des astres est vide (chargement initial ou pendant le rafraîchissement)
          final showPreloader = astraState.astras.isEmpty;

          return RefreshIndicator(
            color: Colors.white,
            backgroundColor: Colors.blueAccent,
            onRefresh: () async {
              final completer = Completer<void>();
              context.read<AstraBloc>().add(AppOpened(completer: completer));
              return await completer.future;
            },
            child: Stack(
              children: [
                // Toujours construire BlackCanvas pour qu'il soit prêt
                // Sa visibilité sera gérée par le Stack et le preloader par-dessus
                const BlackCanvas(),
                if (showPreloader)
                  Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.black.withOpacity(
                      0.8,
                    ), // Légère transparence pour voir le RefreshIndicator derrière
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
                        const SizedBox(height: 20),
                        const SpinKitFadingCircle(
                          size: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Actualisation des données...',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
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
