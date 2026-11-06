import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/cloudinary_config.dart';

class StorageService {
  StorageService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const maxBytes = 5 * 1024 * 1024;
  static const _timeout = Duration(seconds: 30);

  Future<String> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required int index,
    required Uint8List bytes,
  }) async {
    if (bytes.lengthInBytes > maxBytes) {
      throw ArgumentError('Each photo must be under 5 MB.');
    }
    if (!CloudinaryConfig.isConfigured) {
      throw StateError('Photo upload isn\'t set up yet. Submit without a photo for now.');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = 'mend/incidents/$uid/$incidentId'
      ..fields['public_id'] = 'photo_$index'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'photo_$index.jpg'));

    try {
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw StateError('The photo was rejected. Try a smaller photo.');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final url = body['secure_url'] as String?;
      if (url == null || url.isEmpty) {
        throw StateError('Photo upload failed. Please try again.');
      }
      return url;
    } on StateError {
      rethrow;
    } catch (_) {
      // Timeouts, no connection, malformed response.
      throw StateError('Couldn\'t upload the photo. Check your connection and try again.');
    }
  }

  Future<void> deletePhotos(List<String> urls) async {}
}