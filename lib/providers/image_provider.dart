import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final imagePickerProvider = Provider<ImagePicker>((ref) {
  return ImagePicker();
});

class ImageNotifier extends Notifier<XFile?> {
  @override
  XFile? build() {
    return null;
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ref.read(imagePickerProvider);
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1600,
      );
      state = pickedFile;
    } catch (e) {
      state = null;
      rethrow;
    }
  }

  void clear() {
    state = null;
  }

  void setImage(XFile? file) {
    state = file;
  }
}

final imageProvider = NotifierProvider<ImageNotifier, XFile?>(() {
  return ImageNotifier();
});
