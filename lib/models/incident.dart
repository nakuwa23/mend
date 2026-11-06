import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_enums.dart';
import 'status_update.dart';

/// A campus incident report stored at `incidents/{id}`.
class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.building,
    required this.room,
    required this.urgency,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.nameHidden,
    required this.photoUrls,
    required this.affectedUids,
    required this.history,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String building;
  final String room;
  final Urgency urgency;
  final IncidentStatus status;
  final String reporterId;

  /// Already anonymised at write time when [nameHidden] is true,
  /// so other students never receive the real name.
  final String reporterName;
  final bool nameHidden;
  final List<String> photoUrls;

  /// Students who tapped "Me too" (the reporter is included).
  final List<String> affectedUids;
  final List<StatusUpdate> history;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const anonymousName = 'Anonymous student';
  static const overdueAfter = Duration(hours: 48);

  String get location => room.isEmpty ? building : '$building · $room';
  int get affectedCount => affectedUids.isEmpty ? 1 : affectedUids.length;
  bool isAffected(String uid) => affectedUids.contains(uid);

  bool isOverdue([DateTime? now]) =>
      status.isOpen && (now ?? DateTime.now()).difference(createdAt) > overdueAfter;

  /// Staff queue ordering: urgency, then how many people are affected, then age.
  int get priorityScore {
    final ageHours = DateTime.now().difference(createdAt).inHours;
    return urgency.weight * 100 + affectedCount * 5 + (isOverdue() ? 200 : 0) + ageHours.clamp(0, 99);
  }

  factory Incident.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    DateTime readTime(Object? v) => v is Timestamp ? v.toDate() : DateTime.now();

    return Incident(
      id: doc.id,
      title: (d['title'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      category: IncidentCategory.fromName(d['category'] as String?),
      building: (d['building'] as String?) ?? '',
      room: (d['room'] as String?) ?? '',
      urgency: Urgency.fromName(d['urgency'] as String?),
      status: IncidentStatus.fromName(d['status'] as String?),
      reporterId: (d['reporterId'] as String?) ?? '',
      reporterName: (d['reporterName'] as String?) ?? anonymousName,
      nameHidden: (d['nameHidden'] as bool?) ?? false,
      photoUrls: List<String>.from((d['photoUrls'] as List?) ?? const []),
      affectedUids: List<String>.from((d['affectedUids'] as List?) ?? const []),
      history: ((d['history'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => StatusUpdate.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      createdAt: readTime(d['createdAt']),
      updatedAt: readTime(d['updatedAt']),
    );
  }

  /// Data for a brand-new report. Status always starts as `submitted`.
  static Map<String, dynamic> newReportMap({
    required String title,
    required String description,
    required IncidentCategory category,
    required String building,
    required String room,
    required Urgency urgency,
    required String reporterId,
    required String reporterName,
    required bool hideName,
    required List<String> photoUrls,
  }) {
    final shownName = hideName ? anonymousName : reporterName;
    return {
      'title': title.trim(),
      'description': description.trim(),
      'category': category.name,
      'building': building,
      'room': room.trim(),
      'urgency': urgency.name,
      'status': IncidentStatus.submitted.name,
      'reporterId': reporterId,
      'reporterName': shownName,
      'nameHidden': hideName,
      'photoUrls': photoUrls,
      'affectedUids': [reporterId],
      'history': [
        StatusUpdate(
          status: IncidentStatus.submitted,
          note: 'Report submitted',
          byName: shownName,
          at: DateTime.now(),
        ).toMap(),
      ],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}