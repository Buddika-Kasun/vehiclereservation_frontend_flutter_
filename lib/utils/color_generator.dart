import 'package:flutter/material.dart';

class ColorGenerator {
  static final List<Color> _colors = [
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.pink,
    Colors.cyan,
    Colors.deepOrange,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.deepPurple,
    Colors.brown,
    Colors.blueGrey,
  ];

  static Color getRandomColor(String text) {
    if (text.isEmpty) return Colors.grey;
    
    // Generate consistent color based on text
    final index = text.codeUnits.fold(0, (a, b) => a + b) % _colors.length;
    return _colors[index];
  }

  static Color getRandomColorFromIndex(int index) {
    return _colors[index % _colors.length];
  }

  static List<Color> get availableColors => _colors;

  static Color getRandomColorWithSeed(String seed) {
    if (seed.isEmpty) return Colors.grey;
    
    final hash = seed.codeUnits.fold(0, (a, b) => a + b);
    return _colors[hash % _colors.length];
  }
}