import 'package:flutter/material.dart';

void main() {
  runApp(const PoleSafetyApp());
}

class PoleSafetyApp extends StatelessWidget {
  const PoleSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electric Pole Safety',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'Electric Pole Safety Platform\n(Mobile Scaffold Ready)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
