import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:akshaya_hub/services/centre_service.dart';
import 'package:akshaya_hub/screens/register_akshaya_screen.dart';
import 'package:akshaya_hub/services/notification_service.dart';
import 'package:akshaya_hub/services/appointment_service.dart';
import '../widgets/homepage_navbar.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_doc.dart';
import 'document_details_screen.dart';

class MyCentersScreen extends StatefulWidget {
  const MyCentersScreen({super.key});

  @override
  State<MyCentersScreen> createState() => _MyCentersScreenState();
}

class _MyCentersScreenState extends State<MyCentersScreen> with SingleTickerProviderStateMixin {
  static const Color primaryYellow = Color(0xFFE8E45E);
  static const Color lightYellow = Color(0xFFF8F6F0);
  static const Color darkYellow = Color(0xFFB5A642);
  static const Color accentYellow = Color(0xFFEAE6D8);

  final _centreService = CentreService();
  final _notificationService = NotificationService();
  final _appointmentService = AppointmentService();
  late TabController _tabController;
  int _currentIndex = 1; // Set to 1 since this is the My Centers page

  void _onItemTapped(int index) {
    if (index == 0) {
      // Navigate to Home Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (index == 2) {
      // Navigate to Search Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SearchDoc()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Centers',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: darkYellow,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryYellow,
          indicatorWeight: 3,
          tabs: [
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business, size: 20),
                  SizedBox(width: 4),
                  Text('Center Details', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            Tab(
              child: StreamBuilder<int>(
                stream: _notificationService.getUnreadNotificationCountStream(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications, size: 20),
                          SizedBox(width: 4),
                          Text('Notifications', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -12,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCenterTab(),
          _buildNotificationsTab(),
        ],
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
              backgroundColor: primaryYellow,
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
      bottomNavigationBar: HomePageNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildCenterTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _centreService.getUserCentresStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: primaryYellow,
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
                      backgroundColor: primaryYellow,
                    ),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        final centers = snapshot.data ?? [];

        if (centers.isEmpty) {
          return _buildEmptyState();
        }

        // Show full details of the registered center
        return _buildCenterDetailsView(centers.first);
      },
    );
  }

  Widget _buildNotificationsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _notificationService.getCenterNotificationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: primaryYellow,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading notifications',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primaryYellow.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_off_outlined,
                      size: 60,
                      color: darkYellow,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkYellow,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll receive notifications when customers book appointments',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Actions bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: primaryYellow.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${notifications.length} notification${notifications.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: darkYellow,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await _notificationService.markAllAsRead();
                        },
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Mark all read'),
                        style: TextButton.styleFrom(
                          foregroundColor: darkYellow,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Clear All'),
                              content: const Text('Are you sure you want to delete all notifications?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _notificationService.deleteAllNotifications();
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        tooltip: 'Clear all',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Notifications list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationCard(notification);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] ?? false;
    final createdAt = notification['createdAt'] as dynamic;
    final timeAgo = createdAt != null ? _getTimeAgo(createdAt.toDate()) : '';
    final appointmentId = notification['appointmentId'] as String?;
    final appointmentStatus = notification['appointmentStatus'] as String? ?? 'pending';

    return Dismissible(
      key: Key(notification['id']),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _notificationService.deleteNotification(notification['id']);
      },
      child: GestureDetector(
        onTap: () {
          if (!isRead) {
            _notificationService.markAsRead(notification['id']);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : primaryYellow.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead ? Colors.grey.shade300 : darkYellow.withValues(alpha: 0.3),
              width: isRead ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: appointmentStatus == 'confirmed' 
                              ? [Colors.green, Colors.green.shade700]
                              : appointmentStatus == 'rejected'
                                  ? [Colors.red, Colors.red.shade700]
                                  : [primaryYellow, darkYellow],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        appointmentStatus == 'confirmed' 
                            ? Icons.check_circle
                            : appointmentStatus == 'rejected'
                                ? Icons.cancel
                                : Icons.event_available,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification['title'] ?? 'Notification',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: accentYellow,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification['message'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: darkYellow.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person_outline, size: 14, color: darkYellow),
                                    const SizedBox(width: 4),
                                    Text(
                                      notification['userName'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: darkYellow,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                timeAgo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Status Badge or Action Buttons
                if (appointmentId != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  if (appointmentStatus == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approveAppointment(appointmentId, notification['id'], notification),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _rejectAppointment(appointmentId, notification['id'], notification),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: appointmentStatus == 'confirmed'
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            appointmentStatus == 'confirmed' ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: appointmentStatus == 'confirmed' ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            appointmentStatus == 'confirmed' ? 'Approved' : 'Rejected',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: appointmentStatus == 'confirmed' ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _approveAppointment(String appointmentId, String notificationId, Map<String, dynamic> notification) async {
    try {
      // Get appointment details to find the user
      final appointment = await _appointmentService.getAppointmentById(appointmentId);
      
      await _appointmentService.approveAppointment(appointmentId);
      await _notificationService.updateNotificationStatus(notificationId, 'confirmed');
      
      // Create notification for the user
      if (appointment != null && appointment['userId'] != null) {
        DateTime appointmentDate;
        if (notification['appointmentDate'] is Timestamp) {
          appointmentDate = (notification['appointmentDate'] as Timestamp).toDate();
        } else {
          appointmentDate = DateTime.now();
        }
        
        await _notificationService.createUserNotification(
          userId: appointment['userId'],
          centerId: notification['centerId'] ?? '',
          centerName: notification['centerName'] ?? 'Center',
          appointmentId: appointmentId,
          appointmentDate: appointmentDate,
          appointmentTime: notification['appointmentTime'] ?? '',
          status: 'confirmed',
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectAppointment(String appointmentId, String notificationId, Map<String, dynamic> notification) async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this appointment?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Reason for rejection (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // Get appointment details to find the user
        final appointment = await _appointmentService.getAppointmentById(appointmentId);
        
        await _appointmentService.rejectAppointment(
          appointmentId,
          reason: reasonController.text.isNotEmpty ? reasonController.text : null,
        );
        await _notificationService.updateNotificationStatus(notificationId, 'rejected');
        
        // Create notification for the user
        if (appointment != null && appointment['userId'] != null) {
          DateTime appointmentDate;
          if (notification['appointmentDate'] is Timestamp) {
            appointmentDate = (notification['appointmentDate'] as Timestamp).toDate();
          } else {
            appointmentDate = DateTime.now();
          }
          
          await _notificationService.createUserNotification(
            userId: appointment['userId'],
            centerId: notification['centerId'] ?? '',
            centerName: notification['centerName'] ?? 'Center',
            appointmentId: appointmentId,
            appointmentDate: appointmentDate,
            appointmentTime: notification['appointmentTime'] ?? '',
            status: 'rejected',
            rejectionReason: reasonController.text.isNotEmpty ? reasonController.text : null,
          );
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
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
                color: primaryYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: primaryYellow.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'Note: You can only register one center per account',
                style: TextStyle(
                  fontSize: 12,
                  color: darkYellow,
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
              color: lightYellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryYellow.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: primaryYellow, size: 24),
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
          
          const SizedBox(height: 24),
          
          // New Document Details Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DocumentDetailsScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryYellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description, color: Colors.black87, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'New Document Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
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
          color: primaryYellow.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryYellow.withValues(alpha: 0.08),
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
                  color: primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryYellow, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkYellow,
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
            color: primaryYellow.withValues(alpha: 0.7),
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
}
