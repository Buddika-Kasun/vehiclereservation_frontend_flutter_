import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/screens/sub_screens/trip/vehicle_selection_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/services/api_service.dart';
import 'package:vehiclereservation_frontend_flutter_/services/storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/utils/constant.dart';

class SchedulePassengersScreen extends StatefulWidget {
  final Map<String, dynamic> locationData;

  const SchedulePassengersScreen({Key? key, required this.locationData}) : super(key: key);

  @override
  _SchedulePassengersScreenState createState() => _SchedulePassengersScreenState();
}

class _SchedulePassengersScreenState extends State<SchedulePassengersScreen> {
  // Schedule Section State
  DateTime? _startDate = DateTime.now();
  DateTime? _validTillDate;
  TimeOfDay? _startTime = TimeOfDay.fromDateTime(
    DateTime.now().add(Duration(minutes: 20))
  );
  String _repetition = 'once';
  bool _includeWeekends = false;
  int _repeatAfterDays = 0;

  // Passengers Section State
  String _passengerType = 'own';
  Map<String, dynamic>? _selectedIndividual;
  List<Map<String, dynamic>> _selectedGroupUsers = [];
  List<Map<String, dynamic>> _selectedOthers = [];
  bool _includeMeInGroup = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Add this getter method instead:
  Map<String, dynamic> get _currentUser {
    return {
      'id': _user?.id ?? 'current_user',
      'displayName': _user?.displayname ?? 'User Name',
      'contactNo': _user?.phone ?? 'User Contact',
    };
  }

  // Update the _loadUserData method:
  Future<void> _loadUserData() async {
    try {
      final user = StorageService.userData;
      
      if (user == null) {
        print('No user data found in storage');
        return;
      }
      
      setState(() {
        _user = user;
      });
      
      print('User data loaded: ${user.displayname}');
    } catch (e) {
      print('Load user data error: $e');
    }
  }

  // Expansion State
  bool _scheduleExpanded = true;
  bool _passengersExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Schedule Section
                    _buildScheduleSection(),
                    SizedBox(height: 16),
                    
                    // Passengers Section
                    _buildPassengersSection(),
                    
