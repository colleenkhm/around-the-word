import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/trip_selection.dart';
import 'learn_use_screen.dart';

/// Screen 4: cosmetic "personalizing your dictionary" step.
class PersonalizingScreen extends StatefulWidget {
  const PersonalizingScreen({super.key});

  @override
  State<PersonalizingScreen> createState() => _PersonalizingScreenState();
}

class _PersonalizingScreenState extends State<PersonalizingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    await context.read<TripSelection>().personalize();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LearnUseScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Personalizing your dictionary...'),
          ],
        ),
      ),
    );
  }
}
