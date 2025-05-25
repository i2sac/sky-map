import 'package:equatable/equatable.dart';

class Astra extends Equatable {
  final String name, constellation;
  final double distanceAU,
      distanceKM,
      altitude,
      azimuth,
      rightAscension,
      declination,
      magnitude;

  Astra({
    required this.name,
    required this.distanceAU,
    required this.distanceKM,
    required this.altitude,
    required this.azimuth,
    required this.rightAscension,
    required this.declination,
    required this.constellation,
    required this.magnitude,
  });

  @override
  List<Object> get props => [
    name,
    distanceAU,
    distanceKM,
    altitude,
    azimuth,
    rightAscension,
    declination,
    constellation,
    magnitude,
  ];

  factory Astra.fromRow(Map<String, dynamic> row) {
    Map<String, dynamic> cell = row["cells"][0];
    return Astra(
      name: cell["name"],
      distanceAU: double.parse(cell["distance"]["fromEarth"]["au"]),
      distanceKM: double.parse(cell["distance"]["fromEarth"]["km"]),
      altitude: double.parse(
        cell["position"]["horizontal"]["altitude"]["degrees"],
      ),
      azimuth: double.parse(
        cell["position"]["horizontal"]["azimuth"]["degrees"],
      ),
      rightAscension: double.parse(
        cell["position"]["equatorial"]["rightAscension"]["hours"],
      ),
      declination: double.parse(
        cell["position"]["equatorial"]["declination"]["degrees"],
      ),
      constellation: cell["position"]["constellation"]["name"],
      magnitude: cell["extraInfo"]["magnitude"] ?? 0,
    );
  }
}
