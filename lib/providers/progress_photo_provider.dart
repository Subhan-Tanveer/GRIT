import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dao_providers.dart';
import '../data/models/progress_photo.dart';

final progressPhotosByCategoryProvider =
    FutureProvider.family.autoDispose<List<ProgressPhoto>, PhotoCategory>((ref, category) async {
  final dao = ref.watch(progressPhotoDaoProvider);
  return dao.getByCategory(category);
});

class ProgressPhotoActions {
  final Ref ref;
  ProgressPhotoActions(this.ref);

  Future<void> capturePhoto(PhotoCategory category) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (image == null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'progress_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final fileName = '${category.dbValue}_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
    final savedPath = p.join(photosDir.path, fileName);
    await File(image.path).copy(savedPath);

    final dao = ref.read(progressPhotoDaoProvider);
    await dao.insert(ProgressPhoto(
      date: DateTime.now().toIso8601String().split('T')[0],
      category: category,
      filePath: savedPath,
    ));

    ref.invalidate(progressPhotosByCategoryProvider(category));
  }

  Future<void> deletePhoto(ProgressPhoto photo) async {
    final dao = ref.read(progressPhotoDaoProvider);
    await dao.delete(photo.id!);
    final file = File(photo.filePath);
    if (await file.exists()) {
      await file.delete();
    }
    ref.invalidate(progressPhotosByCategoryProvider(photo.category));
  }
}

final progressPhotoActionsProvider = Provider((ref) => ProgressPhotoActions(ref));
