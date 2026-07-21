import 'package:flutter/material.dart';

import 'screens/category_list_screen.dart';

void main() {
  runApp(const AroundTheWordApp());
}

class AroundTheWordApp extends StatelessWidget {
  const AroundTheWordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Around the Word',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CategoryListScreen(),
    );
  }
}
