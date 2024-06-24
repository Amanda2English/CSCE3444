import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:mapapp/map.dart';

void main() {
  runApp( // Sets MyApp as the root widget
    DevicePreview( // Setting up the Device Preview Package
      enabled: true, // Enables Device Preview
      builder: (context) => const MyApp(), // Sets MyApp() and its widgets as what will be displayed by device preview
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) { // Calling this build function is crucial to creating any widgets on screen
    return MaterialApp( // Sets up a structure to manipulate the root widget (in this case the main screen like overall background color and layout)
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'UNT Utility Finder',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.lightGreen[200],

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
        useMaterial3: true,
      ),
      home: MapPage(),
    );
  }
}

