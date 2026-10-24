import 'package:flutter/material.dart';

import '../data/phrases.dart';
import '../theme/word_travels_theme.dart';
import '../widgets/place_picker_sheet.dart';

/// First step of setting up a trip: pick its destination. Required —
/// everything the trip shows is filtered by it.
class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  String? _choice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Where are you using $targetLanguage?', style: ptHeading(size: 24)),
              const SizedBox(height: 10),
              Text(
                'You\'ll get $targetLanguage that works everywhere, plus the words and phrases people use in your country.',
                style: ptBody(size: 14, color: PTColors.inkSoft).copyWith(height: 1.5),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    for (final c in spanishCountries)
                      OptionTile(
                        label: c,
                        selected: _choice == c,
                        onTap: () => setState(() => _choice = c),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PTColors.postal,
                    foregroundColor: const Color(0xFFFBE9E2),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontWeight: FontWeight.w500,
                      fontSize: 14.5,
                    ),
                  ),
                  onPressed: _choice == null
                      ? null
                      : () => widget.onSelected(_choice!),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
