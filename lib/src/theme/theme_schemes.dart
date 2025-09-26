import 'package:flutter/material.dart';


/// Light/Dark schemes matched to your AgentHome palette.
final Color seed = const Color(0xFF6C63FF); // tweak if you like


final ThemeData appLight = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
);


final ThemeData appDark = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
);