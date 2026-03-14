// lib/core/services/navigation_service.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/core/utils/auth_manager.dart';
import 'package:vehiclereservation_frontend_flutter_/core/routes/app_routes.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';
class NavigationService {
  // Use the same navigatorKey from AuthManager
  GlobalKey<NavigatorState> get navigatorKey => AuthManager.navigatorKey;

  BuildContext? get currentContext => navigatorKey.currentContext;

  // Navigate to HomeScreen with a specific internal screen
  Future<T?> navigateToHomeWithScreen<T>({
    required String screenName,
    Map<String, dynamic>? screenData,
  }) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      AppRoutes.home,
      (route) => false,
      arguments: {'screenName': screenName, 'screenData': screenData},
    );
  }

  // Direct route navigation
  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  // Navigate and replace current route
  Future<T?> pushReplacementNamed<T, TO>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushReplacementNamed<T, TO>(
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  // Navigate and remove all previous routes
  Future<T?> pushNamedAndRemoveUntil<T>(
    String newRouteName,
    bool Function(Route<dynamic>) predicate, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      newRouteName,
      predicate,
      arguments: arguments,
    );
  }

  // Go back
  void goBack<T>([T? result]) {
    if (navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop<T>(result);
    }
  }

  // Check if can pop
  bool canPop() {
    return navigatorKey.currentState!.canPop();
  }

  // Helper methods for common navigation
  Future<T?> navigateToTripDetails<T>({
    required int tripId,
    bool fromConflictNavigation = false,
    bool fromInstanceNavigation = false,
  }) {
    return navigateToHomeWithScreen<T>(
      screenName: 'trip_details',
      screenData: {
        'tripId': tripId,
        'fromConflictNavigation': fromConflictNavigation,
        'fromInstanceNavigation': fromInstanceNavigation,
      },
    );
  }

  Future<T?> navigateToNotifications<T>() {
    return navigateToHomeWithScreen<T>(screenName: 'notifications');
  }

  Future<T?> navigateToDashboard<T>() {
    return navigateToHomeWithScreen<T>(screenName: 'dashboard');
  }

  Future<T?> navigateToLogin<T>() {
    return pushNamedAndRemoveUntil<T>(AppRoutes.login, (route) => false);
  }

  // Simple void methods for notification navigation
  void toUserCreations(String filter) {
    navigateToHomeWithScreen(
      screenName: 'user_creations',
      screenData: {'filter': filter}
    );
  }

  void toTripDetails(int tripId) {
    navigateToTripDetails(tripId: tripId);
  }

  void toMyRideTripDetails(int tripId) {
    navigateTo(
      AppRoutes.myRideTripDetails,
      arguments: {'tripId': tripId},
    );
  }

  void toReviewTripDetails(int tripId) {
    navigateTo(
      AppRoutes.reviewTripDetails, 
      arguments: {'tripId': tripId}
      );
  }

  void toApprovalTripDetails(int tripId) {
    navigateTo(
      AppRoutes.approvalTripDetails, 
      arguments: {'tripId': tripId}
      );
  }

  void toAssignRideTripDetails(int tripId) {
    navigateTo(
      AppRoutes.assignRideTripDetails, 
      arguments: {'tripId': tripId}
    );
  }

  void toMeterReading() {
    navigateToHomeWithScreen(
      screenName: 'meter_reading',
    );
  }

  void toAllTrips(UserRole userRole) {
    navigateToHomeWithScreen(
      screenName: 'all_trips',
      screenData: {'userRole': userRole}
    );
  }

  void toNotifications() {
    navigateToNotifications();
  }

  void toDashboard() {
    navigateToDashboard();
  }
}
