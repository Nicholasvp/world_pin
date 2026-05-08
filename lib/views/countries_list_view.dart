import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sealed_countries/sealed_countries.dart';
import 'package:world_pin/l10n/app_localizations.dart';
import '../providers/visited_countries_provider.dart';
import '../providers/wishlist_countries_provider.dart';

class CountriesListView extends ConsumerWidget {
  const CountriesListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.myTrips),
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.check_circle), text: l10n.visited),
              Tab(icon: const Icon(Icons.star), text: l10n.wishlist),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CountryList(
              asyncValue: ref.watch(visitedCountriesProvider),
              emptyMessage: l10n.emptyVisited,
              accentColor: const Color(0xFF6750A4),
              onRemove: (code) =>
                  ref.read(visitedCountriesProvider.notifier).remove(code),
            ),
            _CountryList(
              asyncValue: ref.watch(wishlistCountriesProvider),
              emptyMessage: l10n.emptyWishlist,
              accentColor: const Color(0xFFD4AF37),
              onRemove: (code) =>
                  ref.read(wishlistCountriesProvider.notifier).remove(code),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryList extends StatelessWidget {
  final AsyncValue<List<String>> asyncValue;
  final String emptyMessage;
  final Color accentColor;
  final Future<void> Function(String) onRemove;

  const _CountryList({
    required this.asyncValue,
    required this.emptyMessage,
    required this.accentColor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (isoCodes) {
        if (isoCodes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: isoCodes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final isoCode = isoCodes[index];
            final country = WorldCountry.maybeFromAnyCode(isoCode);

            if (country == null) return const SizedBox.shrink();

            return Card(
              elevation: 0,
              color: accentColor.withOpacity(0.1),
              child: ListTile(
                leading: Text(
                  country.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                title: Text(
                  country.internationalName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Código: ${country.code}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDeletion(context, country),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err')),
    );
  }

  Future<void> _confirmDeletion(
    BuildContext context,
    WorldCountry country,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeCountry),
        content: Text(l10n.confirmRemove(country.internationalName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await onRemove(country.code);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.removed(country.internationalName))),
        );
      }
    }
  }
}
