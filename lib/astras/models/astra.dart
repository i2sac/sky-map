import 'package:equatable/equatable.dart';

class Astra extends Equatable {
  final String name, constellation;
  final double distanceAU,
      distanceKM,
      altitude,
      azimuth,
      magnitude;

  const Astra({
    required this.name,
    required this.distanceAU,
    required this.distanceKM,
    required this.altitude,
    required this.azimuth,
    required this.constellation,
    required this.magnitude,
  });

  double get distanceInKM => distanceKM;
  double get distanceInAU => distanceAU;

  @override
  List<Object> get props => [
    name,
    distanceAU,
    distanceKM,
    altitude,
    azimuth,
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
      constellation: cell["position"]["constellation"]["name"],
      magnitude: cell["extraInfo"]["magnitude"] ?? 0,
    );
  }
}
