import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

import '../theme/word_travels_theme.dart';
import '../widgets/place_picker_sheet.dart';

/// Second step of setting up a trip: anything it won't involve.
///
/// Everything starts on, so skipping this is the right answer for most
/// people and costs them nothing — it's here for the traveler who already
/// knows they don't want half the phrasebook in their practice sessions.
class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({super.key, required this.onDone});

  /// The tags to mute on the new trip — empty when nothing was switched off.
  final ValueChanged<Set<String>> onDone;

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  final Set<String> _muted = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Anything you won\'t need?', style: ptHeading(size: 24)),
              const SizedBox(height: 10),
              Text(
                'You\'ll get the whole phrasebook either way. Switching something off just keeps it out of practice, so you drill what the trip actually calls for. Skip this if you\'re not sure — it\'s all editable from the top right.',
                style: ptBody(size: 14, color: PTColors.inkSoft).copyWith(height: 1.5),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    TagMutePicker(
                      muted: _muted,
                      onChanged: () => setState(() {}),
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
                      fontFamily: AccordionTheme.dmSans,
                      fontWeight: FontWeight.w500,
                      fontSize: 14.5,
                    ),
                  ),
                  onPressed: () => widget.onDone(_muted),
                  child: Text(_muted.isEmpty ? 'Skip' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
