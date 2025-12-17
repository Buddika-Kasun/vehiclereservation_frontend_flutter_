import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vehiclereservation_frontend_flutter_/models/available_vehicles_response.dart';
import 'package:vehiclereservation_frontend_flutter_/models/driver_trip_response.dart';
import 'package:vehiclereservation_frontend_flutter_/models/trip_booking_response.dart';
import 'package:vehiclereservation_frontend_flutter_/models/trip_list_response.dart';
import 'package:vehiclereservation_frontend_flutter_/models/trip_request_model.dart';
import 'package:vehiclereservation_frontend_flutter_/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/services/storage_service.dart';
import '../config/api_config.dart';

class ApiService {
  //static const String baseUrl = ApiConfig.baseUrl;
  static final String baseUrl = ApiConfig.baseUrl;
  //static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    final res = json.decode(response.body);

    if (res['success'] == true) {
      // Save tokens securely
      await SecureStorageService().saveTokens(
        accessToken: res['data']['accessToken'],
        refreshToken: res['data']['refreshToken'],
      );

      // Convert the user map to User object and save
    final userMap = res['data']['user'] as Map<String, dynamic>;
    final user = User.fromJson(userMap);
    
    await StorageService.saveUserData(
      userData: user,
      originalJson: userMap
    );

      return res;
    } else {
      //throw Exception(errorData['message'] ?? 'Login failed: ${response.statusCode}');
      throw res['message'] ?? 'Login failed: ${response.statusCode}';
    }
  }

  static Future<Map<String, dynamic>> getRegisterStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/validate/canRegisterUser'),
        headers: {'Content-Type': 'application/json'},
      );
      
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get app status');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Add other API methods here
  static Future<Map<String, dynamic>> signUp(
      String username, String password, String confirmPassword, String? email,
      {required String phone, required String displayName, String? role, String? departmentId}) async {
    
    // Check if passwords match
    if (password != confirmPassword) {
      throw Exception('Passwords do not match');
    }

    final Map<String, dynamic> body = {
      'username': username,
      'password': password,
      'phone': phone,
      'displayname': displayName, // Made required
      'departmentId': departmentId,
    };

    // Only add email if provided (optional)
    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }

    // Only add role if provided (optional)
    if (role != null && role.isNotEmpty) {
      body['role'] = role.toLowerCase();
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    final res = json.decode(response.body);

    if (res['success'] == true) {
      return res;
    } else {
      throw res['message'] ?? 'Registration failed: ${response.statusCode}';
    }
  }

  // Refresh token method
  static Future<Map<String, dynamic>> refreshToken() async {
    final refreshToken = await SecureStorageService().refreshToken;
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      },
      body: {
        'refreshToken': refreshToken,
      }
    );

    final responseData = json.decode(response.body);
    
    if (responseData['success'] == true) {
      // Save new tokens
      await SecureStorageService().saveTokens(
        accessToken: responseData['data']['accessToken'],
        refreshToken: responseData['data']['refreshToken'] ?? refreshToken, // Use new refresh token if provided, else keep old one
      );

      final userMap = responseData['data']['user'] as Map<String, dynamic>;
      final user = User.fromJson(userMap);

      await StorageService.saveUserData(
        userData: user,
        originalJson: userMap);
      return responseData;
    } else {
      // If refresh fails, clear user data (force logout)
      await SecureStorageService().clearTokens();
      await StorageService.clearUserData();
      throw Exception(responseData['message'] ?? 'Token refresh failed');
    }
  }

  // Enhanced API call with automatic token refresh
  static Future<Map<String, dynamic>> authenticatedApiCall(
  String endpoint, {
  String method = 'GET',
  dynamic body,
}) async {
  // Check if token is expired
  if (await StorageService.isAccessTokenExpired) {
    // Try to refresh token
    await refreshToken();
  }

  final accessToken = await SecureStorageService().accessToken;
  if (accessToken == null) {
    throw Exception('No access token available');
  }

  // Create the request based on method
  http.Response response;
  final uri = Uri.parse('$baseUrl/$endpoint');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };

  switch (method.toUpperCase()) {
    case 'POST':
      response = await http.post(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      break;
    case 'PUT':
      response = await http.put(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      break;
    case 'DELETE':
      response = await http.delete(
        uri,
        headers: headers,
      );
      break;
    case 'GET':
    default:
      response = await http.get(
        uri,
        headers: headers,
      );
      break;
  }

  final responseData = json.decode(response.body);
  
  if (response.statusCode == 401) {
    // Token might be invalid, try refresh once
    await refreshToken();
    
    // Get new token and retry the request
    final newAccessToken = await SecureStorageService().accessToken;
    if (newAccessToken == null) {
      throw Exception('No access token available after refresh');
    }
    
    // Update headers with new token
    headers['Authorization'] = 'Bearer $newAccessToken';
    
    // Retry the request with new token (only once)
    switch (method.toUpperCase()) {
      case 'POST':
        response = await http.post(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(
          uri,
          headers: headers,
        );
        break;
      case 'GET':
      default:
        response = await http.get(
          uri,
          headers: headers,
        );
        break;
    }
    
    // Parse the retry response
    final retryResponseData = json.decode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return retryResponseData;
    } else {
      throw Exception(retryResponseData['message'] ?? 'API call failed after token refresh');
    }
  }

  if (response.statusCode >= 200 && response.statusCode < 300) {
    return responseData;
  } else {
    throw Exception(responseData['message'] ?? 'API call failed with status ${response.statusCode}');
  }
}

  // Company API methods
  static Future<Map<String, dynamic>> getAllCompanies() async {
    final response = await authenticatedApiCall('company/get-all');
    
    // Handle the nested companies array
    if (response['success'] == true) {
      final data = response['data'];
      if (data is Map<String, dynamic> && data.containsKey('companies')) {
        return {
          'success': true,
          'data': data['companies'], // Extract the companies array
          'total': data['total'] ?? 0,
        };
      }
    }
    return response;
  }

  static Future<Map<String, dynamic>> getCompanyById(int id) async {
    return await authenticatedApiCall('company/get/$id');
  }

  static Future<Map<String, dynamic>> createCompany(Map<String, dynamic> companyData) async {
    return await authenticatedApiCall(
      'company/create',
      method: 'POST',
      body: companyData,
    );
  }

  static Future<Map<String, dynamic>> updateCompany(int id, Map<String, dynamic> companyData) async {
    return await authenticatedApiCall(
      'company/update/$id',
      method: 'PUT',
      body: companyData,
    );
  }

  static Future<Map<String, dynamic>> deleteCompany(int id) async {
    return await authenticatedApiCall(
      'company/delete/$id',
      method: 'DELETE',
    );
  }

  // Status API methods
  static Future<Map<String, dynamic>> getCompanyStatus() async {
    return await authenticatedApiCall(
      'validate/haveCompany',
      method: 'GET',
    );
  }

  static Future<Map<String, dynamic>> getCostCenterStatus() async {
    return await authenticatedApiCall(
      'validate/haveCostCenter',
      method: 'GET',
    );
  }

  static Future<Map<String, dynamic>> getDepartmentStatus() async {
    return await authenticatedApiCall(
      'validate/haveDepartment',
      method: 'GET',
    );
  }

  // CostCenter API methods
  static Future<Map<String, dynamic>> getCostCenters([int? companyId]) async {
    String url = 'cost-center/get-all';
    
    if (companyId != null) {
      url += '?companyId=$companyId';
    }
    
    return await authenticatedApiCall(
      url,
      method: 'GET',
    );
  }

  static Future<Map<String, dynamic>> createCostCenter(Map<String, dynamic> data) async {
    return await authenticatedApiCall(
      'cost-center/create',
      method: 'POST',
      body: data,
    );
  }

  static Future<Map<String, dynamic>> updateCostCenter(int id, Map<String, dynamic> data) async {
    return await authenticatedApiCall(
      'cost-center/update/$id',
      method: 'PUT',
      body: data,
    );
  }

  static Future<Map<String, dynamic>> deleteCostCenter(int id) async {
    return await authenticatedApiCall(
      'cost-center/delete/$id',
      method: 'DELETE',
    );
  }

  // Department API methods
  static Future<Map<String, dynamic>> getDepartments([int? companyId]) async {
    String url = 'department/get-all';
    
    if (companyId != null) {
      url += '?companyId=$companyId';
    }
    
    return await authenticatedApiCall(
      url,
      method: 'GET',
    );
  }

  static Future<Map<String, dynamic>> getDepartmentsForReg([int? companyId]) async {
    String url = '$baseUrl/department/get-all';

    if (companyId != null) {
      url += '?companyId=$companyId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load departments: ${response.statusCode}');
    }
  }


  static Future<Map<String, dynamic>> createDepartment(Map<String, dynamic> data) async {
    return await authenticatedApiCall(
      'department/create',
      method: 'POST',
      body: data,
    );
  }

  static Future<Map<String, dynamic>> updateDepartment(int id, Map<String, dynamic> data) async {
    return await authenticatedApiCall(
      'department/update/$id',
      method: 'PUT',
      body: data,
    );
  }

  static Future<Map<String, dynamic>> deleteDepartment(int id) async {
    return await authenticatedApiCall(
      'department/delete/$id',
      method: 'DELETE',
    );
  }

  // User API methods
  static Future<Map<String, dynamic>> getUsers() async {
    return await authenticatedApiCall(
      'user/get-all',
      method: 'GET',
    );
  }

  static Future<Map<String, dynamic>> getUsersByDepartment(int departmentId) async {
    return await authenticatedApiCall(
      'user/get-all-by-department/$departmentId',
      method: 'GET',
    );
  }

  static Future<Map<String, dynamic>> getUsersByRole(
      String role,
  ) async {
    return await authenticatedApiCall(
      'user/get-all-by-role/$role',
      method: 'GET',
    );
  }

  static Future<Map<String, dynamic>> searchUsers(String query) async {
    return await authenticatedApiCall(
      'user/search?query=$query',
      method: 'GET',
    );
  }

  static Future<Map<String, dynamic>> searchUsersApproval(String query) async {
    return await authenticatedApiCall(
      'user/search-approval?query=$query',
      method: 'GET',
    );
  }

  static Future<Map<String, dynamic>> approveUser(String userId, bool state) async {
    return await authenticatedApiCall(
      'user/set-approval/$userId',
      method: 'PUT',
      body: {
        'state': state,
      },
    );
  }

  static Future<Map<String, dynamic>> getUsersByUserApproval() async {
    return await authenticatedApiCall(
      'user/get-user-by-approval',
      method: 'GET',
    );
  }

  // VehicleTypes API methods
  static Future<Map<String, dynamic>> getVehicleTypes() async {
    String url = 'cost-configurations/get-all';
    
    return await authenticatedApiCall(
      url,
      method: 'GET',
    );
  }

  static Future<Map<String, dynamic>> createVehicleType(Map<String, dynamic> data) async {
    return await authenticatedApiCall(
      'cost-configurations/create',
      method: 'POST',
      body: data,
    );
  }

  static Future<Map<String, dynamic>> updateVehicleType(int id, Map<String, dynamic> data) async {
    return await authenticatedApiCall(
      'cost-configurations/update/$id',
      method: 'PUT',
      body: data,
    );
  }

  static Future<Map<String, dynamic>> deleteVehicleType(int id) async {
    return await authenticatedApiCall(
      'cost-configurations/delete/$id',
      method: 'DELETE',
    );
  }

  // Vehicle API methods
  static Future<Map<String, dynamic>> getVehicles() async {
    String url = 'vehicle/get-all';
    
    return await authenticatedApiCall(
      url,
      method: 'GET',
    );
  }

  static Future<Map<String, dynamic>> getDriverVehicles(int id) async {
    String url = 'vehicle/driver/$id';
    
    return await authenticatedApiCall(
      url,
      method: 'GET',
    );
  }

  static Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> data) async {
    return await authenticatedApiCall(
      'vehicle/create',
      method: 'POST',
      body: data,
    );
  }

  static Future<Map<String, dynamic>> updateVehicle(int id, Map<String, dynamic> data) async {
    return await authenticatedApiCall(
      'vehicle/update/$id',
      method: 'PUT',
      body: data,
    );
  }

  static Future<Map<String, dynamic>> deleteVehicle(int id) async {
    return await authenticatedApiCall(
      'vehicle/delete/$id',
      method: 'DELETE',
    );
  }

  // UserCreation API methods
  static Future<Map<String, dynamic>> getUserCreations({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    // Prepare body data
    final Map<String, dynamic> body = {'page': page, 'limit': limit};

    if (status != null && status != 'All') {
      body['status'] = status.toLowerCase();
    }

    return await authenticatedApiCall(
      'user/get-all-by-status',
      method: 'POST',
      body: body, // This will be sent as body
    );
  }

  static Future<Map<String, dynamic>> approveUserCreationWithDetails(
    int userCreationId, {
    required String role,
    required String? departmentId, // Change to departmentId
  }) async {
    final body = {
      'role': role,
    };
    
    // Only add departmentId if it's not null and not empty
    if (departmentId != null && departmentId.isNotEmpty && departmentId != 'None') {
      body['departmentId'] = departmentId;
    }
    
    return await authenticatedApiCall(
      'user/approve/$userCreationId',
      method: 'PUT',
      body: body,
    );
  }

  static Future<Map<String, dynamic>> rejectUserCreation(int userCreationId) async {
    return await authenticatedApiCall(
      'user/reject/$userCreationId',
      method: 'PUT',
      body: {},
    );
  }

  // Approval Configuration API methods
  static Future<Map<String, dynamic>> getApprovalConfig() async {
    return await authenticatedApiCall(
      'approval-config/get-all',
      method: 'GET',
    );
    
  }

  static Future<Map<String, dynamic>> getMenuApprovalConfig() async {
    return await authenticatedApiCall(
      'approval-config/get-menu-approvals',
      method: 'GET',
    );
    
  }

  static Future<Map<String, dynamic>> createApprovalConfig(Map<String, dynamic> configData) async {
  return await authenticatedApiCall(
    'approval-config/create',
    method: 'POST',
    body: configData,
  );
}

  static Future<Map<String, dynamic>> updateApprovalConfig(int id, Map<String, dynamic> configData) async {
  return await authenticatedApiCall(
    'approval-config/update/$id',
    method: 'PUT',
    body: configData,
  );
}

  static Future<Map<String, dynamic>> deleteApprovalConfig(int id) async {
  return await authenticatedApiCall(
    'approval-config/delete/$id',
    method: 'DELETE',
  );
}

  // Status check for approval configuration
  static Future<Map<String, dynamic>> getApprovalConfigStatus() async {
    return await authenticatedApiCall(
      'validate/haveApprovalConfig',
      method: 'GET',
    );
  }

  // Trip API methods
  // Location search using authenticatedApiCall
  static Future<dynamic> searchLocations(String query) async {
    return await authenticatedApiCall(
      'locations/search?q=${Uri.encodeQueryComponent(query)}',
      method: 'GET',
    );
  }

  // Reverse geocode using authenticatedApiCall
  static Future<Map<String, dynamic>> reverseGeocode(double lat, double lon) async {
    return await authenticatedApiCall(
      'locations/reverse?lat=$lat&lon=$lon',
      method: 'GET',
    );
  }

  // Route calculation using authenticatedApiCall
  static Future<Map<String, dynamic>> calculateRoute(List<Map<String, dynamic>> coordinates) async {
    final data = await authenticatedApiCall(
      'routes/calculate',
      method: 'POST',
      body: {
        'points': coordinates,
        'vehicleType': 'car'
      },
    );

    return data;
  }

  static Future<AvailableVehiclesResponse> getAvailableVehicles(TripRequest tripRequest) async {
  try {
    print('Sending available vehicles request: ${tripRequest.toJson()}');
    
    final response = await authenticatedApiCall(
      'trips/available-vehicles',
      method: 'POST',
      body: tripRequest.toJson(),
    );

    print('Available vehicles API response: $response');

    // Check if the response contains the expected data structure
    if (response.containsKey('recommendedVehicles') || response.containsKey('allVehicles')) {
      print('Successfully parsed available vehicles - direct response structure');
      return AvailableVehiclesResponse.fromJson(response);
    } 
    // Check if response has nested data structure
    else if (response['success'] == true && response['data'] != null) {
      print('Successfully parsed available vehicles - nested data structure');
      return AvailableVehiclesResponse.fromJson(response['data']);
    } 
    // Check if response has success field but no data
    else if (response['success'] == true) {
      print('Successfully parsed available vehicles - success response');
      return AvailableVehiclesResponse.fromJson(response);
    } 
    else {
      final errorMessage = response['message'] ?? 'Failed to fetch available vehicles';
      print('API returned error: $errorMessage');
      throw Exception(errorMessage);
    }
  } catch (e) {
    print('Error in getAvailableVehicles: $e');
    rethrow;
  }
}

  static Future<TripBookingResponse> bookTrip(TripRequest tripRequest) async {
    final response = await authenticatedApiCall(
      'trips/create',
      method: 'POST',
      body: tripRequest.toJson(),
    );

    return TripBookingResponse.fromJson(response);
  }

  static Future<Map<String, dynamic>> cancelTrip(int tripId) async {
    return await authenticatedApiCall(
      'trips/cancel/$tripId',
      method: 'DELETE',
    );
  }

  static Future<Map<String, dynamic>> getTripStatus(int tripId) async {
    return await authenticatedApiCall(
      'trips/status/$tripId',
      method: 'GET',
    );
  }

  static Future<TripListResponse> getUserTrips(TripListRequest request) async {
    try {
      print('Getting user trips with filters: ${request.toJson()}');
      
      final response = await authenticatedApiCall(
        'trips/user-trips',
        method: 'POST',
        body: request.toJson(),
      );

      print('User trips API response: $response');

      if (response['success'] == true && response['data'] != null) {
        print('Successfully parsed user trips');
        return TripListResponse.fromJson(response['data']);
      } else {
        final errorMessage = response['message'] ?? 'Failed to fetch user trips';
        print('API returned error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in getUserTrips: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getPendingApprovals(Map<String, dynamic> request) async {
    try {
      print('Getting pending approvals with filters: $request');
      
      final response = await authenticatedApiCall(
        'trips/pending-approvals',
        method: 'POST',
        body: request,
      );

      //print('Pending approvals API response: $response');

      if (response['success'] == true) {
        return response;
      } else {
        final errorMessage = response['message'] ?? 'Failed to fetch pending approvals';
        print('API returned error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in getPendingApprovals: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getTripById(int tripId) async {
    try {
      return await authenticatedApiCall(
        'trips/get-by-id/$tripId',
        method: 'GET',
      );
    } catch (e) {
      print('Error fetching trip details: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> approveTrip(int tripId, String comment) async {
    return await authenticatedApiCall(
      'trips/approve/$tripId',
      method: 'POST',
      body: {
        'comment': comment,
      },
    );
  }

  static Future<Map<String, dynamic>> rejectTrip(int tripId, String comment) async {
    return await authenticatedApiCall(
      'trips/reject/$tripId',
      method: 'POST',
      body: {
        'rejectionReason': comment,
      },
    );
  }

//
// Add these methods to your ApiService class
  static Future<Map<String, dynamic>> approveScheduledTrip(
    int masterTripId,
    String comment,
  ) async {
    try {
      return await authenticatedApiCall(
        'trips/approve-scheduled/$masterTripId',
        method: 'POST',
        body: {'comment': comment},
      );
    } catch (e) {
      print('Error approving scheduled trip: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getTripWithInstances(int tripId) async {
    try {
      return await authenticatedApiCall(
        'trips/with-instances/$tripId',
        method: 'GET',
      );
    } catch (e) {
      print('Error fetching trip with instances: $e');
      rethrow;
    }
  }
//

  static Future<Map<String, dynamic>> getTripsForMeterReading(
    Map<String, dynamic> request,
  ) async {
    return await ApiService.authenticatedApiCall(
      'trips/for-meter-reading',
      method: 'POST',
      body: request,
    );
  }

  static Future<Map<String, dynamic>> getReadTrips(
    Map<String, dynamic> request,
  ) async {
    return await ApiService.authenticatedApiCall(
      'trips/already-read',
      method: 'POST',
      body: request,
    );
  }

  static Future<Map<String, dynamic>> recordOdometer(
    int tripId,
    double reading,
    String readingType,
  ) async {
    return await ApiService.authenticatedApiCall(
      'trips/record-odometer/$tripId',
      method: 'POST',
      body: {
        'reading': reading,
        'readingType': readingType, // 'start' or 'end'
      },
    );
  }

  static Future<DriverTripResponse> getDriverAssignedTrips(
      DriverTripListRequest request,
    ) async {
      try {
        return await ApiService.authenticatedApiCall(
          'trips/driver-assigned',
          method: 'POST',
          body: request.toJson(),
        ).then((response) {
          return DriverTripResponse.fromJson(response);
        });
      } catch (e) {
        print('Error getting driver trips: $e');
        rethrow;
      }
    }

  static Future<Map<String, dynamic>> startTrip(int tripId) async {
    return await authenticatedApiCall('trips/start/$tripId', method: 'POST');
  }

  static Future<Map<String, dynamic>> endTrip(int tripId) async {
    return await authenticatedApiCall('trips/end/$tripId', method: 'POST');
  }


    // Add these methods using your existing authenticatedApiCall method
  static Future<Map<String, dynamic>> getPendingUsers({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      return await authenticatedApiCall(
        'user/get-all-by-status',
        method: 'POST',
        body: {
          'status': 'pending',
          'page': page,
          'limit': limit,
        },
      );
    } catch (e) {
      print('Error fetching pending users: $e');
      rethrow;
    }
  }

  // Add a new method for getting approval users with pagination if needed
  static Future<Map<String, dynamic>> getApprovalUsersWithPagination({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      return await authenticatedApiCall(
        'user/get-user-by-approval',
        method: 'POST',
        body: {
          'page': page,
          'limit': limit,
        },
      );
    } catch (e) {
      print('Error fetching approval users with pagination: $e');
      rethrow;
    }
  }
  
  // Add a method to get user details by ID
  static Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      return await authenticatedApiCall(
        'user/get/$userId',
        method: 'GET',
      );
    } catch (e) {
      print('Error fetching user by ID: $e');
      rethrow;
    }
  }
  
  // Add a method to update user approval status (alternative to existing approveUser)
  static Future<Map<String, dynamic>> updateUserApprovalStatus(
    String userId,
    bool isApproved,
  ) async {
    try {
      return await authenticatedApiCall(
        'user/set-approval/$userId',
        method: 'PUT',
        body: {
          'state': isApproved,
        },
      );
    } catch (e) {
      print('Error updating user approval status: $e');
      rethrow;
    }
  }



  // Notification API methods
  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? read,
  }) async {
    try {
      final Map<String, dynamic> body = {'page': page, 'limit': limit};

      if (read != null) {
        body['read'] = read;
      }

      return await authenticatedApiCall(
        'notifications',
        method: 'POST',
        body: body,
      );
    } catch (e) {
      print('Error fetching notifications: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(
    String notificationId,
  ) async {
    try {
      return await authenticatedApiCall(
        'notifications/$notificationId/read',
        method: 'PUT',
        body: {},
      );
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      return await authenticatedApiCall(
        'notifications/mark-all-read',
        method: 'PUT',
        body: {},
      );
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> deleteNotification(
    String notificationId,
  ) async {
    try {
      return await authenticatedApiCall(
        'notifications/$notificationId',
        method: 'DELETE',
      );
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      return await authenticatedApiCall(
        'notifications/unread-count',
        method: 'GET',
      );
    } catch (e) {
      print('Error fetching unread count: $e');
      rethrow;
    }
  }

}

