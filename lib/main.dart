import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sky_map/astras/bloc/astra_bloc.dart';
import 'package:sky_map/astras/bloc/astra_event.dart';
import 'package:sky_map/astras/bloc/astra_state.dart';
import 'package:sky_map/phone/bloc/phone_bloc.dart';
import 'package:sky_map/phone/bloc/phone_event.dart';
import 'package:sky_map/phone/view/canvas.dart';
import 'package:sky_map/utils.dart';

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
  bool gpsOK = true;
  bool networkOK = true;
  bool accelerometerOK = true;
  bool magnetometerOK = true;
  bool gyroscopeOK = true;
  bool constellationsOK = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _restartApp() {
    // Annuler les abonnements existants
    _orientationStream?.cancel();

    setState(() {
      gpsOK = true;
      networkOK = true;
      accelerometerOK = true;
      gyroscopeOK = true;
      magnetometerOK = true;

      // Réinitialiser les astres
      context.read<AstraBloc>().add(const ResetAstras());
    });

    // Relancer l'initialisation
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _checkInternet();
      await _initPositioning();
      await _testSensors();
      _setupOrientationStream();
    } catch (e) {
      // Ne rien faire ici car les erreurs sont déjà gérées dans chaque méthode
      // avec des setState appropriés
    }
  }

  Future<void> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 5),
        onTimeout: () => [InternetAddress('0.0.0.0')],
      );

      if (result.isEmpty || result[0].address == '0.0.0.0') {
        throw SocketException('No internet');
      }

      setState(() => networkOK = true);
    } on SocketException catch (_) {
      setState(() => networkOK = false);
      rethrow; // Important pour arrêter l'exécution de _initializeApp
    }
  }

  Future<void> _initPositioning() async {
    try {
      final position = await getPosition().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException('Position GPS indisponible');
        },
      );
      final fileContent = await rootBundle.loadString(
        'assets/constellations.lines.json',
      );

      final jsonData = parseConstellationsCoords(
        jsonDecode(fileContent) as List<dynamic>,
        position.latitude,
        position.longitude,
      );

      setState(() {
        constellationsOK = jsonData.isNotEmpty;
      });

      if (mounted) {
        context.read<PhoneBloc>().add(
          PhonePositionEvent(
            latitude: position.latitude,
            longitude: position.longitude,
            constellationData: jsonData,
          ),
        );
        // Une fois la position obtenue, charger les données des astres
        context.read<AstraBloc>().add(const AppOpened());
      }
    } catch (e) {
      setState(() {
        gpsOK = false;
      });
    }
  }

  void _setupOrientationStream() {
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

  Future<void> _testSensors() async {
    // Vérification de l'accéléromètre
    try {
      await for (var _ in accelerometerEventStream().timeout(
        const Duration(seconds: 1),
        onTimeout: (sink) => sink.close(),
      )) {
        break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          accelerometerOK = false;
        });
      }
    }

    // Vérification du gyroscope
    try {
      await for (var _ in gyroscopeEventStream().timeout(
        const Duration(seconds: 1),
        onTimeout: (sink) => sink.close(),
      )) {
        break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          gyroscopeOK = false;
        });
      }
    }

    // Vérification du magnétomètre
    try {
      await for (var _ in magnetometerEventStream().timeout(
        const Duration(seconds: 1),
        onTimeout: (sink) => sink.close(),
      )) {
        break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          magnetometerOK = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _orientationStream?.cancel();
    super.dispose();
  }

  Widget _loadingScreen(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: Colors.black.withOpacity(0.8),
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
          const SpinKitFadingCircle(size: 40, color: Colors.white),
          const SizedBox(height: 20),
          const Text(
            'Actualisation des données...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _displayErrors(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: Colors.black.withOpacity(0.8),
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 10,
            children: [
              if (!gpsOK) _gpsError(),
              if (!networkOK) _networkError(),
              if (!accelerometerOK) _accelerometerError(),
              if (!gyroscopeOK) _gyroscopeError(),
              if (!magnetometerOK) _magnetometerError(),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _restartApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Réessayer',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _networkError() {
    return const Text(
      'Vérifiez la connexion internet',
      style: TextStyle(color: Colors.red, fontSize: 16),
    );
  }

  Widget _gpsError() {
    return const Text(
      'Vérifiez le GPS',
      style: TextStyle(color: Colors.red, fontSize: 16),
    );
  }

  Widget _accelerometerError() {
    return const Text(
      'Accéléromètre non détecté',
      style: TextStyle(color: Colors.red, fontSize: 16),
    );
  }

  Widget _gyroscopeError() {
    return const Text(
      'Gyroscope non détecté',
      style: TextStyle(color: Colors.red, fontSize: 16),
    );
  }

  Widget _magnetometerError() {
    return const Text(
      'Magnétomètre non détecté',
      style: TextStyle(color: Colors.red, fontSize: 16),
    );
  }

  Widget _buildOverlay(AstraState astraState) {
    if (!networkOK ||
        !gpsOK ||
        !accelerometerOK ||
        !gyroscopeOK ||
        !magnetometerOK) {
      return _displayErrors(context);
    }

    return astraState.astras.isEmpty
        ? _loadingScreen(context)
        : const SizedBox.shrink(); // Pas d'overlay
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<AstraBloc, AstraState>(
        builder: (context, astraState) {
          return RefreshIndicator(
            color: Colors.white,
            backgroundColor: Colors.blueAccent,
            onRefresh: () async {
              _restartApp();
            },
            // Minimal fix: RefreshIndicator needs a Scrollable child.
            // We wrap the full-screen Stack in a SingleChildScrollView with
            // AlwaysScrollableScrollPhysics so the pull gesture is detected
            // even if the content is the exact screen height.
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                // Ensure the scrollable area is at least the screen height
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  children: [
                    // Full-screen sky canvas
                    const BlackCanvas(),
                    // Preloader overlay on top when data is loading
                    _buildOverlay(astraState),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
