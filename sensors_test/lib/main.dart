import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _ax = 0, _ay = 0, _az = 0;
  double _mx = 0, _my = 0, _mz = 0;
  double _azimuth = 0, _pitch = 0, _roll = 0;
  // Ajout des variables pour les angles calculés
  double _calcAzimuth = 0, _calcPitch = 0, _calcRoll = 0;

  StreamSubscription? _accelerometerStream;
  StreamSubscription? _magnetometerStream;
  StreamSubscription? _orientationStream;

  Text title(String txt) {
    return Text(txt,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            );
  }

  // Fonction pour calculer les angles d'Euler
  void _calculateEulerAngles() {
    // 1. Calcul du roulis et du tangage à partir de l'accéléromètre
    _calcRoll = atan2(_ay, _az) * 180 / pi;
    _calcPitch = atan2(-_ax, sqrt(_ay * _ay + _az * _az)) * 180 / pi;
    
    // 2. Calcul du lacet (azimut) avec compensation magnétique
    final double rollRad = _calcRoll * pi / 180;
    final double pitchRad = _calcPitch * pi / 180;
    
    final double cosRoll = cos(rollRad);
    final double sinRoll = sin(rollRad);
    final double cosPitch = cos(pitchRad);
    final double sinPitch = sin(pitchRad);
    
    // Composantes magnétiques compensées
    final double magX = _mx * cosPitch + _mz * sinPitch;
    final double magY = _mx * sinRoll * sinPitch + 
                        _my * cosRoll - 
                        _mz * sinRoll * cosPitch;
    
    // 3. Calcul de l'azimut
    _calcAzimuth = atan2(-magY, magX) * 180 / pi;
    
    // Normaliser entre 0-360°
    if (_calcAzimuth < 0) _calcAzimuth += 360;
  }

  @override
  void initState() {
    super.initState();
    
    _accelerometerStream = accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _ax = event.x;
        _ay = event.y;
        _az = event.z;
        _calculateEulerAngles();
      });
    });

    _magnetometerStream = magnetometerEvents.listen((MagnetometerEvent event) {
      setState(() {
        _mx = event.x;
        _my = event.y;
        _mz = event.z;
        _calculateEulerAngles();
      });
    });

    _orientationStream = RotationSensor.orientationStream.listen((event) {
      setState(() {
        _azimuth = event.eulerAngles.azimuth;
        _pitch = event.eulerAngles.pitch;
        _roll = event.eulerAngles.roll;
      });
    });
  }

  @override
  void dispose() {
    _accelerometerStream?.cancel();
    _magnetometerStream?.cancel();
    _orientationStream?.cancel();
    super.dispose();
  }

  String format(double value) {
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Sensors Checker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            title('Accelerometer'),
            Text('${format(_ax)}, ${format(_ay)}, ${format(_az)}'),
            
            const SizedBox(height: 20),
            title('Magnetometer'),
            Text('${format(_mx)}, ${format(_my)}, ${format(_mz)}'),
            
            const SizedBox(height: 20),
            title('Orientation (Sensor)'),
            Text('Azimuth: ${format(_azimuth)}\n'
                 'Pitch: ${format(_pitch)}\n'
                 'Roll: ${format(_roll)}'),
            
            // Ajout de la section pour les angles calculés
            const SizedBox(height: 30),
            title('Calculated Orientation'),
            Text('Azimuth: ${format(_calcAzimuth)}\n'
                 'Pitch: ${format(_calcPitch)}\n'
                 'Roll: ${format(_calcRoll)}'),
          ],
        ),
      ),
    );
  }
}