import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:world_pin/l10n/app_localizations.dart';

class MonthYearPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const MonthYearPicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (context) => MonthYearPicker(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }

  @override
  State<MonthYearPicker> createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<MonthYearPicker> {
  late int _selectedMonth;
  late int _selectedYear;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  final List<int> _years = [];
  final List<String> _months = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialDate.month;
    _selectedYear = widget.initialDate.year;

    for (int i = widget.firstDate.year; i <= widget.lastDate.year; i++) {
      _years.add(i);
    }

    final locale = Intl.getCurrentLocale();
    for (int i = 1; i <= 12; i++) {
      _months.add(DateFormat.MMMM(locale).format(DateTime(2024, i)));
    }

    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
    _yearController = FixedExtentScrollController(
      initialItem: _years.indexOf(_selectedYear),
    );
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text(
        'Selecionar Mês/Ano',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        height: 200,
        width: 300,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: CupertinoPicker(
                scrollController: _monthController,
                itemExtent: 45,
                selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                  background: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.1),
                ),
                onSelectedItemChanged: (index) {
                  setState(() => _selectedMonth = index + 1);
                },
                children: _months
                    .map(
                      (m) => Center(
                        child: Text(
                          m[0].toUpperCase() + m.substring(1),
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: CupertinoPicker(
                scrollController: _yearController,
                itemExtent: 45,
                selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                  background: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.1),
                ),
                onSelectedItemChanged: (index) {
                  setState(() => _selectedYear = _years[index]);
                },
                children: _years
                    .map(
                      (y) => Center(
                        child: Text(
                          y.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.cancel,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final result = DateTime(_selectedYear, _selectedMonth);
            // Validar se não é no futuro
            if (result.isAfter(widget.lastDate)) {
              Navigator.pop(context, widget.lastDate);
            } else if (result.isBefore(widget.firstDate)) {
              Navigator.pop(context, widget.firstDate);
            } else {
              Navigator.pop(context, result);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
