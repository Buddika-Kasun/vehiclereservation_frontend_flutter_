import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/app_info_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';

class UserDetailsScreen extends StatefulWidget {
  final int userId;
  final User?
  user; // Optional: if user is already passed, use it; otherwise fetch

  const UserDetailsScreen({Key? key, required this.userId, this.user})
    : super(key: key);

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  User? _user;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      // Use provided user data
      _user = widget.user;
      _isLoading = false;
    } else {
      // Fetch user from API
      _fetchUserDetails();
    }
  }

  Future<void> _fetchUserDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await ApiService.getFullUserById(
        widget.userId.toString(),
      );

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _user = User.fromJson(response['data']['user']);
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch user details');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user details: ${e.toString()}';
        print(_errorMessage);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
          ? _buildErrorState()
          : _user == null
          ? _buildNoDataState()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileSection(),
                SizedBox(height: 16),
                _buildInfoSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double appBarHeight = 60.0;

    return Container(
      height: statusBarHeight + appBarHeight,
      padding: EdgeInsets.only(
        top: statusBarHeight,
        left: 16,
        right: 16,
        bottom: 0,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9C80E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'User Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    Color roleColor = _getRoleColor(_user!.role.value);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getAvatarText(_user!.displayname),
                style: TextStyle(
                  color: roleColor,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            _user!.displayname,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getRoleDisplayName(_user!.role.value),
              style: TextStyle(
                color: roleColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _user!.isActive
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _user!.isActive ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  _user!.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: _user!.isActive ? Colors.green : Colors.red,
                    fontSize: 12,
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

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow('User Name', _user!.username),
          _buildInfoRow('Display Name', _user!.displayname),
          _buildInfoRow('Role', _getRoleDisplayName(_user!.role.value)),
          _buildInfoRow('Department', _user!.department ?? 'No Department'),
          _buildInfoRow('Email', _user!.email ?? 'Not provided'),
          _buildInfoRow('Phone', _formatPhoneNumber(_user!.phone)),

          SizedBox(height: 26),
          Text(
            'Permissions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          if (_user!.canTripApprove)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Can Approve Trips',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 14),
                  ),
                ],
              ),
            ),

          if (_user!.canUserCreate)
            Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Can Create Users',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 14),
                  ),
                ],
              ),
            ),

          if (!_user!.canTripApprove && !_user!.canUserCreate)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.redAccent, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'No special permissions assigned',
                    style: TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),
                ],
              ),
            ),

          SizedBox(height: 32),
          Text(
            'Activity Logs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          _buildInfoRow('Registered', _formatDateTime(_user!.createdAt)),
          if (_user!.lastLogin != null)
            _buildInfoRow('Last Login', _formatDateTime(_user!.lastLogin!)),
          if (_user!.lastAccess != null)
            _buildInfoRow('Last Access', _formatDateTime(_user!.lastAccess!)),

          SizedBox(height: 26),
          Text(
            'Last Access Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          _buildInfoRow(
            'Device',
            _user!.device == null
                ? 'Unknown'
                : _user!.device == "Web Browser"
                ? 'Apple device'
                : _user!.device!,
          ),
          _buildInfoRow(
            'Platform',
            _user!.platform != null && _user!.platform!.isNotEmpty
                ? '${_user!.platform![0].toUpperCase()}${_user!.platform!.substring(1)}'
                : 'Unknown',
          ),
          _buildInfoRow(
            'App Version',
            _user!.appVersion == null
                ? 'Unknown'
                : _user!.appVersion == "web"
                ? AppInfoService.version
                : _user!.appVersion!,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              ': $value',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'sysadmin':
        return const Color.fromARGB(255, 210, 28, 16);
      case 'supervisor':
        return const Color.fromARGB(255, 33, 150, 243);
      case 'security':
        return const Color.fromARGB(255, 76, 175, 80);
      case 'hr':
        return const Color.fromARGB(255, 156, 39, 176);
      case 'employee':
        return const Color.fromARGB(255, 255, 152, 0);
      case 'admin':
        return const Color.fromARGB(255, 63, 81, 181);
      case 'driver':
        return const Color.fromARGB(255, 244, 67, 54);
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'sysadmin':
        return 'System Admin';
      case 'supervisor':
        return 'Transport Supervisor';
      case 'admin':
        return 'HOD';
      case 'driver':
        return 'Driver';
      case 'security':
        return 'Security';
      case 'hr':
        return 'HR';
      case 'employee':
        return 'Employee';
      default:
        return role;
    }
  }

  String _getAvatarText(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatDateTime(DateTime dateTime) {
    // Method 1: Using intl package (recommended)
    // First add intl: ^0.18.1 to pubspec.yaml
    // return DateFormat('yyyy-MM-dd hh:mm:ss a').format(dateTime);

    // Method 2: Manual implementation without package
    final hour12 = dateTime.hour % 12;
    final hour = hour12 == 0 ? 12 : hour12;
    final amPm = dateTime.hour < 12 ? 'AM' : 'PM';

    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}'
        '    ${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }

  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return 'Not provided';

    String cleaned = phone.trim();

    // If length is 9, add +94 prefix
    if (cleaned.length == 9) {
      return '+94 $cleaned';
    }
    // If length is 10 and starts with 0, remove 0 and add +94
    else if (cleaned.length == 10 && cleaned.startsWith('0')) {
      return '+94 ${cleaned.substring(1)}';
    }
    // If already starts with +94, return as is
    else if (cleaned.startsWith('+94')) {
      return cleaned;
    }
    // Otherwise return original
    else {
      return cleaned;
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: const Color(0xFFF9C80E)),
          SizedBox(height: 16),
          Text(
            'Loading user details...',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 50),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchUserDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9C80E),
                foregroundColor: Colors.black,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, color: Colors.grey[600], size: 50),
          SizedBox(height: 16),
          Text(
            'User not found',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'User ID: ${widget.userId}',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
