import 'package:flutter/material.dart';
import 'dart:math' as math;

class HomePageNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const HomePageNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<HomePageNavBar> createState() => _HomePageNavBarState();
}

class _HomePageNavBarState extends State<HomePageNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: AnimatedBorderPainter(
              animation: _animationController,
              color: const Color(0xFF42A5F5),
            ),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home,
                    label: 'Home',
                    index: 0,
                    isSelected: widget.currentIndex == 0,
                  ),
                  _buildNavItem(
                    icon: Icons.add_business,
                    label: 'Register',
                    index: 1,
                    isSelected: widget.currentIndex == 1,
                  ),
                  _buildNavItem(
                    icon: Icons.person,
                    label: 'Profile',
                    index: 2,
                    isSelected: widget.currentIndex == 2,
                  ),
                  _buildNavItem(
                    icon: Icons.explore,
                    label: 'Explore',
                    index: 3,
                    isSelected: widget.currentIndex == 3,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E88E5).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? const Color(0xFF1E88E5)
              : Colors.grey[400],
          size: 22,
        ),
      ),
    );
  }
}

class AnimatedBorderPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  AnimatedBorderPainter({
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(30));

    // Draw white background
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    // Create gradient that rotates
    final progress = animation.value;
    final gradientRotation = progress * 2 * math.pi;

    final gradient = SweepGradient(
      colors: [
        color,
        color.withValues(alpha: 0.5),
        Colors.white,
        Colors.white,
        color.withValues(alpha: 0.5),
        color,
      ],
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
      transform: GradientRotation(gradientRotation),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(AnimatedBorderPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}