import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:sky_map/astras/bloc/astra_event.dart';
import 'package:sky_map/astras/bloc/astra_state.dart';
import 'package:sky_map/astras/models/astra.dart';

class AstraBloc extends Bloc<AstraEvent, AstraState> {
  List<Astra> data = [];
  double? angle;

  AstraBloc({required this.data}) : super(const AstraState([])) {
    on<AppOpened>(_fetchData);
  }

  Future<Position> getPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _fetchData(AppOpened event, Emitter<AstraState> emit) async {
    final position = await getPosition();
    List<Astra> data = [];

    final appID = dotenv.env['APP_ID'];
    final appSecret = dotenv.env['APP_SECRET'];
    String basicAuth =
        'Basic ${base64.encode(utf8.encode('$appID:$appSecret'))}';

    final now = DateTime.now();
    final queryParams = {
      'latitude': position.latitude.toString(),
      'longitude': position.longitude.toString(),
      'elevation': position.altitude.toString(),
      'from_date': now.toString().split(' ')[0],
      'to_date': now.toString().split(' ')[0],
      'time': now.toString().split(' ')[1].split('.')[0],
    };
    final uri = Uri.https(
      'api.astronomyapi.com',
      '/api/v2/bodies/positions',
      queryParams,
    );
    final r = await http.get(
      uri,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: basicAuth,
        HttpHeaders.contentTypeHeader: 'application/json',
      },
    );

    Map<String, dynamic> resData = jsonDecode(r.body);

    if (resData["data"] != null) {
      for (var row in resData["data"]["table"]["rows"]) {
        data.add(Astra.fromRow(row));
      }
    }

    emit(AstraState(data));
  }
}

class CustomBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
  }
}
