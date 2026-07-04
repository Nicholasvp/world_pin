import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:sealed_countries/sealed_countries.dart' hide LatLng;
import 'package:world_pin/helpers/country_helper.dart';
import 'package:world_pin/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../controllers/auth_controller.dart';
import '../providers/visited_countries_provider.dart';
import '../providers/wishlist_countries_provider.dart';
import '../providers/world_polygons_provider.dart';
import '../providers/avatar_provider.dart';
import '../providers/all_users_provider.dart';
import '../providers/locale_provider.dart';
import 'country_search_delegate.dart';
import '../widgets/month_year_picker.dart';


class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  bool _showOthers = false;
  String? _selectedFriendKey;

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

  Widget _defaultAvatarIcon(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Icon(
        Icons.person_rounded,
        size: 40,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Marker? _buildMarkerFromIso(String isoCode, String? avatarUrl,
      {bool isWish = false, Locale locale = const Locale('en')}) {
    final country = CountryHelper.resolveCountry(isoCode);
    if (country == null) return null;
    final displayName = countryName(country, locale);

    if (isWish) {
      return Marker(
        point: LatLng(country.latLng.latitude, country.latLng.longitude),
        width: 40,
        height: 40,
        child: Tooltip(
          message: displayName,
          child: const Icon(Icons.lock, color: Color(0xFFD4AF37), size: 28),
        ),
      );
    }

    return Marker(
      point: LatLng(country.latLng.latitude, country.latLng.longitude),
      width: 40,
      height: 40,
      child: Tooltip(
        message: displayName,
        child: avatarUrl != null
            ? ClipOval(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, _) {
                      debugPrint('Marker avatar load error: $error');
                      return const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF6750A4),
                        size: 36,
                      );
                    },
                  ),
                ),
              )
            : const Icon(
                Icons.person_rounded,
                color: Color(0xFF6750A4),
                size: 36,
              ),
      ),
    );
  }

  Widget _otherUserFallback(UserPublicProfile user) {
    return Container(
      color: const Color(0xFF6750A4).withOpacity(0.6),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  List<Marker> _buildOtherUserMarkers(List<UserPublicProfile> users) {
    final markers = <Marker>[];
    final countryUsers = <String, List<_CountryUser>>{};

    for (final user in users) {
      for (final isoCode in user.visitedCountries) {
        final country = CountryHelper.resolveCountry(isoCode);
        if (country == null) continue;
        countryUsers.putIfAbsent(isoCode, () => []);
        countryUsers[isoCode]!.add(_CountryUser(user, country));
      }
    }

    for (final entry in countryUsers.entries) {
      final list = entry.value;
      final base = list.first.country;
      final center = LatLng(base.latLng.latitude, base.latLng.longitude);

      for (int i = 0; i < list.length; i++) {
        final cu = list[i];
        final offset = _markerOffset(i, list.length);
        final key = '${cu.user.id}:${entry.key}';
        final isSelected = _selectedFriendKey == key;

        markers.add(
          Marker(
            point: LatLng(center.latitude + offset.latitude,
                center.longitude + offset.longitude),
            width: isSelected ? 120 : 40,
            height: isSelected ? 40 : 40,
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedFriendKey = isSelected ? null : key;
              }),
              child: Row(
                children: [
                  Tooltip(
                    message:
                        '${cu.user.name}: ${countryName(cu.country, Localizations.localeOf(context))}',
                    child: ClipOval(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: cu.user.avatarUrl != null
                            ? Image.network(
                                cu.user.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, _) =>
                                    _otherUserFallback(cu.user),
                              )
                            : _otherUserFallback(cu.user),
                      ),
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26, blurRadius: 2)
                          ],
                        ),
                        child: Text(
                          cu.user.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }
    }
    return markers;
  }

  LatLng _markerOffset(int index, int total) {
    if (total <= 1) return const LatLng(0, 0);
    final radius = 1.0 + (total > 4 ? 0.2 : 0.0);
    final angle = (2 * math.pi * index) / total;
    return LatLng(radius * math.sin(angle), radius * math.cos(angle));
  }

  @override
  Widget build(BuildContext context) {
    final visitedAsync = ref.watch(visitedCountriesProvider);
    final wishlistAsync = ref.watch(wishlistCountriesProvider);
    final worldPolygonsAsync = ref.watch(worldPolygonsProvider);
    final allUsersAsync = ref.watch(allUsersProvider);
    final avatarAsync = ref.watch(avatarProvider);
    final avatarUrl = avatarAsync.valueOrNull;
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
            icon: Icon(
              _showOthers ? Icons.people_alt_rounded : Icons.public_rounded,
              color: _showOthers
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: _showOthers ? l10n.hideOthers : l10n.showAllTravelers,
            onPressed: () => setState(() => _showOthers = !_showOthers),
          ),
          IconButton(
            icon: avatarUrl != null
                ? ClipOval(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, _) {
                          debugPrint('Avatar load error: $error');
                          return const Icon(
                            Icons.account_circle_rounded,
                          );
                        },
                      ),
                    ),
                  )
                : const Icon(Icons.account_circle_rounded),
            tooltip: l10n.profile,
            onPressed: _showProfileSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(20, 0),
          initialZoom: 2,
          minZoom: 1.5,
          maxZoom: 10,
          cameraConstraint: CameraConstraint.contain(
            bounds: LatLngBounds(
              const LatLng(-85.051129, -180),
              const LatLng(85.051129, 180),
            ),
          ),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
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
                  .map((iso) => _buildMarkerFromIso(iso, avatarUrl, locale: Localizations.localeOf(context)))
                  .whereType<Marker>()
                  .toList(),
            ),
          if (wishlistAsync.hasValue && wishlistAsync.value!.isNotEmpty)
            MarkerLayer(
              markers: wishlistAsync.value!
                  .map((iso) => _buildMarkerFromIso(iso, avatarUrl, isWish: true, locale: Localizations.localeOf(context)))
                  .whereType<Marker>()
                  .toList(),
            ),
          if (_showOthers && allUsersAsync.hasValue)
            MarkerLayer(
              markers: _buildOtherUserMarkers(allUsersAsync.value!),
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
                l10n.selectDestination(countryName(country, Localizations.localeOf(context))),
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

    if (choice == 'visited') {
      final date = await MonthYearPicker.show(
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

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    final file = File(picked.path);
    await ref.read(avatarProvider.notifier).upload(file);
  }

  void _showProfileSheet() {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.read(authProvider);
    String userName = '';
    String userEmail = '';
    if (authState is AuthAuthenticated) {
      userEmail = authState.user.email ?? '';
      userName = authState.user.userMetadata?['name'] as String? ??
          userEmail.split('@').first;
    } else {
      final u = Supabase.instance.client.auth.currentUser;
      userEmail = u?.email ?? '';
      userName = u?.userMetadata?['name'] as String? ??
          userEmail.split('@').first;
    }

    final visitedAsync = ref.read(visitedCountriesProvider);
    final visitedCount = visitedAsync.value?.length ?? 0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
          builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final avatarAsync = ref.watch(avatarProvider);
            final avatarUrl = avatarAsync.valueOrNull;

            return Container(
              padding: const EdgeInsets.all(28),
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _pickAndUploadAvatar(),
                    child: Stack(
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: avatarUrl != null
                                ? Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, _) {
                                      debugPrint(
                                        'Profile avatar load error: $error',
                                      );
                                      return _defaultAvatarIcon(context);
                                    },
                                  )
                                : _defaultAvatarIcon(context),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _pickAndUploadAvatar();
                      },
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: Text(l10n.changePhoto),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.language,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _LanguageButton(
                          label: l10n.english,
                          isSelected: Localizations.localeOf(context)
                                  .languageCode ==
                              'en',
                          onTap: () {
                            ref.read(localeProvider.notifier).setLocale(
                              const Locale('en'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LanguageButton(
                          label: l10n.portuguese,
                          isSelected: Localizations.localeOf(context)
                                  .languageCode ==
                              'pt',
                          onTap: () {
                            ref.read(localeProvider.notifier).setLocale(
                              const Locale('pt'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
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
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _confirmDeleteAccount();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        l10n.deleteAccount,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
          },
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

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(
          l10n.deleteAccountConfirmMessage,
          textAlign: TextAlign.center,
        ),
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
                  child: Text(l10n.deleteAccountButton),
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
      try {
        await ref.read(authProvider.notifier).deleteAccount();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.error(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _LanguageButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.check,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountryUser {
  final UserPublicProfile user;
  final WorldCountry country;
  _CountryUser(this.user, this.country);
}
