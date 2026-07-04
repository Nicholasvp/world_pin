import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sealed_countries/sealed_countries.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:world_pin/helpers/country_helper.dart';
import 'package:world_pin/l10n/app_localizations.dart';

class CountrySearchDelegate extends SearchDelegate<WorldCountry?> {
  final List<String> visitedCountryCodes;
  final List<String> wishlistCountryCodes;

  CountrySearchDelegate({
    required this.visitedCountryCodes,
    required this.wishlistCountryCodes,
  });

  static final _allCountries = CountryHelper.allCountries;

  @override
  String get searchFieldLabel => 'Search...';

  void _selectRandomCountry(BuildContext context) {
    final available = _allCountries.where(
      (c) =>
          !visitedCountryCodes.contains(c.code) &&
          !wishlistCountryCodes.contains(c.code),
    ).toList();

    if (available.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.allCountriesAdded)),
      );
      return;
    }

    final random = math.Random();
    final country = available[random.nextInt(available.length)];
    final locale = Localizations.localeOf(context);
    query = countryName(country, locale);
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => query = '',
        ),
      IconButton(
        icon: const Icon(Icons.casino_rounded),
        tooltip: l10n.selectRandomCountry,
        onPressed: () => _selectRandomCountry(context),
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
    final locale = Localizations.localeOf(context);

    final results = q.isEmpty
        ? _allCountries
        : _allCountries.where((c) {
            final name = countryName(c, locale).toLowerCase();
            final intlName = c.internationalName.toLowerCase();
            final commonName = c.name.common.toLowerCase();
            return name.contains(q) ||
                intlName.contains(q) ||
                commonName.contains(q);
          }).toList();

    if (results.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(child: Text(l10n.noCountriesFound));
    }

    final l10n = AppLocalizations.of(context)!;
    final showRandomHeader = q.isEmpty;
    final itemCount = results.length + (showRandomHeader ? 1 : 0);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (showRandomHeader && index == 0) {
          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.casino_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              title: Text(
                l10n.selectRandomCountry,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              subtitle: Text(
                l10n.randomCountry,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
              onTap: () => _selectRandomCountry(context),
            ),
          );
        }

        final countryIndex = showRandomHeader ? index - 1 : index;
        final country = results[countryIndex];
        final isVisited = visitedCountryCodes.contains(country.code);
        final isWishlisted = wishlistCountryCodes.contains(country.code);
        final isAlreadyAdded = isVisited || isWishlisted;
        final displayName = countryName(country, locale);

        String subtitleText;
        Widget? statusWidget;
        if (isVisited) {
          subtitleText = l10n.alreadyVisited;
          statusWidget = const Icon(
            Icons.check_circle,
            color: Color(0xFF6750A4),
          );
        } else if (isWishlisted) {
          subtitleText = l10n.wantToGo;
          statusWidget = const Icon(
            Icons.star,
            color: Color(0xFFD4AF37),
          );
        } else {
          subtitleText = l10n.clickToSelect;
          statusWidget = null;
        }

        final trailingWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blueAccent),
              tooltip: 'More info about $displayName',
              onPressed: () async {
                final url = Uri.parse(
                  'https://www.google.com/search?q=${Uri.encodeComponent(country.internationalName)}',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not launch search'),
                      ),
                    );
                  }
                }
              },
            ),
            if (statusWidget != null) ...[
              const SizedBox(width: 8),
              statusWidget,
            ],
          ],
        );

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
              displayName,
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
