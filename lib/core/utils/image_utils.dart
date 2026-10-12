import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  /// Fixes orientation and resizes image on a background isolate using compute().
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

      // Process orientation and resizing on a background isolate to prevent UI thread freeze
      final Uint8List fixedBytes = await compute(_processOrientationAndResize, bytes);

      // Save to a new temporary file
      final String dirPath = pickedFile.path.substring(
        0,
        pickedFile.path.lastIndexOf(Platform.pathSeparator),
      );
      final String newPath = '$dirPath/fixed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final newFile = File(newPath);
      await newFile.writeAsBytes(fixedBytes);

      // Clean up the original picked file to save cache space
      try {
        await file.delete();
      } catch (_) {}

      return XFile(newPath);
    } catch (e) {
      debugPrint('[ImageUtils] Error fixing image rotation: $e');
      return pickedFile;
    }
  }

  /// Background isolate worker for orientation bake and resizing
  static Uint8List _processOrientationAndResize(Uint8List bytes) {
    final img.Image? originalImage = img.decodeImage(bytes);
    if (originalImage == null) return bytes;

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

    // 3. Save as JPEG with 80% quality to optimize memory and upload latency
    return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 80));
  }

  /// Crops the image based on normalized coordinates (0.0 to 1.0) on a background isolate
  static Future<Uint8List> cropNormalizedArea(
    XFile imageFile, {
    required double normXmin,
    required double normYmin,
    required double normXmax,
    required double normYmax,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return await compute(_processCrop, {
        'bytes': bytes,
        'normXmin': normXmin,
        'normYmin': normYmin,
        'normXmax': normXmax,
        'normYmax': normYmax,
      });
    } catch (e) {
      debugPrint('[ImageUtils] Error cropping normalized area: $e');
      return await imageFile.readAsBytes();
    }
  }

  /// Background isolate worker for cropping
  static Uint8List _processCrop(Map<String, dynamic> params) {
    final Uint8List bytes = params['bytes'] as Uint8List;
    final double normXmin = params['normXmin'] as double;
    final double normYmin = params['normYmin'] as double;
    final double normXmax = params['normXmax'] as double;
    final double normYmax = params['normYmax'] as double;

    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    final double left = normXmin < normXmax ? normXmin : normXmax;
    final double right = normXmin > normXmax ? normXmin : normXmax;
    final double top = normYmin < normYmax ? normYmin : normYmax;
    final double bottom = normYmin > normYmax ? normYmin : normYmax;

    // Add 1.5% margin so edge characters are not clipped
    const double margin = 0.015;
    final int x = ((left - margin).clamp(0.0, 1.0) * decoded.width).round();
    final int y = ((top - margin).clamp(0.0, 1.0) * decoded.height).round();
    final int x2 = ((right + margin).clamp(0.0, 1.0) * decoded.width).round();
    final int y2 = ((bottom + margin).clamp(0.0, 1.0) * decoded.height).round();

    final int w = (x2 - x).clamp(10, decoded.width - x);
    final int h = (y2 - y).clamp(10, decoded.height - y);

    final img.Image cropped = img.copyCrop(
      decoded,
      x: x,
      y: y,
      width: w,
      height: h,
    );

    return Uint8List.fromList(img.encodeJpg(cropped, quality: 90));
  }

  /// Permanently saves a temporary image to the app's persistent documents directory
  /// so it will not be deleted when the OS clears temporary cache.
  static Future<String> persistImageFile(String sourcePath) async {
    if (kIsWeb || sourcePath.isEmpty) return sourcePath;
    try {
      final file = File(sourcePath);
      if (!await file.exists()) return sourcePath;

      final appDir = await getApplicationDocumentsDirectory();
      final savedDir = Directory('${appDir.path}/saved_images');
      if (!await savedDir.exists()) {
        await savedDir.create(recursive: true);
      }
      final fileName = 'saved_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final permanentPath = '${savedDir.path}/$fileName';
      await file.copy(permanentPath);
      return permanentPath;
    } catch (e) {
      debugPrint('[ImageUtils] Error persisting image file: $e');
      return sourcePath;
    }
  }
}
