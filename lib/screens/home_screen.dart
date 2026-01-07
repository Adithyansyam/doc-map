import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../widgets/homepage_navbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final user = FirebaseAuth.instance.currentUser;
  
  // Location tracking variables
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  bool _isLoadingLocation = false;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Show location permission dialog when app opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLocationPermissionDialog();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permissions and location when app comes to foreground
      if (_currentLocation == null) {
        _requestLocationPermission();
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _showLocationPermissionDialog() async {
    // Check if location permission is already granted
    final status = await Permission.location.status;
    
    if (status.isGranted) {
      // If already granted, get location directly
      _getCurrentLocation();
      return;
    }

    if (!mounted) return;

    // Show dialog asking user to turn on location
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFF9C27B0), size: 28),
                SizedBox(width: 10),
                Text('Enable Location'),
              ],
            ),
            content: Text(
              'This app requires access to your location to function. Please grant location permission.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _requestLocationPermission();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF9C27B0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Grant Permission',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    
    if (status.isGranted) {
      _getCurrentLocation();
    } else if (status.isDenied) {
      _showPermissionDeniedDialog();
    } else if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
        });
        // Forcefully navigate to location settings
        _forceOpenLocationSettings();
        return;
      }
      
      // If dialog was showing and service is now enabled, close it
      if (_isDialogShowing && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _isDialogShowing = false;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Animate map to user's location
      _mapController.move(_currentLocation!, 15.0);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Location found!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPermissionDeniedDialog() {
    if (!mounted || _isDialogShowing) return;
    
    _isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text('Permission Required'),
            content: Text(
              'Location permission is required to use this app.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  _isDialogShowing = false;
                  _requestLocationPermission();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOpenSettingsDialog() {
    if (!mounted || _isDialogShowing) return;
    
    _isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text('Location Permission Required'),
            content: Text(
              'Location permission is permanently denied. You MUST enable it in app settings to use this app.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  // Don't pop here, wait for resume
                  openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                ),
                child: Text('Open Settings'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _forceOpenLocationSettings() async {
    if (!mounted || _isDialogShowing) return;
    
    _isDialogShowing = true;
    
    // Immediately open location settings
    await Geolocator.openLocationSettings();
    
    // Show a persistent dialog that explains what's happening
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Prevent back button
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.location_off, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Text('Location Required'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location services are disabled. This app requires location to function.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF9C27B0)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please enable location in the settings that just opened.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  // Open settings again if user needs it
                  await Geolocator.openLocationSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                ),
                child: Text('Open Settings Again'),
              ),
              TextButton(
                onPressed: () async {
                  // Check if location is now enabled
                  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                  if (serviceEnabled) {
                    Navigator.of(context, rootNavigator: true).pop();
                    _isDialogShowing = false;
                    _getCurrentLocation();
                  } else {
                    // Show a snackbar if still disabled
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Location is still disabled. Please enable it to continue.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                child: Text(
                  'I\'ve Enabled It',
                  style: TextStyle(color: Color(0xFF9C27B0)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeContent() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(20.5937, 78.9629), // Center of India, customize as needed
            initialZoom: 5.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.akshaya.hub',
              maxZoom: 19,
              tileBuilder: (context, widget, tile) {
                return ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.transparent,
                    BlendMode.multiply,
                  ),
                  child: widget,
                );
              },
            ),
            // User location marker
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 80,
                    height: 80,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'You are here',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9C27B0),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.location_pin,
                          color: Color(0xFF9C27B0),
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
        // Loading indicator
        if (_isLoadingLocation)
          Container(
            color: Colors.black26,
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF9C27B0),
                      ),
                      SizedBox(height: 16),
                      Text('Getting your location...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Floating action button to re-center on user location
        if (_currentLocation != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () {
                _mapController.move(_currentLocation!, 15.0);
              },
              backgroundColor: Color(0xFF9C27B0),
              child: Icon(Icons.my_location, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileContent() {
    // Navigate to dedicated ProfileScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentIndex == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        ).then((_) {
          // Reset to home tab when returning from profile
          setState(() {
            _currentIndex = 0;
          });
        });
      }
    });
    
    return Container(
      color: Colors.white,
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF9C27B0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0 ? _buildHomeContent() : _buildProfileContent(),
      bottomNavigationBar: HomePageNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}