// lib/features/trips/utils/sort_enums.dart
import 'package:flutter/material.dart';

enum SortField { id, startTime }

enum SortOrder { asc, desc }

extension SortFieldExtension on SortField {
  String get displayName {
    switch (this) {
      case SortField.id:
        return 'ID';
      case SortField.startTime:
        return 'Time';
    }
  }

  IconData get icon {
    switch (this) {
      case SortField.id:
        return Icons.numbers;
      case SortField.startTime:
        return Icons.access_time;
    }
  }
}

extension SortOrderExtension on SortOrder {
  String get displayName {
    switch (this) {
      case SortOrder.asc:
        return 'Ascending';
      case SortOrder.desc:
        return 'Descending';
    }
  }

  IconData get icon {
    switch (this) {
      case SortOrder.asc:
        return Icons.arrow_upward;
      case SortOrder.desc:
        return Icons.arrow_downward;
    }
  }
}
