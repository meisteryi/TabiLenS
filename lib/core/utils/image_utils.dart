import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  /// Fixes orientation and resizes image if the platform is not Web.
  /// If it is Web, it returns the original file.
  static Future<XFile> fixImageRotationAndResize(XFile pickedFile) async {
    if (kIsWeb) {
      return pickedFile;
    }

    try {
      final file = File(pickedFile.path);
      if (!await file.exists()) {
        return pickedFile;
      }

      final bytes = await file.readAsBytes();
      final img.Image? originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        return pickedFile;
      }

      // 1. Bake EXIF orientation info physically into the pixels
      final img.Image orientedImage = img.bakeOrientation(originalImage);

      // 2. Resize maintaining aspect ratio (max dimension 1200)
      img.Image resizedImage = orientedImage;
      const int maxDimension = 1200;
      if (orientedImage.width > maxDimension || orientedImage.height > maxDimension) {
        if (orientedImage.width > orientedImage.height) {
          resizedImage = img.copyResize(orientedImage, width: maxDimension);
        } else {
          resizedImage = img.copyResize(orientedImage, height: maxDimension);
        }
      }

      // 3. Save as JPEG with 80% quality to reduce size
      final fixedBytes = img.encodeJpg(resizedImage, quality: 80);

      // Save to a new temporary file to prevent caching issues
      final String dirPath = pickedFile.path.substring(0, pickedFile.path.lastIndexOf(Platform.pathSeparator));
      final String newPath = '$dirPath/fixed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final newFile = File(newPath);
      await newFile.writeAsBytes(fixedBytes);

      // Try to delete the old temporary file picked by image_picker to save space
      try {
        await file.delete();
      } catch (_) {
        // Safe to ignore if we cannot delete
      }

      return XFile(newPath);
    } catch (e) {
      debugPrint('[ImageUtils] Error fixing image rotation: $e');
      return pickedFile;
    }
  }
}
