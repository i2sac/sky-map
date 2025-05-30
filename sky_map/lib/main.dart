import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sky_map/astras/bloc/astra_bloc.dart';
import 'package:sky_map/astras/bloc/astra_event.dart';
import 'package:sky_map/phone/view/canvas.dart';
import 'package:sky_map/phone/bloc/phone_bloc.dart';
import 'package:sky_map/phone/bloc/phone_event.dart';

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
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _magnetometerSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to orientation changes
    _accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent acc,
    ) {
      _magnetometerSubscription = magnetometerEvents.listen((MagnetometerEvent mag) {
        context.read<PhoneBloc>().add(PhoneOrientationEvent(acc, mag));
      });
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    super.dispose();
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
              const BlackCanvas(),
              if (notLoaded)
                Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10,
                    children: [
                      Text(
                        'Sky Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
