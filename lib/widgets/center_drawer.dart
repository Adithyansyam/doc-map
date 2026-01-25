import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/centre_service.dart';

class CenterDrawer extends StatelessWidget {
  final LatLng? userLocation;

  const CenterDrawer({super.key, this.userLocation});

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, LatLng(lat1, lon1), LatLng(lat2, lon2));
  }

  @override
  Widget build(BuildContext context) {
    final centreService = CentreService();

    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.7,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.location_city, color: Color(0xFFB896E8), size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Nearby Centers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB896E8),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Centers List
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: centreService.getAllCentersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFB896E8),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No centers found nearby',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    var centers = snapshot.data!
                        .where((center) =>
                            center['latitude'] != null &&
                            center['longitude'] != null)
                        .toList();

                    // Sort by distance if user location is available
                    if (userLocation != null) {
                      centers.sort((a, b) {
                        double distA = _calculateDistance(
                          userLocation!.latitude,
                          userLocation!.longitude,
                          a['latitude'] as double,
                          a['longitude'] as double,
                        );
                        double distB = _calculateDistance(
                          userLocation!.latitude,
                          userLocation!.longitude,
                          b['latitude'] as double,
                          b['longitude'] as double,
                        );
                        return distA.compareTo(distB);
                      });
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: centers.length,
                      itemBuilder: (context, index) {
                        final center = centers[index];
                        double? distance;
                        
                        if (userLocation != null) {
                          distance = _calculateDistance(
                            userLocation!.latitude,
                            userLocation!.longitude,
                            center['latitude'] as double,
                            center['longitude'] as double,
                          );
                        }

                        return _buildCenterCard(center, distance);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCenterCard(Map<String, dynamic> center, double? distance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Color(0xFFB896E8).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Center Name and Distance
            Row(
              children: [
                Expanded(
                  child: Text(
                    center['centreName'] ?? 'Unknown Center',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                ),
                if (distance != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFB896E8).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.near_me,
                          size: 12,
                          color: Color(0xFF6A1B9A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A1B9A),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${center['address']}, ${center['city']}, ${center['state']} - ${center['pinCode']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Contact
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  center['contactPhone'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
