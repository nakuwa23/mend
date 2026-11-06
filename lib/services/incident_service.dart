import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/incident_enums.dart';
import '../models/status_update.dart';
import 'storage_service.dart';

/// Data layer for the `incidents` collection (create, read, update, delete).
class IncidentService {
  IncidentService({FirebaseFirestore? db, StorageService? storage})
      : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? StorageService();

  final FirebaseFirestore _db;
  final StorageService _storage;

  static const feedLimit = 200;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('incidents');

  Stream<List<Incident>> watchAll() => _col
      .orderBy('createdAt', descending: true)
      .limit(feedLimit)
      .snapshots()
      .map((snap) => snap.docs.map(Incident.fromDoc).toList());

  Stream<Incident?> watchOne(String id) =>
      _col.doc(id).snapshots().map((doc) => doc.exists ? Incident.fromDoc(doc) : null);

  Future<String> create({
    required AppUser reporter,
    required String title,
    required String description,
    required IncidentCategory category,
    required String building,
    required String room,
    required Urgency urgency,
    required bool hideName,
    required List<Uint8List> photos,
  }) async {
    final ref = _col.doc();
    final urls = <String>[];
    for (var i = 0; i < photos.length; i++) {
      urls.add(await _storage.uploadIncidentPhoto(
        uid: reporter.uid,
        incidentId: ref.id,
        index: i,
        bytes: photos[i],
      ));
    }
    await ref.set(Incident.newReportMap(
      title: title,
      description: description,
      category: category,
      building: building,
      room: room,
      urgency: urgency,
      reporterId: reporter.uid,
      reporterName: reporter.name,
      hideName: hideName,
      photoUrls: urls,
    ));
    return ref.id;
  }

  Future<void> updateStatus({
    required String incidentId,
    required IncidentStatus status,
    required String note,
    required AppUser staff,
  }) {
    final entry = StatusUpdate(status: status, note: note.trim(), byName: staff.name, at: DateTime.now());
    return _col.doc(incidentId).update({
      'status': status.name,
      'history': FieldValue.arrayUnion([entry.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setAffected({required String incidentId, required String uid, required bool affected}) {
    return _col.doc(incidentId).update({
      'affectedUids': affected ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
    });
  }

  Future<void> delete(Incident incident) async {
    await _col.doc(incident.id).delete();
    await _storage.deletePhotos(incident.photoUrls);
  }
}