import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:world_pin/providers/locale_provider.dart';

class LanguageSwitcher extends ConsumerWidget {
  final bool compact;

  const LanguageSwitcher({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isEn = currentLocale.languageCode == 'en';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LangIcon(
          flag: '🇺🇸',
          label: 'EN',
          isSelected: isEn,
          onTap: () =>
              ref.read(localeProvider.notifier).setLocale(const Locale('en')),
        ),
        if (!compact) const SizedBox(width: 4),
        _LangIcon(
          flag: '🇧🇷',
          label: 'PT',
          isSelected: !isEn,
          onTap: () =>
              ref.read(localeProvider.notifier).setLocale(const Locale('pt')),
        ),
      ],
    );
  }
}

class _LangIcon extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangIcon({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.primary : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
