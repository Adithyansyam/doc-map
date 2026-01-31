import 'package:flutter/material.dart';
import 'package:akshaya_hub/services/user_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  // 3D Form Color Scheme (5 levels for signup)
  static const Color color1 = Color(0xFFD8DAF7);
  static const Color color2 = Color(0xFFC2C5F3);
  static const Color color3 = Color(0xFFADB1EF);
  static const Color color4 = Color(0xFF989DEB);
  static const Color color5 = Color(0xFF6D74E3);
  static const Color buttonColor = Color(0xFF575CB5);
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  
  final _userService = UserService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Hover states for 3D effect
  bool _nameHover = false;
  bool _emailHover = false;
  bool _phoneHover = false;
  bool _passwordHover = false;
  bool _confirmPasswordHover = false;
  bool _buttonHover = false;
  
  // Focus states for drawer animation
  bool _nameFocused = false;
  bool _emailFocused = false;
  bool _phoneFocused = false;
  bool _passwordFocused = false;
  bool _confirmPasswordFocused = false;

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() {
      setState(() {
        _nameFocused = _nameFocusNode.hasFocus;
      });
    });
    _emailFocusNode.addListener(() {
      setState(() {
        _emailFocused = _emailFocusNode.hasFocus;
      });
    });
    _phoneFocusNode.addListener(() {
      setState(() {
        _phoneFocused = _phoneFocusNode.hasFocus;
      });
    });
    _passwordFocusNode.addListener(() {
      setState(() {
        _passwordFocused = _passwordFocusNode.hasFocus;
      });
    });
    _confirmPasswordFocusNode.addListener(() {
      setState(() {
        _confirmPasswordFocused = _confirmPasswordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // Modern Create Account Header with Animation
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
                      // Create Account text without background
                      Stack(
                        children: [
                          // Stroke/outline effect
                          Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              height: 1.2,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 2.5
                                ..color = color5.withValues(alpha: 0.5),
                            ),
                          ),
                          // Main text with gradient-like shadow
                          Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: color5,
                              letterSpacing: 1.5,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: color4.withValues(alpha: 0.8),
                                  offset: const Offset(2, 2),
                                  blurRadius: 4,
                                ),
                                Shadow(
                                  color: color3.withValues(alpha: 0.6),
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
                              color: color5.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                // 3D Skewed Form Container
                Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(-0.25),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      // Name Field with 3D effect
                      _build3DInputField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        hintText: 'Full Name',
                        backgroundColor: color4,
                        sideColor: color4,
                        topColor: color4,
                        icon: Icons.person,
                        isHovered: _nameHover,
                        isFocused: _nameFocused,
                        onHoverChange: (hover) => setState(() => _nameHover = hover),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 0),
                      
                      // Email Field with 3D effect
                      _build3DInputField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        hintText: 'E-mail',
                        backgroundColor: color3,
                        sideColor: color3,
                        topColor: color3,
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        isHovered: _emailHover,
                        isFocused: _emailFocused,
                        onHoverChange: (hover) => setState(() => _emailHover = hover),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 0),
                      
                      // Phone Field with 3D effect
                      _build3DInputField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        hintText: 'Phone Number',
                        backgroundColor: color2,
                        sideColor: color2,
                        topColor: color2,
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        isHovered: _phoneHover,
                        isFocused: _phoneFocused,
                        onHoverChange: (hover) => setState(() => _phoneHover = hover),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 0),
                      
                      // Password Field with 3D effect
                      _build3DInputField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        hintText: 'Password',
                        backgroundColor: color1,
                        sideColor: color1,
                        topColor: color1,
                        icon: Icons.lock,
                        obscureText: _obscurePassword,
                        isHovered: _passwordHover,
                        isFocused: _passwordFocused,
                        onHoverChange: (hover) => setState(() => _passwordHover = hover),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 0),
                      
                      // Confirm Password Field with 3D effect
                      _build3DInputField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        hintText: 'Confirm Password',
                        backgroundColor: color1,
                        sideColor: color1,
                        topColor: color1,
                        icon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        isHovered: _confirmPasswordHover,
                        isFocused: _confirmPasswordFocused,
                        onHoverChange: (hover) => setState(() => _confirmPasswordHover = hover),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 0),
                      
                      // Submit Button with 3D effect
                      _build3DButton(
                        onPressed: _isLoading ? null : _signUp,
                        text: _isLoading ? 'Creating Account...' : 'Sign Up',
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
                const SizedBox(height: 60),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: Colors.grey[700]),
                      children: const [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: color5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
    bool obscureText = false,
    Widget? suffixIcon,
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
          ..setTranslationRaw(drawerOffset, 0.0, 0.0),
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
                    color: sideColor.withValues(alpha: 0.8),
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
                    color: topColor.withValues(alpha: 0.8),
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
                    color: sideColor.withValues(alpha: 0.6),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ] : [],
              ),
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                obscureText: obscureText,
                keyboardType: keyboardType,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: Icon(icon, color: Colors.black54),
                  suffixIcon: suffixIcon,
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
            ..setTranslationRaw(isHovered ? -20.0 : 0.0, 0.0, 0.0),
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
                      color: isHovered ? buttonColor.withValues(alpha: 0.8) : sideColor.withValues(alpha: 0.8),
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
                      color: isHovered ? buttonColor.withValues(alpha: 0.8) : topColor.withValues(alpha: 0.8),
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
