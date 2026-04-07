import 'package:flutter/material.dart';
import 'package:sealed_countries/sealed_countries.dart';

class CountrySearchDelegate extends SearchDelegate<WorldCountry?> {
  static final _allCountries = WorldCountry.list.toList()
    ..sort((a, b) => a.name.common.compareTo(b.name.common));

  @override
  String get searchFieldLabel => 'Search country...';

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
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
            .where((c) => c.name.common.toLowerCase().contains(q))
            .toList();

    if (results.isEmpty) {
      return const Center(child: Text('No countries found.'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final country = results[index];
        return ListTile(
          leading: Text(
            country.emoji,
            style: const TextStyle(fontSize: 24),
          ),
          title: Text(country.internationalName),
          subtitle: Text(
            '${country.latLng.latitude.toStringAsFixed(2)}, ${country.latLng.longitude.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: () => close(context, country),
        );
      },
    );
  }
}
