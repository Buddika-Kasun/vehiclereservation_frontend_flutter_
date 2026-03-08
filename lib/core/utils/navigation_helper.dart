// lib/core/utils/navigation_helper.dart
import 'package:vehiclereservation_frontend_flutter_/core/services/navigation_service.dart';
import 'package:vehiclereservation_frontend_flutter_/data/models/user_model.dart';

class NavigationHelper {
  static final NavigationService _nav = NavigationService();

  // Quick access methods
  static void toUserCreations(String filter) {
    _nav.toUserCreations(filter);
  }

  static void toTripDetails(int tripId) {
    _nav.toTripDetails(tripId);
  }

  static void toMyRideTripDetails(int tripId) {
    _nav.toMyRideTripDetails(tripId);
  }

  static void toReviewTripDetails(int tripId) {
    _nav.toReviewTripDetails(tripId);
  }

  static void toApprovalTripDetails(int tripId) {
    _nav.toApprovalTripDetails(tripId);
  }

  static void toAssignRideTripDetails(int tripId) {
    _nav.toAssignRideTripDetails(tripId);
  }

  static void toMeterReading() {
    _nav.toMeterReading();
  }

  static void toAllTrips(UserRole userRole) {
    _nav.toAllTrips(userRole);
  }

  static void toNotifications() {
    _nav.toNotifications();
  }

  static void toDashboard() {
    _nav.toDashboard();
  }

  static void toLogin() {
    _nav.navigateToLogin();
  }

  static void back<T>([T? result]) {
    _nav.goBack<T>(result);
  }

  static bool get canGoBack => _nav.canPop();

  static Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return _nav.navigateTo<T>(routeName, arguments: arguments);
  }

  static Future<T?> navigateToHomeWithScreen<T>({
    required String screenName,
    Map<String, dynamic>? screenData,
  }) {
    return _nav.navigateToHomeWithScreen<T>(
      screenName: screenName,
      screenData: screenData,
    );
  }
}
