import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Add this import
import 'package:vehiclereservation_frontend_flutter_/core/services/firebase_notification_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/auth_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/device_helper.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/available_vehicles_response.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/checklist_models.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/driver_trip_response.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/trip_booking_response.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/trip_list_response.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/trip_request_model.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/dashboard_stats.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/services/storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/core/config/api_config.dart';
import 'dart:math' as math;

import 'package:vehiclereservation_frontend_flutter_/data/new_models/trip_card_model.dart';

int min(int a, int b) => math.min(a, b);

class ApiService {
  //static const String baseUrl = ApiConfig.baseUrl;
  static final String baseUrl = ApiConfig.baseUrl;
  //static String get baseUrl => ApiConfig.baseUrl;

  static bool _isRefreshing = false;
  
  // Add a flag to track if session is expired
  static bool _sessionExpired = false;


  static Future<Map<String, dynamic>> login(
      String username, String password) async {

    // Reset API service session flag
    ApiService.resetSession();

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

  static Future<Map<String, dynamic>> verifyUserForPasswordReset({
    required String username,
    required String mobile,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-password-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'mobile': mobile}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Failed to verify user: $e');
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String username,
    required String mobile,
    required String newPassword,
    required String confirmPassword,
    String? token,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'username': username,
        'mobile': mobile,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };

      if (token != null) {
        body['token'] = token;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Failed to reset password: $e');
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
  static Future<Map<String, dynamic>> refreshTokenFun() async {
    //print("===== Refreshing tokens ====");

    final refreshToken = await SecureStorageService().refreshToken;
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      //print("Refresh response status: ${response.statusCode}");
      //print("Refresh response body: ${response.body}");

      final responseData = json.decode(response.body);

      // Check if response is successful (status 200 OR 201 and success true)
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          responseData['success'] == true) {
        // Success case - don't throw error
        final data = responseData['data'];

        if (data == null) {
          throw Exception('Invalid response: missing data field');
        }

        final newAccessToken = data['accessToken'];
        final newRefreshToken = data['refreshToken'];

        if (newAccessToken == null) {
          throw Exception('Invalid response: missing accessToken');
        }

        // Save new tokens
        await SecureStorageService().saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken ?? refreshToken,
        );

        // Update user data
        if (data['user'] != null) {
          try {
            final userMap = data['user'] as Map<String, dynamic>;
            final user = User.fromJson(userMap);
            await StorageService.saveUserData(
              userData: user,
              originalJson: userMap,
            );
          } catch (e) {
            //print('Warning: Failed to save user data during refresh: $e');
          }
        }

        //print("✅ Token refresh successful");
        // Return the response data (don't throw)
        return responseData;
      } else {
        // Error case
        final errorMessage = responseData['message'] ?? 'Token refresh failed';
        //print('Refresh failed: $errorMessage');

        // Clear tokens on auth failure
        // await SecureStorageService().clearTokens();
        // await StorageService.clearUserData();
        //AuthManager.handleSessionTimeout();
        throw Exception(errorMessage);
      }
    } catch (e) {
      //print('Refresh token error: $e');

      // Don't clear tokens on network errors
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Timeout')) {
        throw Exception('Network error: Unable to refresh token');
      }

