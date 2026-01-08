import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterAkshayaScreen extends StatefulWidget {
  const RegisterAkshayaScreen({super.key});

  @override
  State<RegisterAkshayaScreen> createState() => _RegisterAkshayaScreenState();
}

class _RegisterAkshayaScreenState extends State<RegisterAkshayaScreen> with SingleTickerProviderStateMixin {
  // 3D Form Color Scheme (matching signup screen)
  static const Color color1 = Color(0xFFD8DAF7);
  static const Color color2 = Color(0xFFC2C5F3);
  static const Color color3 = Color(0xFFADB1EF);
  static const Color color4 = Color(0xFF989DEB);
  static const Color color5 = Color(0xFF6D74E3);
  static const Color buttonColor = Color(0xFF575CB5);
  
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
  
  final _centreNameFocusNode = FocusNode();
  final _registrationNumberFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _cityFocusNode = FocusNode();
  final _stateFocusNode = FocusNode();
  final _pinCodeFocusNode = FocusNode();
  final _contactPersonFocusNode = FocusNode();
  final _contactPhoneFocusNode = FocusNode();
  final _contactEmailFocusNode = FocusNode();
  
  bool _isLoading = false;
  
  // Hover states for 3D effect
  bool _centreNameHover = false;
  bool _registrationNumberHover = false;
  bool _addressHover = false;
  bool _cityHover = false;
  bool _stateHover = false;
  bool _pinCodeHover = false;
  bool _contactPersonHover = false;
  bool _contactPhoneHover = false;
  bool _contactEmailHover = false;
  bool _buttonHover = false;
  
  // Focus states for drawer animation
  bool _centreNameFocused = false;
  bool _registrationNumberFocused = false;
  bool _addressFocused = false;
  bool _cityFocused = false;
  bool _stateFocused = false;
  bool _pinCodeFocused = false;
  bool _contactPersonFocused = false;
  bool _contactPhoneFocused = false;
  bool _contactEmailFocused = false;

