import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Simple drag selection manager for calendar date selection
/// Handles press -> drag -> release flow
class DragSelectionManager extends ChangeNotifier {
  DateTime? _startDate;
  DateTime? _currentDate;
  bool _isActive = false;

  // Current pointer position during drag (for cells to check)
  Offset? _currentPointerPosition;

  // Throttle pointer updates to avoid excessive rebuilds
  DateTime? _lastUpdateTime;
  static const _updateThrottleMs = 16; // ~60fps

  bool get isActive => _isActive;
  DateTime? get startDate => _startDate;
  DateTime? get currentDate => _currentDate;
  Offset? get currentPointerPosition => _currentPointerPosition;

  /// Get all selected dates in the range
  Set<DateTime> getSelectedDates() {
    if (_startDate == null || _currentDate == null) {
      return {};
    }

    // Determine min and max dates
    final start = _startDate!.isBefore(_currentDate!) ? _startDate! : _currentDate!;
    final end = _startDate!.isBefore(_currentDate!) ? _currentDate! : _startDate!;

    // Build set of all dates in range
    final selected = <DateTime>{};
    DateTime current = DateTime(start.year, start.month, start.day);
    final endNormalized = DateTime(end.year, end.month, end.day);

    while (current.isBefore(endNormalized) || current.isAtSameMomentAs(endNormalized)) {
      selected.add(current);
      current = current.add(const Duration(days: 1));
    }

    return selected;
  }

  /// Start drag selection
  void startDrag(DateTime date) {
    HapticFeedback.mediumImpact();

    _startDate = DateTime(date.year, date.month, date.day);
    _currentDate = DateTime(date.year, date.month, date.day);
    _isActive = true;

    notifyListeners();
  }

  /// Update pointer position during drag (cells will check if they're under it)
  void updatePointerPosition(Offset position) {
    if (!_isActive) return;

    // Throttle updates to avoid excessive rebuilds
    final now = DateTime.now();
    if (_lastUpdateTime != null) {
      final timeSinceLastUpdate = now.difference(_lastUpdateTime!).inMilliseconds;
      if (timeSinceLastUpdate < _updateThrottleMs) {
        // Still update position for the next check, but don't notify yet
        _currentPointerPosition = position;
        return;
      }
    }

    _lastUpdateTime = now;
    _currentPointerPosition = position;
    notifyListeners();
  }

  /// Update current date during drag
  void updateDrag(DateTime date) {
    if (!_isActive) return;

    final normalized = DateTime(date.year, date.month, date.day);

    // Only update if date actually changed
    if (_currentDate?.day != normalized.day ||
        _currentDate?.month != normalized.month ||
        _currentDate?.year != normalized.year) {

      HapticFeedback.selectionClick();

      _currentDate = normalized;
      notifyListeners();
    }
  }

  /// End drag selection and return the date range
  Map<String, DateTime>? endDrag() {
    if (!_isActive || _startDate == null || _currentDate == null) {
      _reset();
      return null;
    }

    final start = _startDate!.isBefore(_currentDate!) ? _startDate! : _currentDate!;
    final end = _startDate!.isBefore(_currentDate!) ? _currentDate! : _startDate!;

    final result = {'start': start, 'end': end};
    _reset();

    return result;
  }

  /// Cancel drag selection
  void cancelDrag() {
    _reset();
  }

  void _reset() {
    _startDate = null;
    _currentDate = null;
    _isActive = false;
    _currentPointerPosition = null;
    notifyListeners();
  }

  /// Check if a specific date is selected
  bool isDateSelected(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return getSelectedDates().contains(normalized);
  }
}
