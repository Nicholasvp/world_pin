import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/user_controller.dart';
import '../models/country_model.dart';
import '../providers/world_polygons_provider.dart';
import 'country_search_delegate.dart';

class MapView extends ConsumerWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final visitedCountries = user?.visitedCountries ?? [];

    final worldPolygonsAsync = ref.watch(worldPolygonsProvider);
    final visitedIsoCodes = visitedCountries.map((c) => c.isoCode).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('World Pin'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(20, 0),
          initialZoom: 2,
          minZoom: 1.5,
          maxZoom: 10,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.world_pin',
          ),
          if (visitedCountries.isNotEmpty)
            worldPolygonsAsync.when(
              data: (worldData) => PolygonLayer(
                polygons: buildVisitedPolygons(worldData, visitedIsoCodes),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          if (visitedCountries.isNotEmpty)
            MarkerLayer(
              markers: visitedCountries
                  .map((country) => _buildMarker(context, country))
                  .toList(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _searchAndAddCountry(context, ref),
        tooltip: 'Add visited country',
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }

  Marker _buildMarker(BuildContext context, CountryModel country) {
    final parts = country.localization.split(',');
    final lat = double.tryParse(parts[0].trim()) ?? 0;
    final lng = double.tryParse(parts.length > 1 ? parts[1].trim() : '0') ?? 0;

    return Marker(
      point: LatLng(lat, lng),
      width: 40,
      height: 40,
      child: Tooltip(
        message: '${country.name}\n${country.date.day}/${country.date.month}/${country.date.year}',
        child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
      ),
    );
  }

  Future<void> _searchAndAddCountry(BuildContext context, WidgetRef ref) async {
    final country = await showSearch(
      context: context,
      delegate: CountrySearchDelegate(),
    );

    if (country == null || !context.mounted) return;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date == null) return;

    ref.read(userProvider.notifier).addVisitedCountry(
          CountryModel(
            name: country.internationalName,
            isoCode: country.code,
            localization:
                '${country.latLng.latitude}, ${country.latLng.longitude}',
            date: date,
          ),
        );
  }
}
