import 'package:flutter/material.dart';
import 'package:akshaya_hub/services/centre_service.dart';
import 'package:akshaya_hub/screens/register_akshaya_screen.dart';

class MyCentersScreen extends StatefulWidget {
  const MyCentersScreen({super.key});

  @override
  State<MyCentersScreen> createState() => _MyCentersScreenState();
}

class _MyCentersScreenState extends State<MyCentersScreen> {
  static const Color primaryPurple = Color(0xFFCDABFF);
  static const Color lightPurple = Color(0xFFE8D9FF);
  static const Color darkPurple = Color(0xFFB896E8);

  final _centreService = CentreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryPurple),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Centers',
          style: TextStyle(
            color: primaryPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _centreService.getUserCentresStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryPurple,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {}); // Refresh
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                      ),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          final centers = snapshot.data ?? [];
          final hasCenter = centers.isNotEmpty;

          if (centers.isEmpty) {
            return _buildEmptyState();
          }

          // Show full details of the registered center
          return _buildCenterDetailsView(centers.first);
        },
      ),
      // Only show FAB when no center is registered
      floatingActionButton: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _centreService.getUserCentresStream(),
        builder: (context, snapshot) {
          final centers = snapshot.data ?? [];
          if (centers.isEmpty) {
            return FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterAkshayaScreen(),
                  ),
                );
              },
              backgroundColor: primaryPurple,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Register Center',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
          return const SizedBox.shrink(); // Hide button when center exists
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No centers registered yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Register your center to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: primaryPurple.withOpacity(0.3),
                ),
              ),
              child: const Text(
                'Note: You can only register one center per account',
                style: TextStyle(
                  fontSize: 12,
                  color: darkPurple,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCenterDetailsView(Map<String, dynamic> center) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // Center Information Card
          _buildFullDetailSection(
            'Center Information',
            Icons.business,
            [
              _buildFullDetailRow('Center Name', center['centreName'], Icons.business_center),
              _buildFullDetailRow('Registration Number', center['registrationNumber'], Icons.confirmation_number),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Location Details Card
          _buildFullDetailSection(
            'Location Details',
            Icons.location_on,
            [
              _buildFullDetailRow('Address', center['address'], Icons.home),
              _buildFullDetailRow('City', center['city'], Icons.location_city),
              _buildFullDetailRow('State', center['state'], Icons.map),
              _buildFullDetailRow('PIN Code', center['pinCode'], Icons.pin_drop),
              if (center['latitude'] != null && center['longitude'] != null)
                _buildFullDetailRow(
                  'Coordinates',
                  '${center['latitude']}, ${center['longitude']}',
                  Icons.my_location,
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Contact Information Card
          _buildFullDetailSection(
            'Contact Information',
            Icons.contact_phone,
            [
              _buildFullDetailRow('Contact Person', center['contactPerson'], Icons.person),
              _buildFullDetailRow('Phone', center['contactPhone'], Icons.phone),
              _buildFullDetailRow('Email', center['contactEmail'], Icons.email),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Info Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lightPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryPurple.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: primaryPurple, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can only register one center per account. To register a different center, please contact support.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 80), // Extra space for better scrolling
        ],
      ),
    );
  }

  Widget _buildFullDetailSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryPurple.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryPurple, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFullDetailRow(String label, dynamic value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: primaryPurple.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                Text(
                  value?.toString() ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }
}
