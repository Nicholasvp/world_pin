import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:latlong2/latlong.dart';
import 'package:sealed_countries/sealed_countries.dart' hide LatLng;
import 'package:world_pin/l10n/app_localizations.dart';
import '../controllers/auth_controller.dart';
import '../providers/visited_countries_provider.dart';
import '../providers/wishlist_countries_provider.dart';
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
    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: destination.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: destination.longitude,
    );
    final zoomTween = Tween<double>(begin: camera.zoom, end: zoom);

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

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

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _animateTo(_mapController.camera.center, zoom: currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _animateTo(_mapController.camera.center, zoom: currentZoom - 1);
  }

  void _resetView() {
    _animateTo(const LatLng(20, 0), zoom: 2);
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

  Marker? _buildMarkerFromIso(String isoCode, {bool isWish = false}) {
    final country = WorldCountry.maybeFromAnyCode(isoCode);
    if (country == null) return null;
    return Marker(
      point: LatLng(country.latLng.latitude, country.latLng.longitude),
      width: 40,
      height: 40,
      child: Tooltip(
        message: country.internationalName,
        child: Icon(
          Icons.location_pin,
          color: isWish ? const Color(0xFFD4AF37) : const Color(0xFF6750A4),
          size: 36,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visitedAsync = ref.watch(visitedCountriesProvider);
    final wishlistAsync = ref.watch(wishlistCountriesProvider);
    final worldPolygonsAsync = ref.watch(worldPolygonsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle.toUpperCase()),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: l10n.myTrips,
            onPressed: () => context.push('/list'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
          const SizedBox(width: 8),
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
          if (worldPolygonsAsync.hasValue) ...[
            if (visitedAsync.hasValue)
              PolygonLayer(
                polygons: buildCountryPolygons(
                  worldData: worldPolygonsAsync.value!,
                  isoCodes: visitedAsync.value!,
                  fillColor: const Color(0x556750A4),
                  borderColor: const Color(0xFF6750A4),
                ),
              ),
            if (wishlistAsync.hasValue)
              PolygonLayer(
                polygons: buildCountryPolygons(
                  worldData: worldPolygonsAsync.value!,
                  isoCodes: wishlistAsync.value!,
                  fillColor: const Color(0x55D4AF37),
                  borderColor: const Color(0xFFD4AF37),
                ),
              ),
          ],
          if (visitedAsync.hasValue && visitedAsync.value!.isNotEmpty)
            MarkerLayer(
              markers: visitedAsync.value!
                  .map(_buildMarkerFromIso)
                  .whereType<Marker>()
                  .toList(),
            ),
          if (wishlistAsync.hasValue && wishlistAsync.value!.isNotEmpty)
            MarkerLayer(
              markers: wishlistAsync.value!
                  .map((iso) => _buildMarkerFromIso(iso, isWish: true))
                  .whereType<Marker>()
                  .toList(),
            ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.menu_open_rounded,
        activeIcon: Icons.close_rounded,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        spacing: 12,
        spaceBetweenChildren: 12,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add_location_alt_rounded),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            label: l10n.markCountry,
            onTap: _searchAndAddCountry,
          ),
          SpeedDialChild(
            child: const Icon(Icons.add_rounded),
            backgroundColor: Theme.of(context).colorScheme.surface,
            label: 'Zoom In',
            onTap: _zoomIn,
          ),
          SpeedDialChild(
            child: const Icon(Icons.remove_rounded),
            backgroundColor: Theme.of(context).colorScheme.surface,
            label: 'Zoom Out',
            onTap: _zoomOut,
          ),
          SpeedDialChild(
            child: const Icon(Icons.center_focus_strong_rounded),
            backgroundColor: Theme.of(context).colorScheme.surface,
            label: 'Reset View',
            onTap: _resetView,
          ),
        ],
      ),
    );
  }

  Future<void> _searchAndAddCountry() async {
    final country = await showSearch(
      context: context,
      delegate: CountrySearchDelegate(),
    );

    if (country == null || !mounted) return;

    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.selectDestination(country.internationalName),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6750A4),
                      ),
                      onPressed: () => Navigator.pop(context, 'visited'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(l10n.alreadyVisited),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                      ),
                      onPressed: () => Navigator.pop(context, 'wish'),
                      icon: const Icon(Icons.star_outline),
                      label: Text(l10n.wantToGo),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (choice == null || !mounted) return;

    if (choice == 'visited') {
      final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );

      if (date == null) return;

      await ref.read(visitedCountriesProvider.notifier).add(country.code);
    } else {
      await ref.read(wishlistCountriesProvider.notifier).add(country.code);
    }

    _animateTo(
      LatLng(country.latLng.latitude, country.latLng.longitude),
      zoom: _zoomForCountry(country),
    );
  }
}
