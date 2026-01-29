import 'package:flutter/material.dart';

class AppointmentPage extends StatefulWidget {
  final Map<String, dynamic> center;

  const AppointmentPage({super.key, required this.center});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  static const Color primaryPurple = Color(0xFFCDABFF);
  static const Color darkPurple = Color(0xFFB896E8);
  static const Color deepPurple = Color(0xFF6A1B9A);

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: deepPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _bookAppointment() {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both date and time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_purposeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the purpose of your visit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Save appointment to Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointment booked successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkPurple),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Book Appointment',
          style: TextStyle(
            color: darkPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Center Info Card
            _buildCenterInfoCard(),

            const SizedBox(height: 24),

            // Appointment Details Section
            const Text(
              'Appointment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: deepPurple,
              ),
            ),

            const SizedBox(height: 16),

            // Date Picker
            _buildDateTimeSelector(
              icon: Icons.calendar_today,
              label: 'Select Date',
              value: _selectedDate != null
                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                  : 'Choose a date',
              onTap: () => _selectDate(context),
            ),

            const SizedBox(height: 12),

            // Time Picker
            _buildDateTimeSelector(
              icon: Icons.access_time,
              label: 'Select Time',
              value: _selectedTime != null
                  ? _selectedTime!.format(context)
                  : 'Choose a time',
              onTap: () => _selectTime(context),
            ),

            const SizedBox(height: 20),

            // Purpose Field
            _buildInputField(
              controller: _purposeController,
              label: 'Purpose of Visit',
              hint: 'e.g., Document verification, New application...',
              icon: Icons.description_outlined,
            ),

            const SizedBox(height: 16),

            // Notes Field
            _buildInputField(
              controller: _notesController,
              label: 'Additional Notes (Optional)',
              hint: 'Any additional information...',
              icon: Icons.note_outlined,
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // Book Appointment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _bookAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Book Appointment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryPurple.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withValues(alpha: 0.1),
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
                  color: primaryPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business,
                  color: darkPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.center['centreName'] ?? 'Unknown Center',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: deepPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.center['registrationNumber'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.location_on,
            '${widget.center['address'] ?? ''}, ${widget.center['city'] ?? ''}, ${widget.center['state'] ?? ''} - ${widget.center['pinCode'] ?? ''}',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.phone,
            widget.center['contactPhone'] ?? 'N/A',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.email,
            widget.center['contactEmail'] ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSelector({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: darkPurple,
                size: 20,
              ),
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
                    ),
                  ),
                  const SizedBox(height: 4),
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
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: darkPurple,
              size: 20,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: darkPurple,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
