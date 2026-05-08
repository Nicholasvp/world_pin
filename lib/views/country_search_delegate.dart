import 'package:flutter/material.dart';
import 'package:sealed_countries/sealed_countries.dart';
import 'package:world_pin/l10n/app_localizations.dart';

class CountrySearchDelegate extends SearchDelegate<WorldCountry?> {
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

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final country = results[index];
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          child: ListTile(
            leading: Text(country.emoji, style: const TextStyle(fontSize: 32)),
            title: Text(
              country.internationalName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Clique para selecionar',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () => close(context, country),
          ),
        );
      },
    );
  }
}
