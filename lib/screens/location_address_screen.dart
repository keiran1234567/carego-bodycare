import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/app_store.dart';

class LocationAddressScreen extends StatefulWidget {
  const LocationAddressScreen({super.key});

  @override
  State<LocationAddressScreen> createState() => _LocationAddressScreenState();
}

class _LocationAddressScreenState extends State<LocationAddressScreen> {
  final store = AppStore.instance;
  final mapController = MapController();
  final label = TextEditingController(text: 'Rumah');
  final address = TextEditingController();
  LatLng? point;
  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _useCurrentLocation();
  }

  @override
  void dispose() {
    label.dispose();
    address.dispose();
    mapController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        final open = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.location_off_rounded, size: 42),
            title: const Text('Aktifkan lokasi HP'),
            content: const Text(
              'CareGo membutuhkan GPS/lokasi aktif untuk menentukan titik alamat Anda.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Buka Pengaturan Lokasi'),
              ),
            ],
          ),
        );
        if (open != true) {
          throw Exception('Lokasi HP belum diaktifkan.');
        }
        await Geolocator.openLocationSettings();
        if (!await Geolocator.isLocationServiceEnabled()) {
          throw Exception('Aktifkan lokasi HP, lalu tekan tombol coba lagi.');
        }
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        throw Exception(
            'Izinkan akses lokasi CareGo dari pengaturan aplikasi, lalu coba lagi.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final mapAlreadyVisible = point != null;
      await _selectPoint(LatLng(position.latitude, position.longitude),
          moveMap: mapAlreadyVisible);
    } catch (exception) {
      if (mounted) {
        setState(
            () => error = exception.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _selectPoint(LatLng selected, {bool moveMap = false}) async {
    setState(() => point = selected);
    if (moveMap) {
      mapController.move(selected, 17);
    }
    try {
      final places =
          await placemarkFromCoordinates(selected.latitude, selected.longitude);
      if (places.isEmpty) return;
      final place = places.first;
      final parts = [
        place.street,
        place.subLocality,
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
        place.postalCode,
      ].where((value) => value != null && value.trim().isNotEmpty);
      address.text = parts.join(', ');
    } catch (_) {
      address.text =
          '${selected.latitude.toStringAsFixed(7)}, ${selected.longitude.toStringAsFixed(7)}';
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (point == null ||
        label.text.trim().isEmpty ||
        address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Pilih titik peta dan lengkapi alamat terlebih dahulu.')));
      return;
    }
    setState(() => saving = true);
    try {
      await store.addAddress(
        label: label.text.trim(),
        address: address.text.trim(),
        latitude: point!.latitude,
        longitude: point!.longitude,
        primary: store.addresses.isEmpty,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$exception')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Lokasi Alamat')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: point == null
                  ? Center(
                      child: loading
                          ? const CircularProgressIndicator()
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_off_outlined,
                                      size: 64),
                                  const SizedBox(height: 12),
                                  Text(error ?? 'Lokasi belum tersedia.',
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: _useCurrentLocation,
                                    icon: const Icon(Icons.my_location_rounded),
                                    label: const Text('Aktifkan dan Coba Lagi'),
                                  ),
                                ],
                              ),
                            ),
                    )
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: point!,
                            initialZoom: 17,
                            onTap: (_, selected) => _selectPoint(selected),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.bodycare_home_service',
                            ),
                            MarkerLayer(markers: [
                              Marker(
                                point: point!,
                                width: 54,
                                height: 54,
                                child: const Icon(Icons.location_pin,
                                    color: Color(0xFF6138E5), size: 54),
                              ),
                            ]),
                          ],
                        ),
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: FloatingActionButton.small(
                            heroTag: 'current-location',
                            onPressed: loading ? null : _useCurrentLocation,
                            child: const Icon(Icons.my_location_rounded),
                          ),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  TextField(
                    controller: label,
                    decoration: const InputDecoration(
                        labelText: 'Label alamat',
                        prefixIcon: Icon(Icons.bookmark_outline_rounded)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: address,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Alamat hasil lokasi',
                        helperText:
                            'Ketuk peta untuk memperbaiki titik lokasi.',
                        prefixIcon: Icon(Icons.location_on_outlined)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: saving ? null : _save,
                      icon: saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_outlined),
                      label: Text(saving ? 'Menyimpan...' : 'Simpan Alamat'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
