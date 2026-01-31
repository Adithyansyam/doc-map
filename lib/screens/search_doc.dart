import 'package:flutter/material.dart';
import '../widgets/homepage_navbar.dart';
import '../services/document_service.dart';
import 'home_screen.dart';
import 'my_centers_screen.dart';
import 'profile_screen.dart';
import 'document_view_screen.dart';

class SearchDoc extends StatefulWidget {
  const SearchDoc({super.key});

  @override
  State<SearchDoc> createState() => _SearchDocState();
}

class _SearchDocState extends State<SearchDoc> {
  static const Color primaryYellow = Color(0xFFE8E45E);
  static const Color lightYellow = Color(0xFFF8F6F0);
  static const Color darkYellow = Color(0xFFB5A642);

  int _currentIndex = 2;
  final TextEditingController _searchController = TextEditingController();
  final DocumentService _documentService = DocumentService();
  String _searchQuery = '';

  // Gradient colors for cards
  final List<List<Color>> _cardGradients = [
    [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)],
    [const Color(0xFF2D1B69), const Color(0xFF11998E), const Color(0xFFFF6B35)],
    [const Color(0xFF0D0D0D), const Color(0xFF1A472A), const Color(0xFF2D5A27)],
    [const Color(0xFF667EEA), const Color(0xFF764BA2), const Color(0xFFF093FB)],
    [const Color(0xFF0C0C0C), const Color(0xFF1A1A1A), const Color(0xFF8B7355)],
    [const Color(0xFFE8E8E8), const Color(0xFFD4D4D4), const Color(0xFFBDBDBD)],
  ];

  final List<Color> _accentColors = [
    const Color(0xFF00FF88),
    const Color(0xFFFF9F1C),
    const Color(0xFF39FF14),
    const Color(0xFFFF6B9D),
    const Color(0xFFFFD700),
    const Color(0xFF333333),
  ];

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyCentersScreen()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightYellow,
      appBar: AppBar(
        backgroundColor: lightYellow,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {},
        ),
        title: const Text(
          'Discover',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEAE6D8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ),

          // Document Grid
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _documentService.getAllDocumentsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryYellow),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading documents',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final documents = snapshot.data ?? [];
                
                // Filter documents based on search query
                final filteredDocuments = _searchQuery.isEmpty
                    ? documents
                    : documents.where((doc) {
                        final title = (doc['title'] ?? '').toString().toLowerCase();
                        final description = (doc['description'] ?? '').toString().toLowerCase();
                        return title.contains(_searchQuery) || description.contains(_searchQuery);
                      }).toList();

                if (filteredDocuments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: primaryYellow.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            size: 60,
                            color: darkYellow,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'No documents yet' 
                              : 'No documents found',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Documents will appear here when added'
                              : 'Try a different search term',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredDocuments.length,
                    itemBuilder: (context, index) {
                      return _buildDocumentCard(filteredDocuments[index], index);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: HomePageNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> document, int index) {
    final gradientIndex = index % _cardGradients.length;
    final List<Color> gradientColors = _cardGradients[gradientIndex];
    final Color accentColor = _accentColors[gradientIndex];
    final bool isLightCard = gradientIndex == 5;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentViewScreen(document: document),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Abstract pattern overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CustomPaint(
                  painter: _AbstractPatternPainter(
                    accentColor: accentColor,
                    patternIndex: index,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title and Description
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document['title'] ?? 'Untitled',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isLightCard ? Colors.black87 : Colors.white,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (document['description'] ?? '').toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isLightCard 
                              ? Colors.black54 
                              : Colors.white.withOpacity(0.7),
                          letterSpacing: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  // View Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'VIEW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isLightCard || gradientIndex == 4 ? Colors.black87 : Colors.white,
                        letterSpacing: 1,
                      ),
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

// Custom painter for abstract patterns on cards
class _AbstractPatternPainter extends CustomPainter {
  final Color accentColor;
  final int patternIndex;

  _AbstractPatternPainter({required this.accentColor, required this.patternIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (patternIndex % 6) {
      case 0: // Wavy lines
        for (int i = 0; i < 8; i++) {
          final path = Path();
          path.moveTo(0, size.height * 0.3 + i * 15);
          for (double x = 0; x < size.width; x += 20) {
            path.quadraticBezierTo(
              x + 10, size.height * 0.3 + i * 15 + (i.isEven ? 10 : -10),
              x + 20, size.height * 0.3 + i * 15,
            );
          }
          canvas.drawPath(path, paint);
        }
        break;
      case 1: // Circles
        for (int i = 0; i < 5; i++) {
          canvas.drawCircle(
            Offset(size.width * 0.7, size.height * 0.4),
            30.0 + i * 20,
            paint,
          );
        }
        break;
      case 2: // Concentric patterns
        for (int i = 0; i < 6; i++) {
          final rect = Rect.fromCenter(
            center: Offset(size.width * 0.3, size.height * 0.5),
            width: 40.0 + i * 25,
            height: 40.0 + i * 25,
          );
          canvas.drawOval(rect, paint);
        }
        break;
      case 3: // Diagonal lines
        for (int i = 0; i < 12; i++) {
          canvas.drawLine(
            Offset(size.width * 0.5 + i * 15, 0),
            Offset(size.width + i * 15, size.height),
            paint,
          );
        }
        break;
      case 4: // Curved streaks
        for (int i = 0; i < 5; i++) {
          final path = Path();
          path.moveTo(0, size.height * 0.6 + i * 12);
          path.quadraticBezierTo(
            size.width * 0.5, size.height * 0.4 + i * 12,
            size.width, size.height * 0.7 + i * 12,
          );
          canvas.drawPath(path, paint);
        }
        break;
      case 5: // Wave layers
        paint.color = accentColor.withOpacity(0.1);
        for (int i = 0; i < 6; i++) {
          final path = Path();
          path.moveTo(0, size.height * 0.5 + i * 10);
          path.quadraticBezierTo(
            size.width * 0.3, size.height * 0.4 + i * 10,
            size.width * 0.6, size.height * 0.5 + i * 10,
          );
          path.quadraticBezierTo(
            size.width * 0.8, size.height * 0.6 + i * 10,
            size.width, size.height * 0.5 + i * 10,
          );
          canvas.drawPath(path, paint);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
