import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

class CustomMarker {
  final String id;
  final LatLng position;
  final String title;
  final String iconPath;
  final String type;
  BitmapDescriptor? icon; // Nullable to be set later
  bool isVisible;

  CustomMarker({
    required this.id,
    required this.position,
    required this.title,
    required this.iconPath,
    required this.type,
    this.icon, // Nullable to be set later
    this.isVisible = true,
  });
}

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  TextEditingController searchController = TextEditingController();
  List<CustomMarker> customMarkers = [];
  List<CustomMarker> suggestions = []; // List for autocomplete suggestions
  CustomMarker? selectedMarker; // Initialize selectedMarker

  // Checkboxes state
  bool isMicrowavesChecked = true;
  bool isVendingMachinesChecked = true;
  bool isChargingStationsChecked = true;

  bool showContainer = false; // Toggle filter menu

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    try {
      String data = await rootBundle.loadString('assets/markers_data.json');
      List<dynamic> markersJson = jsonDecode(data);

      setState(() {
        customMarkers = markersJson.map((json) {
          return CustomMarker(
            id: json['id'],
            position: LatLng(
              json['position']['latitude'],
              json['position']['longitude'],
            ),
            title: json['title'],
            iconPath: json['iconPath'],
            type: json['type'],
            isVisible: true,
          );
        }).toList();

        _loadMarkerIcons(); // Load marker icons after setting up markers
      });
    } catch (e) {
      print('Error loading markers: $e');
    }
  }

  Future<void> _loadMarkerIcons() async {
    // Load icons for each custom marker
    for (CustomMarker marker in customMarkers) {
      ByteData byteData = await rootBundle.load(marker.iconPath);
      Uint8List byteList = byteData.buffer.asUint8List();
      BitmapDescriptor bitmapDescriptor = BitmapDescriptor.fromBytes(byteList);

      setState(() {
        marker.icon = bitmapDescriptor;
      });
    }
  }

  void _updateMarkerVisibility() {
    setState(() {
      customMarkers = customMarkers.map((customMarker) {
        bool isVisible = true;

        // Check visibility based on marker type
        switch (customMarker.type) {
          case 'vending machine':
            isVisible = isVendingMachinesChecked;
            break;
          case 'charging station':
            isVisible = isChargingStationsChecked;
            break;
          case 'microwave':
            isVisible = isMicrowavesChecked;
            break;
          // Add cases for more types as needed
        }

        return CustomMarker(
          id: customMarker.id,
          position: customMarker.position,
          title: customMarker.title,
          iconPath: customMarker.iconPath,
          type: customMarker.type,
          icon: customMarker.icon, // Retain original loaded icon
          isVisible: isVisible,
        );
      }).toList();
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        _buildMap(),
        _buildCustomTitleBar(),
        GestureDetector(
          onTap: () {
            // Close filter menu when tapping anywhere on the screen
            setState(() {
              showContainer = false;
            });
          },
          child: Container(
            color: Colors.transparent,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            // This GestureDetector captures taps on the whole screen
          ),
        ),
        Positioned(
          top: 225, // Adjust top position as needed
          right: 20, // Align with the top right corner
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                // Toggle filter menu visibility
                showContainer = !showContainer;
              });
            },
            child: Icon(Icons.menu),
          ),
        ),
        if (showContainer) _buildFilterMenu(),
        _buildSearchBar(), // Ensure search bar is on top
        if (suggestions.isNotEmpty) _buildAutoCompleteSuggestions(),
      ],
    ),
  );
}


  Widget _buildMap() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 10), // Move down by 25 pixels
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95, // 95% of screen width
          height: MediaQuery.of(context).size.height * 0.5, // 50% of screen height
          decoration: BoxDecoration(
            border: Border.all(
              color: Color.fromARGB(255, 11, 68, 15),
              width: 3.0,
            ),
          ),
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              
              target: LatLng(33.21075, -97.14727), // Default to Google Plex
              zoom: 18,
            ),
            markers: Set<Marker>.of(customMarkers.where((marker) => marker.isVisible).map((marker) {
              return Marker(
                markerId: MarkerId(marker.id),
                position: marker.position,
                infoWindow: InfoWindow(title: marker.title),
                icon: marker.icon ?? BitmapDescriptor.defaultMarker, // Use custom icon if available, else default marker
                visible: true,
              );
            })),
          ),
        ),
      ),
    );
  }

