// data/models/dashboard_stats_model.dart

class DashboardStats {
  final int totalRides;
  final int pendingSupervisorRides;
  final int totalUsers;
  final int ridesToday;
  final int pendingUserCreations;
  final double budgetAmount;
  final double actualCost;
  final double costVariance;
  final double costVariancePercent;
  final double currentMonthCost;
  final double? previousMonthCost; // Make nullable
  final double monthOverMonthChange;
  final double monthOverMonthPercent;

  DashboardStats({
    required this.totalRides,
    required this.pendingSupervisorRides,
    required this.totalUsers,
    required this.ridesToday,
    required this.pendingUserCreations,
    required this.budgetAmount,
    required this.actualCost,
    required this.costVariance,
    required this.costVariancePercent,
    required this.currentMonthCost,
    this.previousMonthCost,
    required this.monthOverMonthChange,
    required this.monthOverMonthPercent,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    // Calculate values if not provided by API
    final double previousMonthCost =
        json['previousMonthCost']?.toDouble() ?? 0.0;
    final double currentMonthCost = json['currentMonthCost']?.toDouble() ?? 0.0;
    final double monthOverMonthChange =
        json['monthOverMonthChange']?.toDouble() ??
        (currentMonthCost - previousMonthCost);

    final double monthOverMonthPercent =
        json['monthOverMonthPercent']?.toDouble() ??
        (previousMonthCost > 0
            ? ((monthOverMonthChange / previousMonthCost) * 100)
            : (currentMonthCost > 0 ? 100.0 : 0.0));

    final double budgetAmount = json['budgetAmount']?.toDouble() ?? 0.0;
    final double actualCost = json['actualCost']?.toDouble() ?? 0.0;
    final double costVariance =
        json['costVariance']?.toDouble() ?? (budgetAmount - actualCost);
    final double costVariancePercent =
        json['costVariancePercent']?.toDouble() ??
        (budgetAmount > 0 ? ((costVariance / budgetAmount) * 100) : 0.0);

    return DashboardStats(
      totalRides: json['totalRides']?.toInt() ?? 0,
      pendingSupervisorRides: json['pendingSupervisorRides']?.toInt() ?? 0,
      totalUsers: json['totalUsers']?.toInt() ?? 0,
      ridesToday: json['ridesToday']?.toInt() ?? 0,
      pendingUserCreations: json['pendingUserCreations']?.toInt() ?? 0,
      budgetAmount: budgetAmount,
      actualCost: actualCost,
      costVariance: costVariance,
      costVariancePercent: costVariancePercent,
      currentMonthCost: currentMonthCost,
      previousMonthCost: previousMonthCost,
      monthOverMonthChange: monthOverMonthChange,
      monthOverMonthPercent: monthOverMonthPercent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRides': totalRides,
      'pendingSupervisorRides': pendingSupervisorRides,
      'totalUsers': totalUsers,
      'ridesToday': ridesToday,
      'pendingUserCreations': pendingUserCreations,
      'budgetAmount': budgetAmount,
      'actualCost': actualCost,
      'costVariance': costVariance,
      'costVariancePercent': costVariancePercent,
      'currentMonthCost': currentMonthCost,
      'previousMonthCost': previousMonthCost,
      'monthOverMonthChange': monthOverMonthChange,
      'monthOverMonthPercent': monthOverMonthPercent,
    };
  }
}
