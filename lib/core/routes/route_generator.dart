// lib/core/routes/route_generator.dart
import 'package:flutter/material.dart';
import 'package:vehiclereservation_frontend_flutter_/features/home/home_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/screens/all_trips_(Users)/all_trips_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/screens/approval_(Approvers)/approval_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/screens/assigned_(Drivers)/assigned_ride_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/screens/exceed_trips_(Sysadmin)/exceed_trip_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/screens/review_(Supervisors)/review_trip_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/screens/reading_(Security)/meter_reading_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/trips/screens/ride_(Users)/ride_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/admin/vehicle_management/checklist/check_list_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/users/admin/vehicle_management/checklist/checklist_details_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/welcome/welcome_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/auth/screens/login_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/features/app_updates/admin_login_screen.dart';
import 'package:vehiclereservation_frontend_flutter_/core/routes/app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.splash:
      case AppRoutes.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.adminLogin:
        return MaterialPageRoute(builder: (_) => const AdminLoginScreen());

      case AppRoutes.home:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => HomeScreen(
              screenName: args['screenName'],
              screenData: args['screenData'],
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case AppRoutes.myRideTripDetails:
        if (args is Map<String, dynamic> && args['tripId'] != null) {
          return MaterialPageRoute(
            builder: (_) => TripDetailsScreen(
              tripId: args['tripId'],
            ),
          );
        }
        return _errorRoute('Trip ID is required for My Ride Trip Details');

      case AppRoutes.reviewTripDetails:
        if (args is Map<String, dynamic> && args['tripId'] != null) {
          return MaterialPageRoute(
            builder: (_) => ReviewTripDetailsScreen(tripId: args['tripId']),
          );
        }
        return _errorRoute('Trip ID is required for Review Trip Details');

      case AppRoutes.approvalTripDetails:
        if (args is Map<String, dynamic> && args['tripId'] != null) {
          return MaterialPageRoute(
            builder: (_) => ApprovalDetailsScreen(tripId: args['tripId']),
          );
        }
        return _errorRoute('Trip ID is required for Approval Trip Details');

      case AppRoutes.assignRideTripDetails:
        if (args is Map<String, dynamic> && args['tripId'] != null) {
          return MaterialPageRoute(
            builder: (_) => RideDetailsScreen(tripId: args['tripId']),
          );
        }
        return _errorRoute('Trip ID is required for Assign Ride Trip Details');

      case AppRoutes.exceededTripDetails:
        if (args is Map<String, dynamic> && args['tripId'] != null) {
          return MaterialPageRoute(
            builder: (_) => ExceedTripDetailsScreen(
              tripId: args['tripId'],
              userRole: args['userRole'],
            ),
          );
        }
        return _errorRoute('Trip ID is required for Exceeded Trip Details');

      case AppRoutes.reviewChecklistDetails:
        if (args is Map<String, dynamic> && args['checklistId'] != null) {
          return MaterialPageRoute(
            builder: (_) => ChecklistDetailsScreen(
              checklistId: args['checklistId'].toString(),
              hasActions: true,
            ),
          );
        }
        return _errorRoute('Checklist ID is required for Review Checklist Details');
      
      case AppRoutes.checklistDetails:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => ChecklistScreen(
              vehicleId: args['vehicleId'].toString(),
              vehicleRegNo: args['vehicleRegNo'],
              userId: args['userId'].toString(),
              userName: args['userName'],
              userRole: args['userRole'],
            ),
          );
        }
        return _errorRoute('Checklist data is required for Checklist Details'); 

      case AppRoutes.meterReading:
        return MaterialPageRoute(
          builder: (_) => const RidesApprovalScreen(),
        );

      default:
        // Check if it's an internal route
        if (AppRoutes.isInternalRoute(settings.name!)) {
          // Redirect internal routes to home with the correct screen
          final screenName = RouteHelper.getHomeScreenNameFromRoute(
            settings.name!,
          );
          return MaterialPageRoute(
            builder: (_) => HomeScreen(
              screenName: screenName,
              screenData: args is Map<String, dynamic> ? args : null,
            ),
          );
        }

        // Handle unknown routes
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(message)),
      ),
    );
  }
}
