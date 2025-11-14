import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vehiclereservation_frontend_flutter_/models/user_model.dart';
import 'package:vehiclereservation_frontend_flutter_/services/secure_storage_service.dart';
import 'package:vehiclereservation_frontend_flutter_/services/storage_service.dart';

class ApiService {
  static const String baseUrl = "http://localhost:3000/api/v1";

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
    
    await StorageService.saveUserData(userData: user);

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
      {required String phone, required String displayName, String? role}) async {
    
    // Check if passwords match
    if (password != confirmPassword) {
      throw Exception('Passwords do not match');
    }

    final Map<String, dynamic> body = {
      'username': username,
      'password': password,
      'phone': phone,
      'displayname': displayName, // Made required
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
      await StorageService.saveUserData(userData: responseData['data']['user']);
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

}

