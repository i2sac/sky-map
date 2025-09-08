import 'dart:async';
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
  AstraBloc() : super(const AstraState([])) {
    on<AppOpened>(_fetchData);
  }

  Future<Position> getPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

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
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _fetchData(AppOpened event, Emitter<AstraState> emit) async {
    if (state.astras.isNotEmpty) {
      emit(const AstraState([]));
      await Future.delayed(const Duration(milliseconds: 50));
    }

    List<Astra> fetchedData = [];

    try {
      final position = await getPosition();
      final appID = dotenv.env['APP_ID'] ?? '';
      final appSecret = dotenv.env['APP_SECRET'] ?? '';
      String basicAuth =
          'Basic ${base64.encode(utf8.encode('$appID:$appSecret'))}';

      final now = DateTime.now().toString();
      final queryParams = {
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'elevation': position.altitude.toString(),
        'from_date': now.split(' ')[0],
        'to_date': now.split(' ')[0],
        'time': now.split(' ')[1].split('.')[0],
      };
      final uri = Uri.https(
        'api.astronomyapi.com',
        '/api/v2/bodies/positions',
        queryParams,
      );
      final r = await http
          .get(
            uri,
            headers: <String, String>{
              HttpHeaders.authorizationHeader: basicAuth,
              HttpHeaders.contentTypeHeader: 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (r.statusCode == 200) {
        Map<String, dynamic> resData = jsonDecode(r.body);
        if (resData["data"]?["table"]?["rows"] != null) {
          for (var row in resData["data"]["table"]["rows"]) {
            fetchedData.add(Astra.fromRow(row));
          }
        }
        emit(AstraState(fetchedData));
      } else {
        print('HTTP Error: ${r.statusCode} - ${r.body}');
        emit(const AstraState([]));
      }
    } catch (e) {
      print('Error fetching data: $e');
      emit(const AstraState([]));
    } finally {
      event.completer?.complete();
    }
  }
}

class CustomBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
  }
}
