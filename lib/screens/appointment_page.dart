import 'package:flutter/material.dart';
import '../services/appointment_service.dart';

class AppointmentPage extends StatefulWidget {
  final Map<String, dynamic> center;

  const AppointmentPage({super.key, required this.center});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage>
    with SingleTickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF90CAF9);
  static const Color darkBlue = Color(0xFF42A5F5);
  static const Color deepBlue = Color(0xFF1565C0);
  static const Color accentBlue = Color(0xFF1E88E5);

  final AppointmentService _appointmentService = AppointmentService();

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingSlots = false;
  Map<String, int> _timeSlotCounts = {};
  static const int maxBookingsPerSlot = 20;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
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

  @override
  void dispose() {
    _animationController.dispose();
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
              primary: deepBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
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

    // Check if slot is full
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
      // Double-check availability from server before booking
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
                  color: deepBlue,
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
                  color: primaryBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: deepBlue),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: deepBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 18, color: deepBlue),
                    const SizedBox(width: 8),
                    Text(
                      _selectedTimeSlot!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: deepBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepBlue,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [deepBlue, accentBlue, darkBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Book Appointment',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.business,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.center['centreName'] ?? 'Center',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCenterInfoCard(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Select Date', Icons.calendar_month),
                      const SizedBox(height: 12),
                      _buildDateSelector(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Select Time Slot', Icons.schedule),
                      const SizedBox(height: 12),
                      _buildTimeSlotGrid(),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        'Appointment Details',
                        Icons.description_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildPurposeField(),
                      const SizedBox(height: 16),
                      _buildNotesField(),
                      const SizedBox(height: 32),
                      _buildBookButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [darkBlue, primaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: deepBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildCenterInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: deepBlue.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, darkBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.center['centreName'] ?? 'Unknown Center',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: deepBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Open',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.location_on_outlined,
            '${widget.center['address'] ?? ''}, ${widget.center['city'] ?? ''}',
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            Icons.phone_outlined,
            widget.center['contactPhone'] ?? 'N/A',
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            Icons.email_outlined,
            widget.center['contactEmail'] ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: darkBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedDate != null ? darkBlue : Colors.grey.shade300,
            width: _selectedDate != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedDate != null
                    ? darkBlue.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_today,
                color: _selectedDate != null ? darkBlue : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedDate != null ? 'Selected Date' : 'Choose Date',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedDate != null
                        ? _formatDate(_selectedDate!)
                        : 'Tap to select a date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedDate != null
                          ? Colors.black87
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildTimeSlotGrid() {
    if (_selectedDate == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator(color: darkBlue)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Max $maxBookingsPerSlot bookings per time slot',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _timeSlots
                .map((time) => _buildTimeSlotChip(time))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotChip(String time) {
    final isSelected = _selectedTimeSlot == time;
    final currentBookings = _timeSlotCounts[time] ?? 0;
    final availableSlots = maxBookingsPerSlot - currentBookings;
    final isFull = currentBookings >= maxBookingsPerSlot;

    return GestureDetector(
      onTap: isFull
          ? null
          : () {
              setState(() {
                _selectedTimeSlot = time;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: isFull
              ? null
              : isSelected
              ? const LinearGradient(
                  colors: [darkBlue, accentBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isFull
              ? Colors.grey.shade300
              : isSelected
              ? null
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected && !isFull
              ? [
                  BoxShadow(
                    color: darkBlue.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isFull
                    ? Colors.grey[500]
                    : isSelected
                    ? Colors.white
                    : Colors.grey[700],
                decoration: isFull ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isFull
                    ? Colors.red.shade100
                    : isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : availableSlots <= 5
                    ? Colors.orange.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isFull ? 'FULL' : '$availableSlots left',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isFull
                      ? Colors.red.shade700
                      : isSelected
                      ? Colors.white
                      : availableSlots <= 5
                      ? Colors.orange.shade700
                      : Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _purposeController,
        decoration: InputDecoration(
          hintText: 'e.g., Document verification, New application...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          labelText: 'Purpose of Visit *',
          labelStyle: const TextStyle(color: darkBlue),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 12),
            child: Icon(Icons.assignment_outlined, color: darkBlue),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: darkBlue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Any additional information or special requests...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          labelText: 'Additional Notes (Optional)',
          labelStyle: const TextStyle(color: darkBlue),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 12, bottom: 48),
            child: Icon(Icons.note_alt_outlined, color: darkBlue),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: darkBlue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _bookAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: deepBlue,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: deepBlue.withValues(alpha: 0.4),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Confirm Appointment',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
