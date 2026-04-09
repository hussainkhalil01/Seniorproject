import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime_type/mime_type.dart';

Future<String?> uploadData(String path, Uint8List data) async {
  final storageRef = FirebaseStorage.instance.ref().child(path);
  // mime() does not recognise .m4a; fall back to audio/mp4 for audio files.
  String? contentType = mime(path);
  if (contentType == null) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'm4a' || ext == 'aac' || ext == 'mp3' || ext == 'wav' || ext == 'ogg') {
      contentType = ext == 'm4a' || ext == 'aac' ? 'audio/mp4' : 'audio/$ext';
    }
  }
  final metadata = SettableMetadata(contentType: contentType);
  final result = await storageRef.putData(data, metadata);
  return result.state == TaskState.success ? result.ref.getDownloadURL() : null;
}
