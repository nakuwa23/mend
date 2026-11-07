import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/firebase_errors.dart';
import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/incident_enums.dart';
import '../services/incident_service.dart';

enum ReportScope { mine, campus }

enum StaffTab { fresh, active, overdue }

class IncidentProvider extends ChangeNotifier {
  IncidentProvider(this._service);

  final IncidentService _service;
  StreamSubscription<List<Incident>>? _sub;
  AppUser? _user;

  List<Incident> _all = const [];
  bool _loading = false;
  bool _busy = false;
  String? _error;

  // Filters (browse screen)
  String _query = '';
  IncidentStatus? _statusFilter;
  IncidentCategory? _categoryFilter;
  ReportScope _scope = ReportScope.campus;

  // Staff queue
  StaffTab _staffTab = StaffTab.fresh;

  bool get loading => _loading;
  bool get busy => _busy;
  String? get error => _error;
  String get query => _query;
  IncidentStatus? get statusFilter => _statusFilter;
  IncidentCategory? get categoryFilter => _categoryFilter;
  ReportScope get scope => _scope;
  StaffTab get staffTab => _staffTab;
  List<Incident> get all => _all;

  void bindUser(AppUser? user) {
    if (user?.uid == _user?.uid) {
      _user = user; // role or name may have changed
      return;
    }
    _user = user;
    _sub?.cancel();
    _sub = null;
    _all = const [];
    Future.microtask(_safeNotify);
    if (user == null) return;
    _loading = true;
    _sub = _service.watchAll().listen(
      (items) {
        _all = items;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = friendlyError(e);
        notifyListeners();
      },
    );
  }

  Incident? byId(String id) {
    for (final i in _all) {
      if (i.id == id) return i;
    }
    return null;
  }

  // ---------- Derived data ----------

  List<Incident> get mine => _all.where((i) => i.reporterId == _user?.uid).toList();

  int mineCount(IncidentStatus status) => mine.where((i) => i.status == status).length;
  int get mineOpenCount => mine.where((i) => i.status.isOpen).length;

  Incident? get knownIssue {
    final open = _all.where((i) => i.status.isOpen && i.affectedCount >= 3).toList()
      ..sort((a, b) => b.affectedCount.compareTo(a.affectedCount));
    return open.isEmpty ? null : open.first;
  }

  Incident? get latestOfMine {
    final list = mine..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list.isEmpty ? null : list.first;
  }

  List<Incident> get _scoped => _scope == ReportScope.mine ? mine : _all;

  int scopedCount(IncidentStatus? status) =>
      status == null ? _scoped.length : _scoped.where((i) => i.status == status).length;

  List<Incident> get filtered {
    final q = _query.trim().toLowerCase();
    return _scoped.where((i) {
      if (_statusFilter != null && i.status != _statusFilter) return false;
      if (_categoryFilter != null && i.category != _categoryFilter) return false;
      if (q.isEmpty) return true;
      return i.title.toLowerCase().contains(q) ||
          i.location.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q);
    }).toList();
  }

  List<Incident> similarOpen(IncidentCategory category, String building) => _all
      .where((i) => i.status.isOpen && i.category == category && i.building == building)
      .toList();

  List<Incident> staffList(StaffTab tab) {
    final Iterable<Incident> matches = switch (tab) {
      StaffTab.fresh => _all.where((i) => i.status == IncidentStatus.submitted),
      StaffTab.active => _all.where((i) => i.status == IncidentStatus.inProgress),
      StaffTab.overdue => _all.where((i) => i.isOverdue()),
    };
    return matches.toList()..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
  }

  int staffCount(StaffTab tab) => staffList(tab).length;

  // ---------- Filter setters ----------

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setStatusFilter(IncidentStatus? value) {
    _statusFilter = value;
    notifyListeners();
  }

  void setCategoryFilter(IncidentCategory? value) {
    _categoryFilter = value;
    notifyListeners();
  }

  void setScope(ReportScope value) {
    _scope = value;
    notifyListeners();
  }

  void setStaffTab(StaffTab tab) {
    _staffTab = tab;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _statusFilter = null;
    _categoryFilter = null;
    notifyListeners();
  }

  // ---------- Actions ----------

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _error = friendlyError(e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> submit({
    required String title,
    required String description,
    required IncidentCategory category,
    required String building,
    required String room,
    required Urgency urgency,
    required bool hideName,
    required List<Uint8List> photos,
  }) {
    final user = _user;
    if (user == null) return Future.value(false);
    return _run(() => _service.create(
          reporter: user,
          title: title,
          description: description,
          category: category,
          building: building,
          room: room,
          urgency: urgency,
          hideName: hideName,
          photos: photos,
        ));
  }

  Future<bool> updateStatus(Incident incident, IncidentStatus status, String note) {
    final user = _user;
    if (user == null || !user.isStaff) {
      _error = 'Only Facilities staff can change a status.';
      notifyListeners();
      return Future.value(false);
    }
    return _run(() => _service.updateStatus(incidentId: incident.id, status: status, note: note, staff: user));
  }

  Future<bool> toggleAffected(Incident incident) {
    final user = _user;
    if (user == null) return Future.value(false);
    return _run(() => _service.setAffected(
          incidentId: incident.id,
          uid: user.uid,
          affected: !incident.isAffected(user.uid),
        ));
  }

  bool canDelete(Incident incident) {
    final user = _user;
    if (user == null) return false;
    if (user.isStaff) return true;
    return incident.reporterId == user.uid && incident.status == IncidentStatus.submitted;
  }

  Future<bool> delete(Incident incident) => _run(() => _service.delete(incident));

  void clearError() {
    _error = null;
    notifyListeners();
  }

  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}