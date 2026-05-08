import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:sealed_countries/sealed_countries.dart' show WorldCountry;

// Raw polygon shapes (points + holes) keyed by ISO Alpha-3 code.
// Colors are applied later so the same data can be reused with different styles.
typedef PolygonShape = ({List<LatLng> points, List<List<LatLng>>? holes});

final worldPolygonsProvider = FutureProvider<Map<String, List<PolygonShape>>>((
  ref,
) async {
  final body = await rootBundle.loadString('assets/countries.geo.json');

  final decoded = json.decode(body) as Map<String, dynamic>;
  final features = decoded['features'] as List<dynamic>;

  final result = <String, List<PolygonShape>>{};

  for (final feature in features) {
    final id = feature['id'] as String?;
    if (id == null || id == '-99') continue;

    final geometry = feature['geometry'] as Map<String, dynamic>?;
    if (geometry == null) continue;

    final shapes = _parseGeometry(geometry);
    if (shapes.isNotEmpty) result[id] = shapes;
  }

  return result;
});

List<PolygonShape> _parseGeometry(Map<String, dynamic> geometry) {
  final type = geometry['type'] as String;
  final coords = geometry['coordinates'];
  final shapes = <PolygonShape>[];

  if (type == 'Polygon') {
    final shape = _parsePolygon(coords as List<dynamic>);
    if (shape != null) shapes.add(shape);
  } else if (type == 'MultiPolygon') {
    for (final polygonCoords in coords as List<dynamic>) {
      final shape = _parsePolygon(polygonCoords as List<dynamic>);
      if (shape != null) shapes.add(shape);
    }
  }

  return shapes;
}

PolygonShape? _parsePolygon(List<dynamic> rings) {
  if (rings.isEmpty) return null;

  final outer = _parseRing(rings[0] as List<dynamic>);
  if (outer.isEmpty) return null;

  final holes = rings.length > 1
      ? rings.skip(1).map((r) => _parseRing(r as List<dynamic>)).toList()
      : null;

  return (points: outer, holes: holes);
}

List<LatLng> _parseRing(List<dynamic> coords) => coords.map((p) {
  final point = p as List<dynamic>;
  return LatLng((point[1] as num).toDouble(), (point[0] as num).toDouble());
}).toList();

// Builds the list of colored Polygon widgets for a set of ISO codes.
List<Polygon> buildCountryPolygons({
  required Map<String, List<PolygonShape>> worldData,
  required List<String> isoCodes,
  required Color fillColor,
  required Color borderColor,
}) {
  final polygons = <Polygon>[];
  for (final code in isoCodes) {
    // Convert to Alpha-3 if it's an old Alpha-2 code
    final alpha3Code = WorldCountry.maybeFromAnyCode(code)?.code ?? code;
    final shapes = worldData[alpha3Code];
    if (shapes == null) continue;
    for (final shape in shapes) {
      polygons.add(
        Polygon(
          points: shape.points,
          holePointsList: shape.holes,
          color: fillColor,
          borderColor: borderColor,
          borderStrokeWidth: 1.5,
        ),
      );
    }
  }
  return polygons;
}