  @override
  void initState() {
    super.initState();
    _centreNameFocusNode.addListener(() {
      setState(() {
        _centreNameFocused = _centreNameFocusNode.hasFocus;
      });
    });
    _registrationNumberFocusNode.addListener(() {
      setState(() {
        _registrationNumberFocused = _registrationNumberFocusNode.hasFocus;
      });
    });
    _addressFocusNode.addListener(() {
      setState(() {
        _addressFocused = _addressFocusNode.hasFocus;
      });
    });
    _cityFocusNode.addListener(() {
      setState(() {
        _cityFocused = _cityFocusNode.hasFocus;
      });
    });
    _stateFocusNode.addListener(() {
      setState(() {
        _stateFocused = _stateFocusNode.hasFocus;
      });
    });
    _pinCodeFocusNode.addListener(() {
      setState(() {
        _pinCodeFocused = _pinCodeFocusNode.hasFocus;
      });
    });
    _contactPersonFocusNode.addListener(() {
      setState(() {
        _contactPersonFocused = _contactPersonFocusNode.hasFocus;
      });
    });
    _contactPhoneFocusNode.addListener(() {
      setState(() {
        _contactPhoneFocused = _contactPhoneFocusNode.hasFocus;
      });
    });
    _contactEmailFocusNode.addListener(() {
      setState(() {
        _contactEmailFocused = _contactEmailFocusNode.hasFocus;
      });
    });
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
    
    _centreNameFocusNode.dispose();
    _registrationNumberFocusNode.dispose();
    _addressFocusNode.dispose();
    _cityFocusNode.dispose();
    _stateFocusNode.dispose();
    _pinCodeFocusNode.dispose();
    _contactPersonFocusNode.dispose();
    _contactPhoneFocusNode.dispose();
    _contactEmailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _registerCentre() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Save centre data to Firestore
      await FirebaseFirestore.instance.collection('centres').add({
        'centreName': _centreNameController.text.trim(),
        'registrationNumber': _registrationNumberController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pinCode': _pinCodeController.text.trim(),
        'contactPerson': _contactPersonController.text.trim(),
        'contactPhone': _contactPhoneController.text.trim(),
        'contactEmail': _contactEmailController.text.trim(),
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, approved, rejected
      });

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
            content: Text('Failed to register centre: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8E8E8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: color5),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Modern Header with Animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - value.clamp(0.0, 1.0))),
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          // Stroke/outline effect
                          Text(
                            'Register Akshaya Centre',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              height: 1.2,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 2.5
                                ..color = color5.withOpacity(0.5),
                            ),
                          ),
                          // Main text with gradient-like shadow
                          Text(
                            'Register Akshaya Centre',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: color5,
                              letterSpacing: 1.5,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: color4.withOpacity(0.8),
                                  offset: const Offset(2, 2),
                                  blurRadius: 4,
                                ),
                                Shadow(
                                  color: color3.withOpacity(0.6),
                                  offset: const Offset(4, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Decorative line with gradient
                      Container(
                        width: 100,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              color5,
                              color4,
                              color3,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color5.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // 3D Skewed Form Container
                Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(-0.25),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      // Centre Name Field
                      _build3DInputField(
                        controller: _centreNameController,
                        focusNode: _centreNameFocusNode,
                        hintText: 'Centre Name',
                        backgroundColor: color5,
                        sideColor: color5,
                        topColor: color5,
                        icon: Icons.business,
                        isHovered: _centreNameHover,
                        isFocused: _centreNameFocused,
                        onHoverChange: (hover) => setState(() => _centreNameHover = hover),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter centre name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 0),
                      
                      // Registration Number Field
                      _build3DInputField(
                        controller: _registrationNumberController,
                        focusNode: _registrationNumberFocusNode,
                        hintText: 'Registration Number',
                        backgroundColor: color4,
                        sideColor: color4,
                        topColor: color4,
                        icon: Icons.confirmation_number,
                        isHovered: _registrationNumberHover,
                        isFocused: _registrationNumberFocused,
                        onHoverChange: (hover) => setState(() => _registrationNumberHover = hover),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter registration number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 0),
                      
                      // Address Field
                      _build3DInputField(
                        controller: _addressController,
                        focusNode: _addressFocusNode,
                        hintText: 'Address',
                        backgroundColor: color3,
                        sideColor: color3,
                        topColor: color3,
                        icon: Icons.location_on,
                        isHovered: _addressHover,
                        isFocused: _addressFocused,
                        onHoverChange: (hover) => setState(() => _addressHover = hover),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 0),
                      
                      // City Field
                      _build3DInputField(
                        controller: _cityController,
                        focusNode: _cityFocusNode,
                        hintText: 'City',
                        backgroundColor: color2,
                        sideColor: color2,
                        topColor: color2,
                        icon: Icons.location_city,
                        isHovered: _cityHover,
                        isFocused: _cityFocused,
                        onHoverChange: (hover) => setState(() => _cityHover = hover),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter city';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 0),
                      
                      // State Field
                      _build3DInputField(
                        controller: _stateController,
                        focusNode: _stateFocusNode,
                        hintText: 'State',
                        backgroundColor: color1,
                        sideColor: color1,
                        topColor: color1,
                        icon: Icons.map,
                        isHovered: _stateHover,
                        isFocused: _stateFocused,
                        onHoverChange: (hover) => setState(() => _stateHover = hover),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter state';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 0),
                      
                      // PIN Code Field
                      _build3DInputField(
                        controller: _pinCodeController,
                        focusNode: _pinCodeFocusNode,
                        hintText: 'PIN Code',
                        backgroundColor: color1,
                        sideColor: color1,
                        topColor: color1,
                        icon: Icons.pin_drop,
                        keyboardType: TextInputType.number,
                        isHovered: _pinCodeHover,
                        isFocused: _pinCodeFocused,
                        onHoverChange: (hover) => setState(() => _pinCodeHover = hover),
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
                      const SizedBox(height: 0),
                      
                      // Contact Person Field
                      _build3DInputField(
                        controller: _contactPersonController,
                        focusNode: _contactPersonFocusNode,
                        hintText: 'Contact Person Name',
                        backgroundColor: color2,
                        sideColor: color2,
                        topColor: color2,
                        icon: Icons.person,
                        isHovered: _contactPersonHover,
                        isFocused: _contactPersonFocused,
                        onHoverChange: (hover) => setState(() => _contactPersonHover = hover),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter contact person name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 0),
                      
                      // Contact Phone Field
                      _build3DInputField(
                        controller: _contactPhoneController,
                        focusNode: _contactPhoneFocusNode,
                        hintText: 'Contact Phone',
                        backgroundColor: color3,
                        sideColor: color3,
                        topColor: color3,
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        isHovered: _contactPhoneHover,
                        isFocused: _contactPhoneFocused,
                        onHoverChange: (hover) => setState(() => _contactPhoneHover = hover),
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
                      const SizedBox(height: 0),
                      
                      // Contact Email Field
                      _build3DInputField(
                        controller: _contactEmailController,
                        focusNode: _contactEmailFocusNode,
                        hintText: 'Contact Email',
                        backgroundColor: color4,
                        sideColor: color4,
                        topColor: color4,
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        isHovered: _contactEmailHover,
                        isFocused: _contactEmailFocused,
                        onHoverChange: (hover) => setState(() => _contactEmailHover = hover),
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
                      const SizedBox(height: 0),
                      
                      // Submit Button with 3D effect
                      _build3DButton(
                        onPressed: _isLoading ? null : _registerCentre,
                        text: _isLoading ? 'Registering...' : 'Register Centre',
                        backgroundColor: color5,
                        sideColor: color5,
                        topColor: color5,
                        isHovered: _buttonHover,
                        onHoverChange: (hover) => setState(() => _buttonHover = hover),
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required Color backgroundColor,
    required Color sideColor,
    required Color topColor,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required bool isHovered,
    required bool isFocused,
    required Function(bool) onHoverChange,
  }) {
    // Calculate drawer animation values
    final double drawerOffset = isFocused ? -30.0 : (isHovered ? -20.0 : 0.0);
    final double fieldWidth = isFocused ? 280.0 : 250.0;
    
    return MouseRegion(
      onEnter: (_) => onHoverChange(true),
      onExit: (_) => onHoverChange(false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: isFocused ? 400 : 300),
        curve: isFocused ? Curves.easeOutCubic : Curves.easeInOut,
        transform: Matrix4.identity()
          ..translate(drawerOffset, 0.0, 0.0),
        child: Stack(
          children: [
            // Left side panel (3D effect)
            Positioned(
              left: 0,
              top: 0,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(0.785),
                alignment: Alignment.centerRight,
                child: Container(
                  width: 40,
                  height: 50,
                  decoration: BoxDecoration(
                    color: sideColor.withOpacity(0.8),
                    border: Border.all(color: sideColor, width: 0.5),
                  ),
                ),
              ),
            ),
            
            // Top panel (3D effect)
            Positioned(
              left: 40,
              top: -40,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(0.785),
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: isFocused ? 400 : 300),
                  curve: isFocused ? Curves.easeOutCubic : Curves.easeInOut,
                  width: fieldWidth,
                  height: 40,
                  decoration: BoxDecoration(
                    color: topColor.withOpacity(0.8),
                    border: Border.all(color: topColor, width: 0.5),
                  ),
                ),
              ),
            ),
            
            // Main input field
            AnimatedContainer(
              duration: Duration(milliseconds: isFocused ? 400 : 300),
              curve: isFocused ? Curves.easeOutCubic : Curves.easeInOut,
              margin: const EdgeInsets.only(left: 40),
              width: fieldWidth,
              height: 50,
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: sideColor, width: 0.5),
                boxShadow: isFocused ? [
                  BoxShadow(
                    color: sideColor.withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ] : [],
              ),
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: Icon(icon, color: Colors.black54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: validator,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DButton({
    required VoidCallback? onPressed,
    required String text,
    required Color backgroundColor,
    required Color sideColor,
    required Color topColor,
    required bool isHovered,
    required Function(bool) onHoverChange,
    required bool isLoading,
  }) {
    return MouseRegion(
      onEnter: (_) => onHoverChange(true),
      onExit: (_) => onHoverChange(false),
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.identity()
            ..translate(isHovered ? -20.0 : 0.0, 0.0, 0.0),
          child: Stack(
            children: [
              // Left side panel (3D effect)
              Positioned(
                left: 0,
                top: 0,
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(0.785),
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 40,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isHovered ? buttonColor.withOpacity(0.8) : sideColor.withOpacity(0.8),
                      border: Border.all(
                        color: isHovered ? buttonColor : sideColor,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Top panel (3D effect)
              Positioned(
                left: 40,
                top: -40,
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(0.785),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 250,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isHovered ? buttonColor.withOpacity(0.8) : topColor.withOpacity(0.8),
                      border: Border.all(
                        color: isHovered ? buttonColor : topColor,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Main button
              Container(
                margin: const EdgeInsets.only(left: 40),
                width: 250,
                height: 50,
                decoration: BoxDecoration(
                  color: isHovered ? buttonColor : backgroundColor,
                  border: Border.all(
                    color: isHovered ? buttonColor : sideColor,
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          text,
                          style: const TextStyle(
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
      ),
    );
  }
}
