import 'package:flutter/material.dart';
import 'package:oncue_mobile/combination/presentation/combination_list_page.dart';

final class OnCueApp extends StatelessWidget {
  const OnCueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnCue',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const CombinationListPage(),
    );
  }
}
