import 'package:flutter/material.dart';

// PDF generation and printing packages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/appointment_service.dart';
import 'center_details_screen.dart';

class AppointmentPage extends StatefulWidget {
  final Map<String, dynamic> center;

  const AppointmentPage({super.key, required this.center});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  static const Color primaryYellow = Color(0xFFE8E45E);
  static const Color darkYellow = Color(0xFFB5A642);
  static const Color lightYellow = Color(0xFFF8F6F0);

  final AppointmentService _appointmentService = AppointmentService();

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingSlots = false;
  Map<String, int> _timeSlotCounts = {};
  static const int maxBookingsPerSlot = 20;

  final List<String> _timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
  ];

  @override
  void dispose() {
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTimeSlotCounts() async {
    if (_selectedDate == null) return;

    setState(() {
      _isLoadingSlots = true;
    });

    try {
      final counts = await _appointmentService.getAllTimeSlotCounts(
        centerId: widget.center['id'] ?? '',
        date: _selectedDate!,
      );
      setState(() {
        _timeSlotCounts = counts;
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSlots = false;
      });
    }
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
            colorScheme: ColorScheme.light(
              primary: primaryYellow,
              onPrimary: Colors.black87,
              onSurface: Colors.black,
              surface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
      });
      _loadTimeSlotCounts();
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null) {
      _showErrorSnackBar('Please select an appointment date');
      return;
    }

    if (_selectedTimeSlot == null) {
      _showErrorSnackBar('Please select a time slot');
      return;
    }

    final currentBookings = _timeSlotCounts[_selectedTimeSlot] ?? 0;
    if (currentBookings >= maxBookingsPerSlot) {
      _showErrorSnackBar('This time slot is full. Please select another time.');
      return;
    }

    if (_purposeController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter the purpose of your visit');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isAvailable = await _appointmentService.isTimeSlotAvailable(
        centerId: widget.center['id'] ?? '',
        date: _selectedDate!,
        time: _selectedTimeSlot!,
      );

      if (!isAvailable) {
        _showErrorSnackBar(
          'This time slot just became full. Please select another time.',
        );
        await _loadTimeSlotCounts();
        setState(() => _isLoading = false);
        return;
      }

      await _appointmentService.bookAppointment(
        centerId: widget.center['id'] ?? '',
        centerName: widget.center['centreName'] ?? 'Unknown Center',
        centerAddress:
            '${widget.center['address'] ?? ''}, ${widget.center['city'] ?? ''}, ${widget.center['state'] ?? ''}',
        centerPhone: widget.center['contactPhone'] ?? '',
        appointmentDate: _selectedDate!,
        appointmentTime: _selectedTimeSlot!,
        purpose: _purposeController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to book appointment. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Appointment Booked!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryYellow,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your appointment at ${widget.center['centreName']} has been successfully booked.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: primaryYellow),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryYellow,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 18, color: primaryYellow),
                    const SizedBox(width: 8),
                    Text(
                      _selectedTimeSlot!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryYellow,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // download pdf button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _downloadAppointmentPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Download PDF',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Creates a PDF document representing the appointment details and sends
  /// it to the system print/layout dialog. The caller does not close any
  /// dialogs so the user may download the file and then hit "Done".
  Future<void> _downloadAppointmentPdf() async {
    if (_selectedDate == null || _selectedTimeSlot == null) return;

    // build a simple map containing the data we just booked so the service
    // can create the document consistently with other parts of the app if
    // we ever need to reuse it.
    final appointmentData = {
      'centerName': widget.center['centreName'] ?? '',
      'centerAddress':
          '${widget.center['address'] ?? ''}, ${widget.center['city'] ?? ''}, ${widget.center['state'] ?? ''}',
      'centerPhone': widget.center['contactPhone'] ?? '',
      'appointmentDate': _selectedDate!,
      'appointmentTime': _selectedTimeSlot!,
      'purpose': _purposeController.text.trim(),
      'notes': _notesController.text.trim(),
    };

    try {
      final bytes = await _appointmentService.createAppointmentPdf(appointmentData);
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } catch (e) {
      _showErrorSnackBar('Failed to generate PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Booking Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Center Profile Card
                  _buildCenterProfileCard(),
                  
                  const SizedBox(height: 30),
                  
                  // Select Date
                  _buildSelectDateSection(),
                  
                  const SizedBox(height: 30),
                  
                  // Available Time
                  _buildAvailableTimeSection(),
                  
                  const SizedBox(height: 30),
                  
                  // Reason for Visit
                  _buildReasonForVisit(),
                  
                  const SizedBox(height: 20),
                  
                  // Additional Notes
                  _buildAdditionalNotes(),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Book Appointment Button
          _buildBookButton(),
        ],
      ),
    );
  }

  Widget _buildCenterProfileCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CenterDetailsScreen(center: widget.center),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Profile Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.business, size: 40, color: Colors.grey[600]),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Center Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.center['centreName'] ?? 'Akshaya Center',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GOVERNMENT CENTER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: primaryYellow, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        '4.9',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(120 reviews)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SELECT DATE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
            Text(
              _selectedDate != null 
                  ? '${_getMonthName(_selectedDate!.month)} ${_selectedDate!.year}'
                  : 'May 2024',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = _selectedDate != null &&
                  _selectedDate!.day == date.day &&
                  _selectedDate!.month == date.month &&
                  _selectedDate!.year == date.year;
              return _buildDateItem(date, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateItem(DateTime date, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
          _selectedTimeSlot = null;
        });
        _loadTimeSlotCounts();
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryYellow : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryYellow : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getDayName(date.weekday).toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildAvailableTimeSection() {
    if (_selectedDate == null) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.calendar_today, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Please select a date first',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_isLoadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: primaryYellow),
        ),
      );
    }

    final morningSlots = _timeSlots.where((slot) => slot.contains('AM')).toList();
    final afternoonSlots = _timeSlots.where((slot) => slot.contains('PM')).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AVAILABLE TIME',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 20),
        // Morning
        Row(
          children: [
            Icon(Icons.wb_sunny_outlined, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Morning',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: morningSlots.map((time) => _buildTimeSlotChip(time)).toList(),
        ),
        const SizedBox(height: 24),
        // Afternoon
        Row(
          children: [
            Icon(Icons.wb_twilight, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Afternoon',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: afternoonSlots.map((time) => _buildTimeSlotChip(time)).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSlotChip(String time) {
    final isSelected = _selectedTimeSlot == time;
    final currentBookings = _timeSlotCounts[time] ?? 0;
    final isFull = currentBookings >= maxBookingsPerSlot;

    return GestureDetector(
      onTap: isFull ? null : () {
        setState(() {
          _selectedTimeSlot = time;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isFull
              ? Colors.grey[100]
              : isSelected
              ? primaryYellow
              : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected 
                ? primaryYellow 
                : isFull 
                    ? Colors.grey[300]! 
                    : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isFull
                ? Colors.grey[400]
                : isSelected
                ? Colors.black
                : Colors.black87,
            decoration: isFull ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }

  Widget _buildReasonForVisit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REASON FOR VISIT',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _purposeController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADDITIONAL NOTES',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _bookAppointment,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryYellow,
            disabledBackgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Book Appointment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
        ),
      ),
    );
  }
}
