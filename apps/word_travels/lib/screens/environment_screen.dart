import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/phrases.dart';
import '../state/location_settings.dart';
import '../theme/pocket_talk_theme.dart';
import '../widgets/place_picker_sheet.dart';

/// First-launch step after choosing a country: what kinds of setting the user
/// will be in. Pick any number, or none — this only adds vocab, it never
/// hides the language-wide basics.
class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({super.key});

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  final Set<String> _choices = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What will it be like there?', style: ptHeading(size: 24)),
              const SizedBox(height: 10),
              Text(
                'Pick everything that applies, like a coastal city. We\'ll add vocab for those places. You can change this any time from the top right.',
                style: ptBody(size: 14, color: PTColors.inkSoft).copyWith(height: 1.5),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    for (final e in environmentOptions)
                      OptionTile(
                        label: e.name,
                        description: e.description,
                        selected: _choices.contains(e.name),
                        onTap: () => setState(() {
                          if (!_choices.remove(e.name)) _choices.add(e.name);
                        }),
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
                  onPressed: () => context.read<LocationSettings>().setEnvironments(_choices),
                  child: Text(_choices.isEmpty ? 'Skip' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
