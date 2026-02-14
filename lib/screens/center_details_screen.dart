import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CenterDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> center;

  const CenterDetailsScreen({super.key, required this.center});

  static const Color primaryYellow = Color(0xFFE8E45E);

  Future<void> _launchPhoneDialer(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchGoogleMaps(double latitude, double longitude) async {
    // Try geo: URI first (opens in maps app directly)
    final Uri geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
      return;
    }
    
    // Fallback to Google Maps URL
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String centerName = center['centreName'] ?? 'Akshaya Center';
    final String address = center['address'] ?? '';
    final String city = center['city'] ?? '';
    final String state = center['state'] ?? '';
    final String pinCode = center['pinCode'] ?? '';
    final String contactPerson = center['contactPerson'] ?? '';
    final String contactPhone = center['contactPhone'] ?? '';
    final String contactEmail = center['contactEmail'] ?? '';
    final double latitude = (center['latitude'] ?? 0.0).toDouble();
    final double longitude = (center['longitude'] ?? 0.0).toDouble();
    final String registrationNumber = center['registrationNumber'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Center Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Center Header Card
            _buildHeaderCard(centerName),

            const SizedBox(height: 24),

            // Contact Information Section
            _buildSectionTitle('Contact Information'),
            const SizedBox(height: 12),
            _buildContactCard(contactPerson, contactPhone, contactEmail),

            const SizedBox(height: 24),

            // Address Section
            _buildSectionTitle('Address'),
            const SizedBox(height: 12),
            _buildAddressCard(address, city, state, pinCode),

            const SizedBox(height: 24),

            // Location Section
            _buildSectionTitle('Location'),
            const SizedBox(height: 12),
            _buildLocationCard(latitude, longitude),

            const SizedBox(height: 24),

            // Registration Details
            if (registrationNumber.isNotEmpty) ...[
              _buildSectionTitle('Registration Details'),
              const SizedBox(height: 12),
              _buildRegistrationCard(registrationNumber),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String centerName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryYellow, primaryYellow.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryYellow.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.business, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  centerName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'GOVERNMENT CENTER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildContactCard(
    String contactPerson,
    String contactPhone,
    String contactEmail,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Contact Person
          if (contactPerson.isNotEmpty)
            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'Contact Person',
              value: contactPerson,
            ),

          if (contactPerson.isNotEmpty && contactPhone.isNotEmpty)
            const Divider(height: 24),

          // Phone Number - Clickable
          if (contactPhone.isNotEmpty)
            InkWell(
              onTap: () => _launchPhoneDialer(contactPhone),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.phone,
                        color: Colors.green.shade600,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone Number',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            contactPhone,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),

          if (contactPhone.isNotEmpty && contactEmail.isNotEmpty)
            const Divider(height: 24),

          // Email
          if (contactEmail.isNotEmpty)
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: contactEmail,
            ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(
    String address,
    String city,
    String state,
    String pinCode,
  ) {
    final fullAddress = [
      if (address.isNotEmpty) address,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (pinCode.isNotEmpty) pinCode,
    ].join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on_outlined,
              color: Colors.orange.shade600,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Full Address',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  fullAddress.isNotEmpty ? fullAddress : 'No address available',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(double latitude, double longitude) {
    final hasValidLocation = latitude != 0.0 && longitude != 0.0;

    return InkWell(
      onTap: hasValidLocation ? () => _launchGoogleMaps(latitude, longitude) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasValidLocation ? Colors.blue.shade50 : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValidLocation ? Colors.blue.shade200 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasValidLocation
                    ? Colors.blue.shade100
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.map_outlined,
                color: hasValidLocation
                    ? Colors.blue.shade700
                    : Colors.grey.shade500,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View on Google Maps',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasValidLocation
                          ? Colors.blue.shade700
                          : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValidLocation
                        ? 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}'
                        : 'Location not available',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasValidLocation
                          ? Colors.blue.shade400
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (hasValidLocation)
              Icon(
                Icons.open_in_new,
                size: 20,
                color: Colors.blue.shade600,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationCard(String registrationNumber) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _buildInfoRow(
        icon: Icons.badge_outlined,
        label: 'Registration Number',
        value: registrationNumber,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primaryYellow.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.black54, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
