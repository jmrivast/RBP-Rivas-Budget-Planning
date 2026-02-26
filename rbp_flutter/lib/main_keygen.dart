import 'package:flutter/material.dart';

import 'ui/screens/keygen_tool_screen.dart';

void main() {
  runApp(const KeygenToolApp());
}

class KeygenToolApp extends StatelessWidget {
  const KeygenToolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RBP Keygen Tool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const KeygenToolScreen(),
    );
  }
}
