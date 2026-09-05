import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';

class PhotoUploadService {
  final ImagePicker _picker = ImagePicker();

  /// Captures a live photograph using the device camera
  Future<XFile?> captureFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
    } catch (_) {
      return null;
    }
  }

  /// Selects an existing photo from the phone gallery
  Future<XFile?> pickFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
    } catch (_) {
      return null;
    }
  }

  /// Uploads picked photo to FastAPI backend storage
  Future<Map<String, dynamic>> uploadPhoto(XFile file) async {
    final bytes = await file.readAsBytes();
    final filename = file.name.isNotEmpty ? file.name : 'hazard_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await ApiClient.uploadImageBytes(bytes, filename);
  }

  /// Convenience static helper to pick from camera or gallery and upload
  static Future<String?> pickAndUploadImage(BuildContext? context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      final filename = file.name.isNotEmpty ? file.name : 'inspection_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final res = await ApiClient.uploadImageBytes(bytes, filename);
      if (res['success'] == true) {
        return res['image_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

