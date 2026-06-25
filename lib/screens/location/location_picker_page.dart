import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  LatLng selectedLocation = const LatLng(11.2588, 75.7804);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Location")),

      body: FlutterMap(
        options: MapOptions(
          initialCenter: selectedLocation,

          initialZoom: 15,

          onTap: (tapPosition, point) {
            setState(() {
              selectedLocation = point;
            });
          },
        ),

        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),

          MarkerLayer(
            markers: [
              Marker(
                point: selectedLocation,

                width: 40,
                height: 40,

                child: const Icon(
                  Icons.location_pin,
                  size: 40,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, {
            'lat': selectedLocation.latitude,

            'lng': selectedLocation.longitude,
          });
        },

        label: const Text("Select"),

        icon: const Icon(Icons.check),
      ),
    );
  }
}
