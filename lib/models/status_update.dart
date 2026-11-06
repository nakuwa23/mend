import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_enums.dart';

/// One entry in an incident's status timeline.
/// Stored inside the incident's `history` array (server timestamps are not
/// allowed inside arrays, so [at] is a client Timestamp).
class StatusUpdate {
  const StatusUpdate({
    required this.status,
    required this.note,
    required this.byName,
    required this.at,
  });

  final IncidentStatus status;
  final String note;
  final String byName;
  final DateTime at;

  factory StatusUpdate.fromMap(Map<String, dynamic> m) => StatusUpdate(
        status: IncidentStatus.fromName(m['status'] as String?),
        note: (m['note'] as String?) ?? '',
        byName: (m['byName'] as String?) ?? '',
        at: m['at'] is Timestamp ? (m['at'] as Timestamp).toDate() : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'note': note,
        'byName': byName,
        'at': Timestamp.fromDate(at),
      };
}