Widget _buildCustomTitleBar() {
  return Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: Container(
      height: MediaQuery.of(context).size.height * 0.10, // 10% of screen height
      color: Colors.green[900], // Dark green color
      child: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.15, // 15% of screen width for image
            margin: EdgeInsets.only(top: 5, left: 20), // Adjust margin as needed
            child: Image.asset('assets/images/logo.png'), // Replace with your image asset
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 30), // Adjust padding as needed
                child: Text(
                  'UNT   Utility   Finder', // Title text
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3, // Adjust letter spacing
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


Widget _buildSearchBar() {
  return Positioned(
    top: MediaQuery.of(context).size.height * 0.10 + 30, // 10% from top + 30 pixels down
    left: 10,
    right: 10,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.lightGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color.fromARGB(255, 11, 68, 15),
          width: 2.0,
        ),
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search UNT Buildings',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8), // Adjust padding as needed
        ),
        onChanged: (value) {
          _onSearchTextChanged(value);
        },
      ),
    ),
  );
}

Widget _buildFilterMenu() {
  return Positioned(
    top: 225,
    right: 20,
    child: Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.lightGreen,
        border: Border.all(
          color: Color.fromARGB(255, 11, 68, 15), // Dark green border color
          width: 2.0, // Border width
        ),
      ),
      width: 215, // Example width
      height: 214, // Example height
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            title: Text('Microwaves'),
            value: isMicrowavesChecked,
            onChanged: (value) {
              setState(() {
                isMicrowavesChecked = value ?? false;
                _updateMarkerVisibility();
              });
            },
          ),
          CheckboxListTile(
            title: Text('Vending Machines'),
            value: isVendingMachinesChecked,
            onChanged: (value) {
              setState(() {
                isVendingMachinesChecked = value ?? false;
                _updateMarkerVisibility();
              });
            },
          ),
          CheckboxListTile(
            title: Text('Charging Stations'),
            value: isChargingStationsChecked,
            onChanged: (value) {
              setState(() {
                isChargingStationsChecked = value ?? false;
                _updateMarkerVisibility();
              });
            },
          ),
        ],
             ),
      ),
    );
}


Widget _buildAutoCompleteSuggestions() {
  return Positioned(
    top: MediaQuery.of(context).size.height * 0.19, // 19% from top
    left: 10,
    right: 10,
    child: GestureDetector(
      onTap: () {
        // Hide suggestions when tapping outside the menu
        setState(() {
          suggestions = [];
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.lightGreen, // Light green background color
          border: Border(
            left: BorderSide(color: Color.fromARGB(255, 11, 68, 15), width: 2.0),
            right: BorderSide(color: Color.fromARGB(255, 11, 68, 15), width: 2.0),
            bottom: BorderSide(color: Color.fromARGB(255, 11, 68, 15), width: 2.0),
          ),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(suggestions[index].id),
              onTap: () {
                _handleMarkerSearch(suggestions[index]);
              },
            );
          },
        ),
      ),
    ),
  );
}


void _onSearchTextChanged(String value) {
  setState(() {
    suggestions = customMarkers.where((marker) =>
        marker.id.toLowerCase().contains(value.toLowerCase())).toList();
  });
}

void _handleMarkerSearch(CustomMarker marker) {
  searchController.text = marker.id; // Update search field text
  setState(() {
    selectedMarker = marker;
    suggestions = []; // Clear suggestions
  });
  _goToMarker(marker);
}

void _goToMarker(CustomMarker marker) {
  mapController.animateCamera(CameraUpdate.newLatLng(marker.position));
}

void _onMapCreated(GoogleMapController controller) {
  setState(() {
    mapController = controller;
  });
}
}

