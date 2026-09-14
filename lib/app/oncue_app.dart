import 'package:flutter/material.dart';

final class OnCueApp extends StatelessWidget {
  const OnCueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnCue',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const Scaffold(body: Center(child: Text('OnCue'))),
    );
  }
}
