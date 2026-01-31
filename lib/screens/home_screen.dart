import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'profile_screen.dart';
import 'my_centers_screen.dart';
import 'new_page_screen.dart';
import '../widgets/homepage_navbar.dart';
import '../widgets/center_drawer.dart';
import '../services/centre_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final user = FirebaseAuth.instance.currentUser;
  final _centreService = CentreService();
  
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
    if (index == 1) {
      // Navigate to My Centers Screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyCentersScreen()),
      );
    } else if (index == 2) {
      // Navigate to Profile Screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else if (index == 3) {
      // Navigate to New Page Screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NewPageScreen()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
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
                Icon(Icons.location_on, color: Color(0xFF1E88E5), size: 28),
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
                  backgroundColor: Color(0xFF1E88E5),
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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
                  backgroundColor: Color(0xFF1E88E5),
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
                  backgroundColor: Color(0xFF1E88E5),
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
    
    if (!mounted) return;
    
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
                      Icon(Icons.info_outline, color: Color(0xFF1E88E5)),
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
                  backgroundColor: Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                ),
                child: Text('Open Settings Again'),
              ),
              TextButton(
                onPressed: () async {
                  // Check if location is now enabled
                  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                  if (serviceEnabled) {
                    if (!context.mounted) return;
                    Navigator.of(context, rootNavigator: true).pop();
                    _isDialogShowing = false;
                    _getCurrentLocation();
                  } else {
                    // Show a snackbar if still disabled
                    if (!context.mounted) return;
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
                  style: TextStyle(color: Color(0xFF1E88E5)),
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
        // Map Layer
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
                              color: Color(0xFF1E88E5),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.location_pin,
                          color: Color(0xFF1E88E5),
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            // User's registered center marker (shown regardless of approval status)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _centreService.getUserCentresStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SizedBox.shrink();
                }

                final userCenter = snapshot.data!.first;
                if (userCenter['latitude'] == null || userCenter['longitude'] == null) {
                  return SizedBox.shrink();
                }

                return MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        userCenter['latitude'] as double,
                        userCenter['longitude'] as double,
                      ),
                      width: 80,
                      height: 80,
                      child: GestureDetector(
                        onTap: () => _showCenterInfo(userCenter),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFCDABFF), Color(0xFFB896E8)],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFCDABFF).withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Color(0xFFCDABFF),
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
                                'My Center',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Other approved centers markers
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _centreService.getAllCentersStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SizedBox.shrink();
                }

                final centers = snapshot.data!;
                // Filter out user's own center to avoid duplicate markers
                final otherCenters = centers.where((center) {
                  return center['userId'] != user?.uid;
                }).toList();

                final markers = otherCenters
                    .where((center) => 
                        center['latitude'] != null && 
                        center['longitude'] != null)
                    .map((center) {
                  return Marker(
                    point: LatLng(
                      center['latitude'] as double,
                      center['longitude'] as double,
                    ),
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _showCenterInfo(center),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Color(0xFFCDABFF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.business,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(height: 2),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              center['centreName'] ?? '',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFCDABFF),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList();

                return MarkerLayer(markers: markers);
              },
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
                        color: Color(0xFF1E88E5),
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
              backgroundColor: Color(0xFF1E88E5),
              child: Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        // Pull-up drawer
        CenterDrawer(userLocation: _currentLocation),
      ],
    );
  }

  void _showCenterInfo(Map<String, dynamic> center) {
    final status = center['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFCDABFF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.business,
                    color: Color(0xFFCDABFF),
                    size: 30,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        center['centreName'] ?? 'Unknown Center',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB896E8),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            center['registrationNumber'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildInfoRow(Icons.location_on, 'Address', 
                '${center['address']}, ${center['city']}, ${center['state']} - ${center['pinCode']}'),
            SizedBox(height: 12),
            _buildInfoRow(Icons.person, 'Contact Person', center['contactPerson'] ?? 'N/A'),
            SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'Phone', center['contactPhone'] ?? 'N/A'),
            SizedBox(height: 12),
            _buildInfoRow(Icons.email, 'Email', center['contactEmail'] ?? 'N/A'),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFCDABFF),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Color(0xFFCDABFF)),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always show home content since other tabs navigate to separate screens
    return Scaffold(
      body: _buildHomeContent(),
      bottomNavigationBar: HomePageNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
