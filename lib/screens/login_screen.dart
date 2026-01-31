// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:akshaya_hub/services/user_service.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // 3D Form Color Scheme
  static const Color color1 = Color(0xFFD8DAF7);
  static const Color color2 = Color(0xFFC2C5F3);
  static const Color color3 = Color(0xFF989DEB);
  static const Color color4 = Color(0xFF6D74E3);
  static const Color buttonColor = Color(0xFF575CB5);
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _userService = UserService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  // Hover states for 3D effect
  bool _emailHover = false;
  bool _passwordHover = false;
  bool _buttonHover = false;
  
  // Focus states for drawer animation
  bool _emailFocused = false;
  bool _passwordFocused = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() {
        _emailFocused = _emailFocusNode.hasFocus;
      });
    });
    _passwordFocusNode.addListener(() {
      setState(() {
        _passwordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _userService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showError(_getErrorMessage(e.code));
    } catch (e) {
      _showError('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                // Modern Login Header with Gradient and Glow
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
                      // Welcome Back text without background
                      Stack(
                        children: [
                          // Stroke/outline effect
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              height: 1.2,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 2.5
                                ..color = color4.withValues(alpha: 0.5),
                            ),
                          ),
                          // Main text with gradient-like shadow
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: color4,
                              letterSpacing: 1.5,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: color3.withValues(alpha: 0.8),
                                  offset: const Offset(2, 2),
                                  blurRadius: 4,
                                ),
                                Shadow(
                                  color: color2.withValues(alpha: 0.6),
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
                              color4,
                              color3,
                              color2,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color4.withValues(alpha: 0.5),
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
                      
                      // Password Field with 3D effect
                      _build3DInputField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        hintText: 'Password',
                        backgroundColor: color2,
                        sideColor: color2,
                        topColor: color2,
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
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 0),
                      
                      // Submit Button with 3D effect
                      _build3DButton(
                        onPressed: _isLoading ? null : _login,
                        text: _isLoading ? 'Loading...' : 'Login',
                        backgroundColor: color4,
                        sideColor: color4,
                        topColor: color4,
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Don\'t have an account? ',
                      style: TextStyle(color: Colors.grey[700]),
                      children: const [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: color4,
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