      // Clear tokens on other errors
      // await SecureStorageService().clearTokens();
      // await StorageService.clearUserData();
      //AuthManager.handleSessionTimeout();
      throw Exception('Failed to refresh token: $e');
    }
  }

  // Enhanced API call with automatic token refresh
  static Future<Map<String, dynamic>> authenticatedApiCall(
    String endpoint, {
    String method = 'GET',
    dynamic body,
    int retryCount = 0,
  }) async {

    if (_sessionExpired) {
      throw Exception('Session expired. Please login again.');
    }

    const maxRetries = 1;

    // Get final access token
    final finalAccessToken = await SecureStorageService().accessToken;
    if (finalAccessToken == null) {
      throw Exception('No access token available. Please login again.');
    }

    // Create the request based on method
    http.Response response;
    final uri = Uri.parse('$baseUrl/$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $finalAccessToken',
    };

    try {
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
          response = await http.delete(uri, headers: headers);
          break;
        case 'GET':
        default:
          response = await http.get(uri, headers: headers);
          break;
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }

    final responseData = json.decode(response.body);

    // Handle 401 Unauthorized
    if (response.statusCode == 401 && retryCount < maxRetries) {
      // Try to refresh token
      if (_isRefreshing) {
        await Future.delayed(Duration(milliseconds: 100));
        return authenticatedApiCall(
          endpoint,
          method: method,
          body: body,
          retryCount: retryCount,
        );
      }

      _isRefreshing = true;
      bool refreshSuccess = false;

      try {
        await refreshTokenFun();
        refreshSuccess = true;
        print("✅ Token refreshed, retrying request...");
      } catch (e) {
        print('Refresh failed: $e');
        refreshSuccess = false;
      } finally {
        _isRefreshing = false;
      }

      // Retry the request with new token
      // Only retry if refresh was successful
      if (refreshSuccess) {
        // Retry the request with new token
        return authenticatedApiCall(
          endpoint,
          method: method,
          body: body,
          retryCount: retryCount + 1,
        );
      }
      else {
        // Refresh failed - mark session as expired, clear tokens, and show timeout
        _sessionExpired = true;
        AuthManager.handleSessionTimeout();
        throw Exception('Session expired. Please login again.');
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      throw Exception(
        responseData['message'] ??
            'API call failed with status ${response.statusCode}',
      );
    }
  }

  static void resetSession() {
    _sessionExpired = false;
    _isRefreshing = false;
  }

  static Future<Map<String, dynamic>> initializeUser(int id) async {
    // Reset API service session flag
    ApiService.resetSession();

    //final id = StorageService.userData?.id;

    final res = await authenticatedApiCall('user/initial-user-by-id/$id');

    if (res['success'] == true) {

      // Convert the user map to User object and save
      final userMap = res['data']['user'] as Map<String, dynamic>;
      final user = User.fromJson(userMap);

      await StorageService.saveUserData(userData: user, originalJson: userMap);

      return res;
    } else {
      //throw Exception(errorData['message'] ?? 'Login failed: ${response.statusCode}');
      throw res['message'] ?? 'User initialization failed';
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
  static Future<Map<String, dynamic>> getCostCenters({
    int? companyId,
    int page = 1,
    int limit = 10,
  }) async {
    String url = 'cost-center/get-all';

    List<String> params = [];

    if (companyId != null) {
      params.add('companyId=$companyId');
    }

    // Add pagination parameters
    params.add('page=$page');
    params.add('limit=$limit');

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    return await authenticatedApiCall(url, method: 'GET');
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
  static Future<Map<String, dynamic>> getDepartments({
    int? companyId,
    int page = 1,
    int limit = 10,
  }) async {
    String url = 'department/get-all';

    List<String> params = [];

    if (companyId != null) {
      params.add('companyId=$companyId');
    }

    // Add pagination parameters
    params.add('page=$page');
    params.add('limit=$limit');

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    return await authenticatedApiCall(url, method: 'GET');
  }

  static Future<Map<String, dynamic>> getUserDepartments({
    int page = 1,
    int limit = 10,
  }) async {
    String url = 'department/get-user-all';

    List<String> params = [];

    // Add pagination parameters
    params.add('page=$page');
    params.add('limit=$limit');

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    return await authenticatedApiCall(url, method: 'GET');
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

  static Future<Map<String, dynamic>> getAllHodUsers() async {
    return await authenticatedApiCall(
      'user/get-all-hod',
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

  // Enhanced trip_service.dart
  static Future<Map<String, dynamic>> checkTripCreationEligibility() async {
    final response = await authenticatedApiCall(
      'user/can-create-trip',
      method: 'GET',
    );
    return response;
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

  static Future<Map<String, dynamic>> searchTripsApprovalUsers(String query) async {
    return await authenticatedApiCall(
      'user/search-trip-approval?query=$query',
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

  static Future<Map<String, dynamic>> tripApproveUser(
    String userId,
    bool state,
  ) async {
    return await authenticatedApiCall(
      'user/set-trip-approval/$userId',
      method: 'PUT',
      body: {'state': state},
    );
  }

  static Future<Map<String, dynamic>> getUsersByUserApproval() async {
    return await authenticatedApiCall(
      'user/get-user-by-approval',
      method: 'GET',
    );
  }

  static Future<Map<String, dynamic>> getUsersByTripApproval() async {
    return await authenticatedApiCall(
      'user/get-user-by-trip-approval',
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

  static Future<AvailableVehiclesResponse> getReviewAvailableVehicles(
    String tripId,
    {
      int page = 0,
      int pageSize = 10,
      String? search,
    }
  ) async {
    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {
        'tripId': tripId, // Add tripId as query parameter
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      // Add search parameter if provided
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      // Convert query parameters to URL string
      final queryString = Uri(queryParameters: queryParams).query;

      final response = await authenticatedApiCall(
        'trips/available-vehicles-review?$queryString',
        method: 'POST',
        //body: tripRequest.toJson(),
      );

      print('Available vehicles API response: $response');

      // Check if the response contains the expected data structure
      if (response.containsKey('recommendedVehicles') ||
          response.containsKey('allVehicles')) {
        print(
          'Successfully parsed available vehicles - direct response structure',
        );
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
      } else {
        final errorMessage =
            response['message'] ?? 'Failed to fetch available vehicles';
        print('API returned error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in getAvailableVehicles: $e');
      rethrow;
    }
  }

  static Future<bool> addVehicleToTrip({
    required String tripId,
    required String vehicleId,
  }) async {
    final body = {'tripId': tripId, 'vehicleId': vehicleId};

    final response = await authenticatedApiCall(
      'trips/assign-trip-vehicle',
      method: 'POST',
      body: body,
    );

    return true;
  }

  static Future<TripBookingResponse> bookTrip(TripRequest tripRequest) async {
    final response = await authenticatedApiCall(
      'trips/create',
      method: 'POST',
      body: tripRequest.toJson(),
    );

    return TripBookingResponse.fromJson(response);
  }

  static Future<TripBookingResponse> bookTripAsDraft(TripRequest tripRequest) async {
    final response = await authenticatedApiCall(
      'trips/create-as-draft',
      method: 'POST',
      body: tripRequest.toJson(),
    );

    return TripBookingResponse.fromJson(response);
  }

  static Future<Map<String, dynamic>> cancelTrip(int tripId) async {
    return await authenticatedApiCall(
      'trips/cancel/$tripId',
      method: 'POST',
    );
  }

  static Future<Map<String, dynamic>> joinTrip(int tripId) async {
    return await authenticatedApiCall(
      'trips/join/$tripId', 
      method: 'POST'
    );
  }

  static Future<Map<String, dynamic>> addMultiplePassengersToTrip(
    int tripId,
    List<dynamic> passengerIds
  ) async {
    return await authenticatedApiCall(
      'trips/add-multiple-passengers/$tripId', 
      method: 'POST',
      body: {
        'passengerIds': passengerIds
      }
    );
  }
  
  static Future<Map<String, dynamic>> confirmReviewTrip(int tripId) async {
    return await authenticatedApiCall(
      'trips/confirm-review/$tripId',
      method: 'POST',
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

  static Future<TripCardResponse> getUserTripsNew(
    TripCardListRequest request
  ) async {
    try {
      return await ApiService.authenticatedApiCall(
        'trips/user-trips',
        method: 'POST',
        body: request.toJson(),
      ).then((response) {
        return TripCardResponse.fromJson(response);
      });
    } catch (e) {
      print('Error getting user trips: $e');
      rethrow;
    }
  }

  static Future<TripCardResponse> getAllTrips(
    TripCardListRequest request,
  ) async {
    try {
      return await ApiService.authenticatedApiCall(
        'trips/all-trips',
        method: 'POST',
        body: request.toJson(),
      ).then((response) {
        return TripCardResponse.fromJson(response);
      });
    } catch (e) {
      print('Error getting all trips: $e');
      rethrow;
    }
  }

  static Future<TripCardResponse> getAllExceedTrips(
    TripCardListRequest request,
  ) async {
    try {
      return await ApiService.authenticatedApiCall(
        'trips/all-exceed-trips',
        method: 'POST',
        body: request.toJson(),
      ).then((response) {
        return TripCardResponse.fromJson(response);
      });
    } catch (e) {
      print('Error getting all exceed trips: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> acceptExceedTrip(
    int tripId,
  ) async {
    try {
      return await ApiService.authenticatedApiCall(
        'trips/accept-exceed-trip/$tripId',
        method: 'POST',
      );
    } catch (e) {
      print('Error accepting exceed trips: $e');
      rethrow;
    }
  }

  static Future<TripListResponse> getSupervisorTrips(TripListRequest request) async {
    try {
      //print('Getting user trips with filters: ${request.toJson()}');

      final response = await authenticatedApiCall(
        'trips/supervisor-trips',
        method: 'POST',
        body: request.toJson(),
      );

      //print('User trips API response: $response');

      if (response['success'] == true && response['data'] != null) {
        //print('Successfully parsed user trips');
        return TripListResponse.fromJson(response['data']);
      } else {
        final errorMessage =
            response['message'] ?? 'Failed to fetch user trips';
        //print('API returned error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      //print('Error in getUserTrips: $e');
      rethrow;
    }
  }

  static Future<TripCardResponse> getSupervisorTripsNew(
    TripCardListRequest request,
  ) async {
    try {
      return await ApiService.authenticatedApiCall(
        'trips/supervisor-trips',
        method: 'POST',
        body: request.toJson(),
      ).then((response) {
        return TripCardResponse.fromJson(response);
      });
    } catch (e) {
      print('Error getting driver trips: $e');
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

  static Future<TripCardResponse> getPendingApprovalsNew(
    TripCardListRequest request
  ) async {
    try {
      return await ApiService.authenticatedApiCall(
        'trips/pending-approvals-new',
        method: 'POST',
        body: request.toJson(),
      ).then((response) {
        return TripCardResponse.fromJson(response);
      });
    } catch (e) {
      print('Error getting driver trips: $e');
      rethrow;
    }
  }


  // Dashboard API methods
  static Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await authenticatedApiCall(
        'dashboard/stats',
        method: 'GET',
      );

      if (response['success'] == true && response['data'] != null) {
        return DashboardStats.fromJson(response['data']);
      } else if (response['data'] != null) {
        // Fallback if success field is missing but data is present
        return DashboardStats.fromJson(response['data']);
      } else {
        // Return empty stats if no data
        return DashboardStats();
      }
    } catch (e) {
      print('Error in getDashboardStats: $e');
      return DashboardStats();
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

  static Future<TripCardResponse> getTripsForMeterReadingNew(
    TripCardListRequest request,
  ) async {
    try {
      return await ApiService.authenticatedApiCall(
        'trips/for-meter-reading-new',
        method: 'POST',
        body: request.toJson(),
      ).then((response) {
        return TripCardResponse.fromJson(response);
      });
    } catch (e) {
      print('Error getting driver trips: $e');
      rethrow;
    }
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

  static Future<TripCardResponse> getDriverAssignedTripsNew(
    TripCardListRequest request,
  ) async {
    try {
      return await ApiService.authenticatedApiCall(
        'trips/driver-assigned',
        method: 'POST',
        body: request.toJson(),
      ).then((response) {
        return TripCardResponse.fromJson(response);
      });
    } catch (e) {
      print('Error getting driver trips: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> startTrip(int tripId) async {
    return await authenticatedApiCall('trips/start/$tripId', method: 'POST');
  }

  static Future<Map<String, dynamic>> endTrip(int tripId, int passengerCount) async {
    return await authenticatedApiCall(
      'trips/end/$tripId',
      method: 'POST',
      body: {'passengerCount': passengerCount},
    );
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
      // Build the URL with query parameters
      String url = 'notifications/get-all?page=$page&limit=$limit';

      if (read != null) {
        url += '&read=$read';
      }

      return await authenticatedApiCall(
        url, // Pass the full URL with query parameters
        method: 'GET',
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
        'notifications/read/$notificationId',
        method: 'PUT',
        body: {},
      );
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> markNotificationAsUnread(
    String notificationId,
  ) async {
    try {
      return await authenticatedApiCall(
        'notifications/unread/$notificationId',
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
        'notifications/delete/$notificationId',
        method: 'DELETE',
      );
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> deleteAllNotification() async {
    try {
      return await authenticatedApiCall(
        'notifications/delete-all',
        method: 'DELETE',
      );
    } catch (e) {
      print('Error deleting all notifications: $e');
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


  static Future<Map<String, dynamic>> getAdminDashboardStats({
    String? departmentId,
  }) async {
    try {
      // Build URL with query parameters
      String url = 'dashboard/admin/stats';

      // Add departmentId to query params if provided
      if (departmentId != null && departmentId.isNotEmpty) {
        url += '?departmentId=$departmentId';
      }

      // Replace with your actual API endpoint
      return await authenticatedApiCall(
        url, // Your API endpoint with query params
        method: 'GET',
      );
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      rethrow;
    }
  }

  static Future<Uint8List?> downloadTripReport({
    required DateTime fromDate,
    required DateTime toDate,
    required String format,
  }) async {
    try {
      // Validate input
      if (fromDate.isAfter(toDate)) {
        throw Exception('From date must be before or equal to to date');
      }

      // Check date range (max 1 year)
      final maxDays = 365;
      final daysDifference = toDate.difference(fromDate).inDays;
      if (daysDifference > maxDays) {
        throw Exception('Date range cannot exceed $maxDays days');
      }

      // Format dates
      final dateFormat = DateFormat('yyyy-MM-dd');
      final formattedFromDate = dateFormat.format(fromDate);
      final formattedToDate = dateFormat.format(toDate);

      print('📋 ======== DOWNLOAD REPORT REQUEST ========');
      print('📋 From Date: $formattedFromDate');
      print('📋 To Date: $formattedToDate');
      print('📋 Format: $format');

      // Download report
      return await _downloadBinaryData(
        'trips/report/download',
        method: 'POST',
        body: {
          'fromDate': formattedFromDate,
          'toDate': formattedToDate,
          'format': format.toLowerCase(),
        },
      );
    } catch (e) {
      print('❌ ======== REPORT DOWNLOAD ERROR ========');
      print('❌ Error: ${e.toString()}');

      // Rethrow with user-friendly message if needed
      if (e is! Exception) {
        rethrow;
      }

      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('no trips found') ||
          errorStr.contains('no data available')) {
        throw Exception('No trips found for the selected date range');
      } else if (errorStr.contains('invalid date') ||
          errorStr.contains('date format')) {
        throw Exception('Invalid date format. Please check your dates.');
      } else if (errorStr.contains('start date must be')) {
        throw Exception('Start date must be before end date');
      } else if (errorStr.contains('date range cannot exceed')) {
        throw Exception('Date range cannot exceed 365 days');
      } else if (errorStr.contains('module not found') ||
          errorStr.contains('pdfkit') ||
          errorStr.contains('exceljs')) {
        throw Exception('Report generation service is temporarily unavailable');
      } else if (errorStr.contains('network') ||
          errorStr.contains('connection') ||
          errorStr.contains('socket')) {
        throw Exception(
          'Network error. Please check your connection and try again.',
        );
      } else if (errorStr.contains('timeout')) {
        throw Exception(
          'Request timeout. The report is taking too long to generate.',
        );
      } else if (errorStr.contains('unauthorized') ||
          errorStr.contains('token')) {
        throw Exception('Session expired. Please log in again.');
      } else {
        // Generic error with fallback
        final message = e.toString().replaceAll('Exception: ', '');
        throw Exception(
          message.isNotEmpty ? message : 'Failed to generate report',
        );
      }
    }
  }

  /// Special method for downloading binary data (PDF/Excel files)
  static Future<Uint8List> _downloadBinaryData(
    String endpoint, {
    String method = 'POST',
    Map<String, dynamic>? body,
  }) async {
    print('🔄 ======== BINARY DOWNLOAD START ========');
    print('🔄 Endpoint: $endpoint');

    try {
      // Get token
      final token = await SecureStorageService().accessToken;
      if (token == null || token.isEmpty) {
        throw Exception('Your session has expired. Please log in again.');
      }

      // Create URL
      final url = Uri.parse('$baseUrl/$endpoint');
      print('🌐 URL: $url');

      // Create request
      final request = http.Request(method, url);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = '*/*';
      request.headers['Cache-Control'] = 'no-cache';

      if (method == 'POST' && body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = json.encode(body);
        print('📤 Request body: ${request.body}');
      }

      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw http.ClientException('Request timeout after 60 seconds');
        },
      );

      print('📊 Status Code: ${streamedResponse.statusCode}');

      // Handle different status codes
      if (streamedResponse.statusCode >= 200 &&
          streamedResponse.statusCode < 300) {
        // Success - read the response bytes
        final bytes = await streamedResponse.stream.toBytes();
        print('✅ Successfully downloaded: ${bytes.length} bytes');

        // Validate file size
        if (bytes.isEmpty) {
          throw Exception('Received empty file from server');
        }

        // Validate file type based on content type
        final contentType = streamedResponse.headers['content-type'] ?? '';
        if (contentType.contains('pdf') ||
            contentType.contains('excel') ||
            contentType.contains('sheet')) {
          return bytes;
        } else {
          // Might be an error in JSON format
          try {
            final errorText = utf8.decode(bytes);
            final errorJson = json.decode(errorText) as Map<String, dynamic>;

            String errorMessage = 'Failed to generate report';
            if (errorJson.containsKey('message')) {
              errorMessage = errorJson['message'] as String;
            } else if (errorJson.containsKey('error')) {
              errorMessage = errorJson['error'] as String;
            }

            // Clean up error message
            if (errorMessage.startsWith('Failed to generate report: ')) {
              errorMessage = errorMessage.substring(
                'Failed to generate report: '.length,
              );
            }

            throw Exception(errorMessage);
          } catch (_) {
            // Not JSON, just throw generic error
            throw Exception('Server returned invalid file format');
          }
        }
      } else {
        // Error - try to parse error response
        final bytes = await streamedResponse.stream.toBytes();
        String errorMessage =
            'Failed to generate report (Status: ${streamedResponse.statusCode})';

        try {
          final errorText = utf8.decode(bytes);
          print('❌ Error response text: $errorText');

          final errorJson = json.decode(errorText) as Map<String, dynamic>;

          if (errorJson.containsKey('message')) {
            errorMessage = errorJson['message'] as String;
          } else if (errorJson.containsKey('error')) {
            if (errorJson['error'] is Map) {
              final errorMap = errorJson['error'] as Map<String, dynamic>;
              if (errorMap.containsKey('message')) {
                errorMessage = errorMap['message'] as String;
              }
            } else {
              errorMessage = errorJson['error'] as String;
            }
          }
        } catch (_) {
          // Couldn't parse as JSON, use default message
          if (streamedResponse.statusCode == 401) {
            errorMessage = 'Session expired. Please log in again.';
          } else if (streamedResponse.statusCode == 403) {
            errorMessage = 'You do not have permission to generate reports.';
          } else if (streamedResponse.statusCode == 404) {
            errorMessage = 'Report endpoint not found.';
          } else if (streamedResponse.statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          } else if (streamedResponse.statusCode == 502 ||
              streamedResponse.statusCode == 503 ||
              streamedResponse.statusCode == 504) {
            errorMessage =
                'Service temporarily unavailable. Please try again later.';
          }
        }

        throw Exception(errorMessage);
      }
    } on http.ClientException catch (e) {
      print('💥 HTTP Client Error: ${e.message}');
      if (e.message.contains('timeout')) {
        throw Exception(
          'Request timeout. The report is taking too long to generate.',
        );
      } else if (e.message.contains('Failed host lookup') ||
          e.message.contains('Network is unreachable')) {
        throw Exception(
          'Network error. Please check your internet connection.',
        );
      }
      rethrow;
    } on SocketException catch (e) {
      print('💥 Socket Error: ${e.message}');
      throw Exception(
        'Network error. Please check your connection and try again.',
      );
    } on FormatException catch (e) {
      print('💥 Format Error: ${e.message}');
      throw Exception('Invalid response from server. Please try again.');
    } catch (e) {
      print('💥 Unexpected Error in _downloadBinaryData: $e');
      rethrow;
    }
  }

  static Future<ChecklistResponse?> getChecklistByDate({
  required String vehicleId,
  required DateTime date,
}) async {
  try {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    
    print('🔍 Fetching checklist for vehicle $vehicleId on $formattedDate');
    
    final response = await authenticatedApiCall(
      'checklist/vehicle/$vehicleId/date/$formattedDate',
      method: 'GET',
    );
    
    print('📥 FULL API Response:');
    print('  Response type: ${response.runtimeType}');
    print('  Response keys: ${response.keys}');
    print('  Has data key: ${response.containsKey('data')}');
    print('  Data value: ${response['data']}');
    print('  Data type: ${response['data']?.runtimeType}');
    
    // Try different approaches to get the data
    dynamic checklistData;
    
    if (response['data'] != null && response['data'] != false) {
      checklistData = response['data'];
      print('✅ Using response[\'data\']');
    } else if (response.isNotEmpty && response.containsKey('id')) {
      // Maybe the data is directly in the response
      checklistData = response;
      print('✅ Using direct response');
    } else {
      print('❌ No checklist data found');
      return null;
    }
    
    print('📋 Parsing checklist data...');
    try {
      final checklist = ChecklistResponse.fromJson(checklistData);
      print('✅ Checklist parsed successfully. ID: ${checklist.id}');
      print('✅ Checklist has ${checklist.responses.length} responses');
      return checklist;
    } catch (e) {
      print('❌ Error parsing checklist: $e');
      print('❌ Checklist data structure: $checklistData');
      return null;
    }
    
  } catch (e) {
    print('❌ Error in getChecklistByDate: $e');
    print('❌ Stack trace: ${e.toString()}');
    return null;
  }
}

  static Future<ChecklistResponse> submitChecklist({
    required String vehicleId,
    required String vehicleRegNo,
    required DateTime checklistDate,
    required String checkedById,
    required String checkedByName,
    required String checkedByRole,
    required Map<String, ChecklistItemRequest> responses,
  }) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(checklistDate);

      print('🚀 Submitting checklist...');

      final request = ChecklistSubmitRequest(
        vehicleId: int.parse(vehicleId),
        vehicleRegNo: vehicleRegNo,
        checklistDate: formattedDate,
        checkedById: int.parse(checkedById),
        responses: responses,
      );

      print('📤 Sending POST request to checklist/submit');
      final response = await authenticatedApiCall(
        'checklist/submit',
        method: 'POST',
        body: request.toJson(),
      );

      print('📥 API Response received');
      print('Response type: ${response.runtimeType}');
      print('Response keys: ${response.keys}');

      // CRITICAL FIX: The API returns the checklist directly, not wrapped in 'data'
      if (response.containsKey('id')) {
        print('✅ Response contains checklist data directly');
        // The response IS the checklist data
        return ChecklistResponse.fromJson(response);
      } else if (response['data'] != null) {
        print('✅ Response contains checklist in data field');
        // The response has data field containing the checklist
        return ChecklistResponse.fromJson(response['data']);
      } else {
        print('❌ Response does not contain checklist data');
        throw Exception('No checklist data in response');
      }
    } catch (e) {
      print('❌ Error in submitChecklist: $e');
      print('❌ Stack trace: ${e.toString()}');
      rethrow;
    }
  }
  
  static Future<bool> checkIfChecklistExists({
    required String vehicleId,
    required DateTime date,
  }) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      print('🔍 Checking if checklist exists for vehicle $vehicleId on $formattedDate');
      
      final response = await authenticatedApiCall(
        'checklist/vehicle/$vehicleId/date/$formattedDate/exists',
        method: 'GET',
      );
      
      print('📥 Exists check response: $response');
      print('  exists value: ${response['exists']}');
      
      return response['exists'] ?? false;
    } catch (e) {
      print('❌ Error checking checklist existence: $e');
      return false;
    }
  }

  /*
  static Future<void> updateFcmToken({
    required fcmToken
  }) async {
    try {
      print('🔄 Updating FCM token: $fcmToken');
      await authenticatedApiCall(
        'notifications/update-fcm-token',
        method: 'PUT',
        body: {
          'fcmToken': fcmToken,
        },
      );
      print('✅ FCM token updated successfully');
    } catch (e) {
      print('❌ Error updating FCM token: $e');
    }
  }
  */

  static Future<void> updateFcmToken({
    required fcmToken,
  }) async {
    try {
      print('🔄 Updating FCM token: $fcmToken');

      // Get device information from helper
      final deviceId = await DeviceHelper.getDeviceId();
      final deviceName = await DeviceHelper.getDeviceName();
      final deviceType = DeviceHelper.getDeviceType();
      
      await authenticatedApiCall(
        'notifications/update-fcm-token-new',
        method: 'PUT',
        body: {
          'fcmToken': fcmToken,
          'deviceId': deviceId,
          'deviceName': deviceName,
          'deviceType': deviceType,
        },
      );
      print('✅ FCM token updated successfully');
    } catch (e) {
      print('❌ Error updating FCM token: $e');
    }
  }

  /*
  static Future<void> deleteFcmToken() async {
    try {
      print('🔄 Deleting FCM token');
      await authenticatedApiCall(
        'notifications/delete-fcm-token',
        method: 'DELETE',
      );
      print('✅ FCM token deleted successfully');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    } 
  }
  */

  static Future<void> deleteFcmToken(int? userId) async {
    try {
      print('🔄 Deleting FCM token');

      final deviceId = await DeviceHelper.getDeviceId();
      /*
      await authenticatedApiCall(
        'notifications/delete-fcm-token-new',
        method: 'PUT',
        body: {'deviceId': deviceId},
      );
      */
      await http.put(
        Uri.parse('$baseUrl/notifications/delete-fcm-token-new'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'deviceId': deviceId, 'userId': userId}),
      );
      print('✅ FCM token deleted successfully $deviceId');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }

  // api_service.dart
  static Future<void> registerWebDevice({
    required String deviceId,
    required String deviceName,
  }) async {
    try {
      print('🔄 Registering web device: $deviceName');

      await authenticatedApiCall(
        'notifications/update-fcm-token-new',
        method: 'PUT',
        body: {
          'deviceId': deviceId,
          'deviceName': deviceName,
          'deviceType': 'web',
        },
      );
      //print('✅ Web device registered successfully');
    } catch (e) {
      print('❌ Error registering web device: $e');
    }
  }

  static Future<void> unregisterWebDevice({required String deviceId, int? userId}) async {
    try {
      /*
      await authenticatedApiCall(
        'notifications/delete-fcm-token-new',
        method: 'PUT',
        body: {'deviceId': deviceId},
      );
      */
      await http.put(
        Uri.parse('$baseUrl/notifications/delete-fcm-token-new'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'deviceId': deviceId, 'userId': userId}),
      );
      print('✅ Web device unregistered successfully');
    } catch (e) {
      print('❌ Error unregistering web device: $e');
    }
  }

  static Future<Map<String, dynamic>?> trackUserActivity({bool? isLogin}) async {
    try {
      print('🔄 Current action : ${isLogin == true ? "Login" : "Access"}');

      // Get device information from helper
      //final deviceId = await DeviceHelper.getDeviceId();
      final deviceName = await DeviceHelper.getDeviceName();
      final platform = DeviceHelper.getDeviceType();
      final appVersion = await DeviceHelper.getAppVersion();

      final res = await authenticatedApiCall(
        'user/update-user-log',
        method: 'PUT',
        body: {
          'deviceName': deviceName,
          'platform': platform,
          'appVersion': appVersion,
          'dateTime': DateTime.now().toIso8601String(),
          'isLogin': isLogin ?? false,
        },
      );
      print('✅ User activity tracked successfully');
      return res;
    } catch (e) {
      print('❌ Error tracking user activity: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getAllSavedLocations() async {
    try {
      return await ApiService.authenticatedApiCall(
        'saved-locations/get-all',
        method: 'GET',
      );
    } catch (e) {
      print('Error getting saved locations: $e');
      rethrow;
    }
  }

  // Get single saved location by ID
  static Future<Map<String, dynamic>> getSavedLocation(String id) async {
    try {
      return await ApiService.authenticatedApiCall(
        'saved-locations/get/$id',
        method: 'GET',
      );
    } catch (e) {
      print('Error getting saved location: $e');
      rethrow;
    }
  }

  // Create new saved location
  static Future<Map<String, dynamic>> createSavedLocation({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? label,
    bool isFavorite = false,
  }) async {
    try {
      return await ApiService.authenticatedApiCall(
        'saved-locations/save',
        method: 'POST',
        body: {
          'name': name,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'label': label,
          'isFavorite': isFavorite,
        },
      );
    } catch (e) {
      print('Error creating saved location: $e');
      rethrow;
    }
  }

  // Update saved location
  static Future<Map<String, dynamic>> updateSavedLocation(
    String id, {
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? label,
    bool? isFavorite,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (address != null) body['address'] = address;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (label != null) body['label'] = label;
      if (isFavorite != null) body['isFavorite'] = isFavorite;

      return await ApiService.authenticatedApiCall(
        'saved-locations/update/$id',
        method: 'PUT',
        body: body,
      );
    } catch (e) {
      print('Error updating saved location: $e');
      rethrow;
    }
  }

  // Increment use count (when user selects a saved location)
  static Future<Map<String, dynamic>> incrementUseCount(String id) async {
    try {
      return await ApiService.authenticatedApiCall(
        'saved-locations/use/$id',
        method: 'POST',
      );
    } catch (e) {
      print('Error incrementing use count: $e');
      rethrow;
    }
  }

  // Toggle favorite status
  static Future<Map<String, dynamic>> toggleFavorite(String id) async {
    try {
      return await ApiService.authenticatedApiCall(
        'saved-locations/favorite/$id',
        method: 'POST',
      );
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }

  // Delete saved location
  static Future<Map<String, dynamic>> deleteSavedLocation(String id) async {
    try {
      return await ApiService.authenticatedApiCall(
        'saved-locations/delete/$id',
        method: 'DELETE',
      );
    } catch (e) {
      print('Error deleting saved location: $e');
      rethrow;
    }
  }

}

