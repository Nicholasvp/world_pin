import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:sealed_countries/sealed_countries.dart' hide LatLng;
import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';
import '../models/country_model.dart';
import '../providers/visited_countries_provider.dart';
import '../providers/world_polygons_provider.dart';
import 'country_search_delegate.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView>
    with TickerProviderStateMixin {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _animateTo(LatLng destination, {double zoom = 5}) {
    final camera = _mapController.camera;
    final latTween =
        Tween<double>(begin: camera.center.latitude, end: destination.latitude);
    final lngTween = Tween<double>(
        begin: camera.center.longitude, end: destination.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: zoom);

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final animation =
        CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  double _zoomForCountry(WorldCountry country) {
    final area = country.areaMetric;
    if (area >= 3_000_000) return 3.0;
    if (area >= 1_000_000) return 4.0;
    if (area >= 200_000) return 5.0;
    if (area >= 50_000) return 6.0;
    if (area >= 10_000) return 7.0;
    return 8.0;
  }

  Marker _buildMarkerFromIso(String isoCode) {
    final country = WorldCountry.fromCodeShort(isoCode);
    return Marker(
      point: LatLng(country.latLng.latitude, country.latLng.longitude),
      width: 40,
      height: 40,
      child: Tooltip(
        message: country.internationalName,
        child: const Icon(Icons.location_pin, color: Colors.red, size: 36),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visitedAsync = ref.watch(visitedCountriesProvider);
    final worldPolygonsAsync = ref.watch(worldPolygonsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('World Pin'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
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
          if (visitedAsync.hasValue && worldPolygonsAsync.hasValue)
            PolygonLayer(
              polygons: buildVisitedPolygons(
                worldPolygonsAsync.value!,
                visitedAsync.value!,
              ),
            ),
          if (visitedAsync.hasValue && visitedAsync.value!.isNotEmpty)
            MarkerLayer(
              markers: visitedAsync.value!
                  .map(_buildMarkerFromIso)
                  .toList(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _searchAndAddCountry,
        tooltip: 'Adicionar país visitado',
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }

  Future<void> _searchAndAddCountry() async {
    final country = await showSearch(
      context: context,
      delegate: CountrySearchDelegate(),
    );

    if (country == null || !mounted) return;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date == null) return;

    await ref.read(userProvider.notifier).addVisitedCountry(
          CountryModel(
            name: country.internationalName,
            isoCode: country.codeShort,
            localization:
                '${country.latLng.latitude}, ${country.latLng.longitude}',
            date: date,
          ),
        );

    _animateTo(
      LatLng(country.latLng.latitude, country.latLng.longitude),
      zoom: _zoomForCountry(country),
    );
  }
}