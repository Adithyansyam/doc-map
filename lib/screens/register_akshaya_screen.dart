import 'package:flutter/material.dart';
import 'package:akshaya_hub/services/centre_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RegisterAkshayaScreen extends StatefulWidget {
  const RegisterAkshayaScreen({super.key});

  @override
  State<RegisterAkshayaScreen> createState() => _RegisterAkshayaScreenState();
}

class _RegisterAkshayaScreenState extends State<RegisterAkshayaScreen> with SingleTickerProviderStateMixin {
  // Modern Color Scheme
  static const Color primaryBlue = Color(0xFF90CAF9);
  static const Color lightBlue = Color(0xFFBBDEFB);
  static const Color darkBlue = Color(0xFF42A5F5);
  static const Color accentColor = Color(0xFF90CAF9);
  
  final _formKey = GlobalKey<FormState>();
  final _centreNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  
  final _centreService = CentreService();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _centreNameController.dispose();
    _registrationNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _registerCentre() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _centreService.registerCentre(
        centreName: _centreNameController.text.trim(),
        registrationNumber: _registrationNumberController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pinCode: _pinCodeController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Centre registered successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickLocationOnMap() async {
    LatLng? selectedLocation;
    
    // Default to India center or use existing coordinates if available
    LatLng initialCenter = const LatLng(20.5937, 78.9629);
    if (_latitudeController.text.isNotEmpty && _longitudeController.text.isNotEmpty) {
      try {
        initialCenter = LatLng(
          double.parse(_latitudeController.text),
          double.parse(_longitudeController.text),
        );
      } catch (e) {
        // Use default if parsing fails
      }
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        LatLng? tempLocation = initialCenter;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.map, color: primaryBlue, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Pick Location',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: darkBlue,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: lightBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.touch_app, size: 20, color: primaryBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap on the map to select your center location',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Selected coordinates display
                    if (tempLocation != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: primaryBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: primaryBlue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lat: ${tempLocation!.latitude.toStringAsFixed(6)}, Lng: ${tempLocation!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    
                    // Map
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: initialCenter,
                            initialZoom: 13.0,
                            onTap: (tapPosition, point) {
                              setState(() {
                                tempLocation = point;
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.akshaya.hub',
                            ),
                            if (tempLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: tempLocation!,
                                    width: 50,
                                    height: 50,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Color(0xFFCDABFF),
                                      size: 50,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: tempLocation == null
                            ? null
                            : () {
                                selectedLocation = tempLocation;
                                Navigator.of(context).pop();
                              },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'Confirm Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // Update the text fields if a location was selected
    if (selectedLocation != null) {
      setState(() {
        _latitudeController.text = selectedLocation!.latitude.toStringAsFixed(6);
        _longitudeController.text = selectedLocation!.longitude.toStringAsFixed(6);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Location selected successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: primaryBlue),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Register Centre',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          // Header Section
                          _buildHeaderSection(),
                          const SizedBox(height: 30),
                          // Centre Information Card
                          _buildSectionCard(
                            title: 'Centre Information',
                            icon: Icons.business,
                            children: [
                              _buildModernTextField(
                                controller: _centreNameController,
                                label: 'Centre Name',
                                icon: Icons.business_center,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter centre name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _registrationNumberController,
                                label: 'Registration Number',
                                icon: Icons.confirmation_number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter registration number';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Location Details Card
                          _buildSectionCard(
                            title: 'Location Details',
                            icon: Icons.location_on,
                            children: [
                              _buildModernTextField(
                                controller: _addressController,
                                label: 'Address',
                                icon: Icons.home,
                                maxLines: 2,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _cityController,
                                      label: 'City',
                                      icon: Icons.location_city,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _stateController,
                                      label: 'State',
                                      icon: Icons.map,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _pinCodeController,
                                label: 'PIN Code',
                                icon: Icons.pin_drop,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter PIN code';
                                  }
                                  if (value.length != 6) {
                                    return 'PIN code must be 6 digits';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Coordinates Section with Map Picker
                          _buildSectionCard(
                            title: 'Location Coordinates',
                            icon: Icons.map,
                            children: [
                              // Pick Location Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _pickLocationOnMap,
                                  icon: const Icon(Icons.map, color: Colors.white),
                                  label: const Text(
                                    'Pick Location on Map',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Coordinates Display
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _latitudeController,
                                      label: 'Latitude',
                                      icon: Icons.my_location,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        final lat = double.tryParse(value);
                                        if (lat == null || lat < -90 || lat > 90) {
                                          return 'Invalid latitude';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildModernTextField(
                                      controller: _longitudeController,
                                      label: 'Longitude',
                                      icon: Icons.location_on,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        final lng = double.tryParse(value);
                                        if (lng == null || lng < -180 || lng > 180) {
                                          return 'Invalid longitude';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: lightBlue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: primaryBlue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Tap the button above to select your center location on the map',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Contact Information Card
                          _buildSectionCard(
                            title: 'Contact Information',
                            icon: Icons.contact_phone,
                            children: [
                              _buildModernTextField(
                                controller: _contactPersonController,
                                label: 'Contact Person Name',
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter contact person name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _contactPhoneController,
                                label: 'Contact Phone',
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter contact phone';
                                  }
                                  if (value.length != 10) {
                                    return 'Phone number must be 10 digits';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildModernTextField(
                                controller: _contactEmailController,
                                label: 'Contact Email',
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter contact email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          // Submit Button
                          _buildSubmitButton(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.app_registration,
            size: 50,
            color: primaryBlue,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Register Your Akshaya Centre',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: darkBlue,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Fill in the details below to register your centre',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shadowColor: primaryBlue.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: primaryBlue),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildSubmitButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _registerCentre,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryBlue, darkBlue],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Register Centre',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