                    // Selected Users Display
                    if (_shouldShowSelectedUsers())
                      _buildSelectedUsersSection(),
                  ],
                ),
              ),
            ),
            
            // Next Button
            Container(
              width: double.infinity,
              height: 50,
              margin: EdgeInsets.only(top: 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _validateAndProceed,
                child: Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 0),
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
                color: Color(0xFFF9C80E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back_ios_rounded, color: Colors.black, size: 20),
            ),
          ),
          SizedBox(width: 16),
          Text(
            "Schedule & Passengers",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowSelectedUsers() {
    if (_passengerType == 'own') return true;
    if (_passengerType == 'other_individual' && _selectedIndividual != null) return true;
    if (_passengerType == 'group' && (_selectedGroupUsers.isNotEmpty || _selectedOthers.isNotEmpty || _includeMeInGroup)) return true;
    return false;
  }

  Widget _buildScheduleSection() {
    return Card(
      color: Colors.grey[900],
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          'Schedule',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                // Start Date
                _buildDateField(
                  'Start Date',
                  _startDate,
                  (date) => setState(() => _startDate = date),
                  isStartDate: true,
                ),
                SizedBox(height: 16),

                // Valid Till Date
                _buildDateField(
                  'Valid Till Date',
                  _validTillDate,
                  (date) => setState(() => _validTillDate = date),
                  isStartDate: false,
                ),
                SizedBox(height: 16),

                // Start Time
                _buildTimeField(
                  'Start Time',
                  _startTime,
                  () => _selectTime(context, (time) => setState(() => _startTime = time)),
                  onClear: _startTime != null ? () => setState(() => _startTime = null) : null,
                ),
                SizedBox(height: 16),

                // Repetition Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Repetition',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.grey[800],
                      style: TextStyle(color: Colors.yellow),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      value: _repetition,
                      items: [
                        DropdownMenuItem(value: 'once', child: Text('Once', style: TextStyle(color: Colors.yellow))),
                        DropdownMenuItem(value: 'daily', child: Text('Daily', style: TextStyle(color: Colors.yellow))),
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly', style: TextStyle(color: Colors.yellow))),
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly', style: TextStyle(color: Colors.yellow))),
                        DropdownMenuItem(value: 'custom', child: Text('Custom', style: TextStyle(color: Colors.yellow))),
                      ],
                      onChanged: (value) => setState(() => _repetition = value!),
                    ),
                  ],
                ),

                // Custom Repetition Fields
                if (_repetition == 'custom') ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Include weekends?',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Spacer(),
                      Transform.scale(
                        scale: 0.8, // Adjust this value (0.7 = 70%, 1.2 = 120%, etc.)
                        child: Switch(
                          value: _includeWeekends,
                          onChanged: (value) => setState(() => _includeWeekends = value),
                          activeColor: Colors.yellow[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  TextField(
                    style: TextStyle(color: Colors.yellow, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Repeat after (days)',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2)
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => _repeatAfterDays = int.tryParse(value) ?? 1),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengersSection() {
    //final totalPassengers = _getTotalPassengerCount();

    return Card(
      color: Colors.grey[900],
      child: ExpansionTile(
        title:Text(
          'Select Passenger',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Passenger Type Radio
                Column(
                  children: [
                    RadioListTile<String>(
                      title: Text('Own', style: TextStyle(color: Colors.white)),
                      value: 'own',
                      groupValue: _passengerType,
                      onChanged: (value) => _handlePassengerTypeChange(value!),
                      activeColor: Colors.yellow[600],
                    ),
                    RadioListTile<String>(
                      title: Text('Other Individual', style: TextStyle(color: Colors.white)),
                      value: 'other_individual',
                      groupValue: _passengerType,
                      onChanged: (value) => _handlePassengerTypeChange(value!),
                      activeColor: Colors.yellow[600],
                    ),
                    RadioListTile<String>(
                      title: Text('Group', style: TextStyle(color: Colors.white)),
                      value: 'group',
                      groupValue: _passengerType,
                      onChanged: (value) => _handlePassengerTypeChange(value!),
                      activeColor: Colors.yellow[600],
                    ),
                  ],
                ),

                // Own Passenger Section
                //if (_passengerType == 'own')
                //  _buildOwnPassengerSection(),

                // Other Individual Section
                if (_passengerType == 'other_individual')
                  _buildOtherIndividualSection(),

                // Group Section
                if (_passengerType == 'group')
                  _buildGroupSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePassengerTypeChange(String newType) {
    setState(() {
      // Clear selections when switching types
      if (newType != _passengerType) {
        _selectedIndividual = null;
        if (newType != 'group') {
          _selectedGroupUsers.clear();
          _selectedOthers.clear();
        }
        if(newType == 'other_individual') {
          _includeMeInGroup = false;
        }
        else {
          _includeMeInGroup = true;
        }
      }
      _passengerType = newType;
    });
  }

  int _getTotalPassengerCount() {
    switch (_passengerType) {
      case 'own':
        return 1;
      case 'other_individual':
        return _selectedIndividual != null ? 1 : 0;
      case 'group':
        int count = _includeMeInGroup ? 1 : 0;
        count += _selectedGroupUsers.length;
        count += _selectedOthers.length;
        return count;
      default:
        return 0;
    }
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnPassengerSection() {
  return Column(
    children: [
      SizedBox(height: 16),
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.yellow[600],
              child: Text(
                _currentUser['displayName'].isNotEmpty ? _currentUser['displayName'][0].toUpperCase() : 'Y',
                style: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser['displayName'],
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Passenger Count: 1',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildOtherIndividualSection() {
    return Column(
      children: [
        SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            minimumSize: Size(double.infinity, 50),
          ),
          onPressed: () async {
            final result = await _showUserSelectionDialog(
              title: 'Select Individual Passenger',
              currentSelection: _selectedIndividual?['displayName'],
            );
            if (result != null) {
              setState(() => _selectedIndividual = result);
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedIndividual != null 
                    ? _selectedIndividual!['displayName']
                    : 'Select User',
                style: TextStyle(
                  color: _selectedIndividual != null ? Colors.yellow : Colors.grey,
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupSection() {
    return Column(
      children: [
        SizedBox(height: 16),
        // Include Me Toggle
        Row(
          children: [
            Text('Include me', style: TextStyle(color: Colors.grey)),
            Spacer(),
            Switch(
              value: _includeMeInGroup,
              onChanged: (value) => setState(() => _includeMeInGroup = value),
              activeColor: Colors.yellow[600],
            ),
          ],
        ),
        SizedBox(height: 16),
        // Add Users Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            minimumSize: Size(double.infinity, 50),
          ),
          onPressed: () async {
            final result = await _showUserSelectionDialog(
              title: 'Add Users to Group',
              currentSelection: null,
            );
            if (result != null) {
              setState(() {
                if (!_selectedGroupUsers.any((user) => user['id'] == result['id'])) {
                  _selectedGroupUsers.add(result);
                }
              });
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.yellow),
              SizedBox(width: 8),
              Text('Add Users', style: TextStyle(color: Colors.yellow)),
            ],
          ),
        ),
        // Add Others Button
        SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            minimumSize: Size(double.infinity, 50),
          ),
          onPressed: _addOtherPassenger,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add, color: Colors.yellow),
              SizedBox(width: 8),
              Text('Add Other Passenger', style: TextStyle(color: Colors.yellow)),
            ],
          ),
        ),
      ],
    );
  }

  void _addOtherPassenger() {
    TextEditingController nameController = TextEditingController();
    TextEditingController contactController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Add Other Passenger', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.yellow),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: contactController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Contact Number',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.yellow),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[600]),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  _selectedOthers.add({
                    'id': 'other_${DateTime.now().millisecondsSinceEpoch}',
                    'displayName': nameController.text.trim(),
                    'contactNo': contactController.text.trim().isNotEmpty 
                        ? contactController.text.trim() 
                        : 'N/A',
                    'isOther': true,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: Text('Add', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedUsersSection() {
    final companyUsersCount = _selectedGroupUsers.length;
    final othersCount = _selectedOthers.length;
    final ownCount = (_passengerType == 'own' || (_passengerType == 'group' && _includeMeInGroup)) ? 1 : 0;

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Selected Passengers', _getTotalPassengerCount()),
            SizedBox(height: 12),
            
            // Own User Card
            if (_passengerType == 'own' || (_passengerType == 'group' && _includeMeInGroup))
              _buildUserCard(_currentUser, 'own'),
            
            // Individual User Card
            if (_passengerType == 'other_individual' && _selectedIndividual != null)
              _buildUserCard(_selectedIndividual!, 'individual'),
            
            // Company Users
            if (_selectedGroupUsers.isNotEmpty) ...[
              SizedBox(height: 8),
              Text('Company Users ($companyUsersCount):', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 8),
              ..._selectedGroupUsers.map((user) => _buildUserCard(user, 'company')),
            ],
            
            // Others
            if (_selectedOthers.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('Others ($othersCount):', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 8),
              ..._selectedOthers.map((user) => _buildUserCard(user, 'other')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, String type) {
    Color avatarColor;
    String typeLabel;

    switch (type) {
      case 'own':
        avatarColor = Colors.yellow[600]!;
        typeLabel = 'You';
        break;
      case 'individual':
        avatarColor = Colors.yellow[600]!;
        typeLabel = 'Individual';
        break;
      case 'company':
        avatarColor = Colors.yellow[600]!;
        typeLabel = 'Company User';
        break;
      case 'other':
        avatarColor = Colors.yellow[600]!;
        typeLabel = 'External Passenger';
        break;
      default:
        avatarColor = Colors.yellow[600]!;
        typeLabel = 'Passenger';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: avatarColor,
            child: Text(
              user['displayName'].isNotEmpty ? user['displayName'][0].toUpperCase() : 'U',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['displayName'],
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                if (user['contactNo'] != null && user['contactNo'] != 'N/A')
                  Text(
                    user['contactNo'],
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                Text(
                  typeLabel,
                  style: TextStyle(
                    color: type == 'other' ? Colors.orange : Colors.yellow,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (type != 'own') // Don't show remove button for own user
            IconButton(
              icon: Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () {
                setState(() {
                  if (type == 'individual') {
                    _selectedIndividual = null;
                  } else if (type == 'company') {
                    _selectedGroupUsers.removeWhere((u) => u['id'] == user['id']);
                  } else if (type == 'other') {
                    _selectedOthers.removeWhere((u) => u['id'] == user['id']);
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, Function(DateTime?) onDateSelected, {required bool isStartDate}) {
  final bool isEnabled = isStartDate || _startDate != null;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: isEnabled ? Colors.grey : Colors.grey.shade400,
          fontSize: 14,
        ),
      ),
      SizedBox(height: 4),
      InkWell(
        onTap: isEnabled ? () => _selectDate(context, onDateSelected, isStartDate: isStartDate) : null,
        child: Container(
          width: double.infinity,
          height: 45,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade800,
            ),
            borderRadius: BorderRadius.circular(8.0),
            color: isEnabled ? Colors.transparent : Colors.grey.shade800,
          ),
          child: Row(
            children: [
              Text(
                date != null 
                  ? '${date.day}/${date.month}/${date.year}'
                  : isStartDate ? 'Select start date' : (_startDate == null ? 'Select start date first' : 'Select valid till date'),
                style: TextStyle(
                  color: date != null ? Colors.yellow : (isEnabled ? Colors.grey.shade600 : Colors.grey.shade500),
                ),
              ),
              Spacer(),
              if (date != null && isEnabled)
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.red, size: 18),
                  onPressed: () => onDateSelected(null),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              Icon(
                Icons.calendar_today,
                color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade500,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

  Widget _buildTimeField(String label, TimeOfDay? time, VoidCallback onTap, {VoidCallback? onClear}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 45,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade600),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Text(
                  time != null 
                    ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                    : 'Select time',
                  style: TextStyle(
                    color: time != null ? Colors.yellow : Colors.grey.shade600,
                  ),
                ),
                Spacer(),
                if (time != null && onClear != null)
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.red, size: 18),
                    onPressed: onClear,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                Icon(
                  Icons.access_time,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, Function(DateTime?) onDateSelected, {required bool isStartDate}) async {
  final DateTime now = DateTime.now();
  final DateTime initialDate = isStartDate ? now : (_startDate ?? now);
  
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: isStartDate ? now : (_startDate ?? now),
    lastDate: DateTime(2100),
  );
  
  if (picked != null) {
    if (isStartDate) {
      // For start date, validate time if it's today
      if (_isToday(picked) && _startTime != null) {
        final selectedDateTime = DateTime(
          picked.year, 
          picked.month, 
          picked.day, 
          _startTime!.hour, 
          _startTime!.minute
        );
        if (selectedDateTime.isBefore(now)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Start time cannot be in the past')),
          );
          return;
        }
      }
      
      // If start date is changed and validTillDate is before new start date, clear validTillDate
      if (_validTillDate != null && _validTillDate!.isBefore(picked)) {
        setState(() {
          _validTillDate = null;
        });
      }
    } else {
      // For valid till date, ensure it's not before start date
      if (_startDate != null && picked.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Valid till date cannot be before start date')),
        );
        return;
      }
    }
    
    onDateSelected(picked);
  }
}

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Future<void> _selectTime(BuildContext context, Function(TimeOfDay?) onTimeSelected) async {
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );
  
  if (picked != null) {
    // Only validate time if start date is today
    if (_startDate != null && _isToday(_startDate!)) {
      final now = TimeOfDay.now();
      final currentTotalMinutes = now.hour * 60 + now.minute;
      final selectedTotalMinutes = picked.hour * 60 + picked.minute;
      
      if (selectedTotalMinutes < currentTotalMinutes + 15) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Start time must be at least 15 minutes from now')),
        );
        return;
      }
    }
    
    onTimeSelected(picked);
  }
}

  // Show user selection dialog
  Future<Map<String, dynamic>?> _showUserSelectionDialog({
    required String title,
    required String? currentSelection,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        // Local state for the dialog
        List<Map<String, dynamic>> localSearchResults = [];
        bool localIsSearching = false;
        String localSearchQuery = '';
        TextEditingController searchController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            
            // Local search function for the dialog
            Future<void> localSearchUsers(String query) async {
              if (query.isEmpty) {
                setState(() {
                  localSearchResults = [];
                  localIsSearching = false;
                });
                return;
              }

              setState(() {
                localIsSearching = true;
              });

              try {
                final response = await ApiService.searchUsers(query);
                if (response['success'] == true) {
                  final usersData = response['data']['users'] as List<dynamic>;
                  setState(() {
                    localSearchResults = usersData.map((data) => {
                      'id': data['_id'] ?? data['id'],
                      'displayName': data['displayName'] ?? data['displayname'] ?? 'Unknown',
                      'contactNo': data['phone'] ?? data['contactNo'] ?? 'N/A'
                    }).toList();
                    localIsSearching = false;
                  });
                } else {
                  throw Exception(response['message'] ?? 'Failed to search users');
                }
              } catch (e) {
                print('Error searching users: $e');
                setState(() {
                  localSearchResults = [];
                  localIsSearching = false;
                });
              }
            }

            return Dialog(
              backgroundColor: Colors.black.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                height: 500,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Search field
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            style: TextStyle(color: Colors.yellow),
                            decoration: InputDecoration(
                              labelText: 'Search users by name',
                              labelStyle: TextStyle(color: Colors.grey),
                              floatingLabelStyle: TextStyle(color: Colors.yellow),
                              prefixIcon: Icon(Icons.search, color: Colors.yellow),
                              suffixIcon: localSearchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.cancel, color: Colors.red, size: 20),
                                      onPressed: () {
                                        searchController.clear();
                                        setState(() {
                                          localSearchQuery = '';
                                          localSearchResults = [];
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade600, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.yellow, width: 1),
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                            onChanged: (query) {
                              setState(() {
                                localSearchQuery = query;
                              });
                              localSearchUsers(query);
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Search results
                    Expanded(
                      child: localIsSearching
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Colors.yellow[600],
                              ),
                            )
                          : localSearchResults.isEmpty
                              ? Center(
                                  child: Text(
                                    localSearchQuery.isEmpty 
                                        ? 'Start typing to search users'
                                        : 'No users found',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: localSearchResults.length,
                                  itemBuilder: (context, index) {
                                    final user = localSearchResults[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.yellow[600],
                                        child: Text(
                                          user['displayName'].isNotEmpty 
                                              ? user['displayName'][0].toUpperCase()
                                              : 'U',
                                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      title: Text(
                                        user['displayName'],
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      subtitle: Text(
                                        user['contactNo'],
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      trailing: currentSelection == user['displayName']
                                          ? Icon(Icons.check, color: Colors.yellow)
                                          : null,
                                      onTap: () {
                                        Navigator.pop(context, user);
                                      },
                                    );
                                  },
                                ),
                    ),
                    
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade800,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[600],
                            ),
                            onPressed: () => Navigator.pop(context, null),
                            child: Text('Clear', style: TextStyle(color: Colors.black)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _validateAndProceed() {
    // Validate schedule
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select start date')),
      );
      return;
    }

    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select start time')),
      );
      return;
    }

    // Validate passengers based on type
    if (_passengerType == 'other_individual' && _selectedIndividual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a passenger')),
      );
      return;
    }

    if (_passengerType == 'group' && _selectedGroupUsers.isEmpty && !_includeMeInGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one passenger to the group')),
      );
      return;
    }

    // Prepare data for next screen
    final scheduleData = {
      'startDate': _startDate,
      'validTillDate': _validTillDate,
      'startTime': _startTime,
      'repetition': _repetition,
      'includeWeekends': _includeWeekends,
      'repeatAfterDays': _repeatAfterDays,
    };

    final passengerData = {
      'passengerType': _passengerType,
      'selectedIndividual': _selectedIndividual,
      'selectedGroupUsers': _selectedGroupUsers,
      'selectedOthers': _selectedOthers,
      'includeMeInGroup': _includeMeInGroup,
      'currentUser': _currentUser,
    };

    // Combine all data
    final tripData = {
      'locationData': widget.locationData,
      'scheduleData': scheduleData,
      'passengerData': passengerData,
    };

    print('Proceeding with trip data:');
    print('Location: ${widget.locationData}');
    print('Schedule: $scheduleData');
    print('Passengers: $passengerData');

    // Navigate to next screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleSelectionScreen(
          tripData: tripData,
        ),
      ),
    );
  }

}