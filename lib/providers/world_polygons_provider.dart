import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

// Raw polygon shapes (points + holes) keyed by ISO Alpha-3 code.
// Colors are applied later so the same data can be reused with different styles.
typedef PolygonShape = ({List<LatLng> points, List<List<LatLng>>? holes});

final worldPolygonsProvider =
    FutureProvider<Map<String, List<PolygonShape>>>((ref) async {
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
      return LatLng(
        (point[1] as num).toDouble(),
        (point[0] as num).toDouble(),
      );
    }).toList();

// Builds the list of colored Polygon widgets for a set of visited ISO codes.
List<Polygon> buildVisitedPolygons(
  Map<String, List<PolygonShape>> worldData,
  List<String> isoCodes,
) {
  const fillColor = Color(0x556750A4);
  const borderColor = Color(0xFF6750A4);

  final polygons = <Polygon>[];
  for (final code in isoCodes) {
    final shapes = worldData[code];
    if (shapes == null) continue;
    for (final shape in shapes) {
      polygons.add(Polygon(
        points: shape.points,
        holePointsList: shape.holes,
        color: fillColor,
        borderColor: borderColor,
        borderStrokeWidth: 1.5,
      ));
    }
  }
  return polygons;
}
