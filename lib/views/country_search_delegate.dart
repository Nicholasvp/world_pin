import 'package:flutter/material.dart';
import 'package:sealed_countries/sealed_countries.dart';
import 'package:world_pin/l10n/app_localizations.dart';

class CountrySearchDelegate extends SearchDelegate<WorldCountry?> {
  final List<String> visitedCountryCodes;
  final List<String> wishlistCountryCodes;

  CountrySearchDelegate({
    required this.visitedCountryCodes,
    required this.wishlistCountryCodes,
  });

  static final _allCountries = WorldCountry.list.toList()
    ..sort((a, b) => a.name.common.compareTo(b.name.common));

  @override
  String get searchFieldLabel => 'Search...'; // This is hard to localize inside SearchDelegate without passing context to constructor

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_ios_new_rounded),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.toLowerCase();
    final results = q.isEmpty
        ? _allCountries
        : _allCountries
              .where(
                (c) =>
                    c.name.common.toLowerCase().contains(q) ||
                    c.internationalName.toLowerCase().contains(q),
              )
              .toList();

    if (results.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(child: Text(l10n.noCountriesFound));
    }

    final l10n = AppLocalizations.of(context)!;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final country = results[index];
        final isVisited = visitedCountryCodes.contains(country.code);
        final isWishlisted = wishlistCountryCodes.contains(country.code);
        final isAlreadyAdded = isVisited || isWishlisted;

        String subtitleText;
        Widget? trailingWidget;
        if (isVisited) {
          subtitleText = l10n.alreadyVisited;
          trailingWidget = const Icon(
            Icons.check_circle,
            color: Color(0xFF6750A4),
          );
        } else if (isWishlisted) {
          subtitleText = l10n.wantToGo;
          trailingWidget = const Icon(
            Icons.star,
            color: Color(0xFFD4AF37),
          );
        } else {
          subtitleText = l10n.clickToSelect;
          trailingWidget = null;
        }

        return Card(
          elevation: 0,
          color: isAlreadyAdded
              ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          child: ListTile(
            enabled: !isAlreadyAdded,
            leading: Opacity(
              opacity: isAlreadyAdded ? 0.5 : 1.0,
              child: Text(country.emoji, style: const TextStyle(fontSize: 32)),
            ),
            title: Text(
              country.internationalName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isAlreadyAdded ? Colors.grey : null,
              ),
            ),
            subtitle: Text(
              subtitleText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isAlreadyAdded ? Colors.grey : null,
              ),
            ),
            trailing: trailingWidget,
            onTap: isAlreadyAdded ? null : () => close(context, country),
          ),
        );
      },
    );
  }
}
