import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:latlong2/latlong.dart';
import 'package:sealed_countries/sealed_countries.dart' hide LatLng;
import 'package:world_pin/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../controllers/auth_controller.dart';
import '../providers/visited_countries_provider.dart';
import '../providers/wishlist_countries_provider.dart';
import '../providers/world_polygons_provider.dart';
import 'country_search_delegate.dart';
import '../providers/premium_provider.dart';
import '../providers/config_provider.dart';
import '../services/premium_service.dart';
import '../widgets/month_year_picker.dart';


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
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            isPremium ? Icons.verified_user_rounded : Icons.star_rounded,
            color: isPremium ? Colors.green : Colors.amber,
          ),
          tooltip: isPremium ? 'Premium Active' : 'Go Premium',
          onPressed: () {
            if (isPremium) {
              PremiumService.showCustomerCenter();
            } else {
              ref.read(premiumProvider.notifier).purchaseFullAccess();
            }
          },
        ),
        title: Text(l10n.appTitle.toUpperCase()),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: l10n.myTrips,
            onPressed: () => context.push('/list'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            tooltip: l10n.profile,
            onPressed: _showProfileSheet,
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
            userAgentPackageName: 'com.nicholasvp.worldpin',
          ),
          if (worldPolygonsAsync.hasValue)
            PolygonLayer(
              polygons: [
                if (visitedAsync.hasValue)
                  ...buildCountryPolygons(
                    worldData: worldPolygonsAsync.value!,
                    isoCodes: visitedAsync.value!,
                    fillColor: const Color(0x556750A4),
                    borderColor: const Color(0xFF6750A4),
                  ),
                if (wishlistAsync.hasValue)
                  ...buildCountryPolygons(
                    worldData: worldPolygonsAsync.value!,
                    isoCodes: wishlistAsync.value!,
                    fillColor: const Color(0x55D4AF37),
                    borderColor: const Color(0xFFD4AF37),
                  ),
              ],
            ),
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
    final visitedCodes = ref.read(visitedCountriesProvider).value ?? [];
    final wishlistCodes = ref.read(wishlistCountriesProvider).value ?? [];

    final country = await showSearch(
      context: context,
      delegate: CountrySearchDelegate(
        visitedCountryCodes: visitedCodes,
        wishlistCountryCodes: wishlistCodes,
      ),
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
                      label: Text(
                        l10n.alreadyVisited,
                        style: TextStyle(fontSize: 12),
                      ),
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
                      label: Text(
                        l10n.wantToGo,
                        style: TextStyle(fontSize: 12),
                      ),
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

    final isPremium = ref.read(premiumProvider);

    if (choice == 'visited') {
      if (!isPremium) {
        final limit = await ref.read(configLimitProvider.future);
        if (visitedCodes.length >= limit) {
          if (mounted) {
            await ref.read(premiumProvider.notifier).purchaseFullAccess();
          }
          return;
        }
      }

      final date = await MonthYearPicker.show(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );

      if (date == null) return;

      await ref.read(visitedCountriesProvider.notifier).add(country.code);
    } else {
      if (!isPremium) {
        final limit = await ref.read(configLimitProvider.future);
        if (wishlistCodes.length >= limit) {
          if (mounted) {
            await ref.read(premiumProvider.notifier).purchaseFullAccess();
          }
          return;
        }
      }

      await ref.read(wishlistCountriesProvider.notifier).add(country.code);
    }

    _animateTo(
      LatLng(country.latLng.latitude, country.latLng.longitude),
      zoom: _zoomForCountry(country),
    );
  }

  void _showProfileSheet() {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.read(authProvider);
    String userEmail = '';
    if (authState is AuthAuthenticated) {
      userEmail = authState.user.email ?? '';
    } else {
      userEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    }

    final visitedAsync = ref.read(visitedCountriesProvider);
    final visitedCount = visitedAsync.value?.length ?? 0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userEmail,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.visitedCountriesLabel,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6750A4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF6750A4),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$visitedCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6750A4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmSignOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(
                    l10n.logout,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: Colors.red),
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage, textAlign: TextAlign.center),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.logout),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ref.read(authProvider.notifier).signOut();
    }
  }
}
