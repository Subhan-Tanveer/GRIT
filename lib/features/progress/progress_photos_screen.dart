import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/progress_photo.dart';
import '../../providers/progress_photo_provider.dart';
import '../../shared/widgets/grit_skeleton.dart';
import '../../shared/widgets/photo_comparison_slider.dart';

class ProgressPhotosScreen extends ConsumerStatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  ConsumerState<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends ConsumerState<ProgressPhotosScreen> {
  PhotoCategory _selectedCategory = PhotoCategory.front;
  bool _compareMode = false;
  ProgressPhoto? _comparePhotoA;
  ProgressPhoto? _comparePhotoB;

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final photosAsync = ref.watch(progressPhotosByCategoryProvider(_selectedCategory));

    return Scaffold(
      backgroundColor: grit.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: grit.border, width: 1))),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: grit.textPrimary),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Text('PROGRESS PHOTOS', style: GritTextStyles.headlineSmall().copyWith(color: grit.textPrimary)),
                const Spacer(),
                IconButton(
                  icon: Icon(_compareMode ? Icons.close : Icons.compare_arrows, color: grit.accent),
                  onPressed: () => setState(() {
                    _compareMode = !_compareMode;
                    _comparePhotoA = null;
                    _comparePhotoB = null;
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _categoryTabs(context),
          if (_compareMode) _compareHint(context),
          Expanded(
            child: photosAsync.when(
              loading: () => const Center(child: GritSkeleton(height: 100, width: 100)),
              error: (e, st) => Center(
                child: Text('Failed to load photos', style: GritTextStyles.label(13, color: grit.textSecondary)),
              ),
              data: (photos) {
                if (_compareMode && _comparePhotoA != null && _comparePhotoB != null) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: PhotoComparisonSlider(
                      beforePath: _comparePhotoA!.filePath,
                      afterPath: _comparePhotoB!.filePath,
                      beforeLabel: _comparePhotoA!.date,
                      afterLabel: _comparePhotoB!.date,
                    ),
                  );
                }
                if (photos.isEmpty) {
                  return Center(
                    child: Text('No ${_selectedCategory.label.toLowerCase()} photos yet.',
                        style: GritTextStyles.label(13, color: grit.muted)),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(GritSpacing.horizontalMargin),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) => _photoTile(context, photos[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _compareMode
          ? null
          : FloatingActionButton(
              backgroundColor: grit.accent,
              onPressed: () async {
                GritHaptics.mediumImpact();
                await ref.read(progressPhotoActionsProvider).capturePhoto(_selectedCategory);
              },
              child: const Icon(Icons.camera_alt, color: Colors.white),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _categoryTabs(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Padding(
      padding: const EdgeInsets.fromLTRB(GritSpacing.horizontalMargin, 16, GritSpacing.horizontalMargin, 8),
      child: Row(
        children: PhotoCategory.values.map((category) {
          final isSelected = category == _selectedCategory;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedCategory = category;
                _comparePhotoA = null;
                _comparePhotoB = null;
              }),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? grit.accent : Colors.transparent,
                  border: Border.all(color: isSelected ? grit.accent : grit.border),
                ),
                child: Text(
                  category.label,
                  style: GritTextStyles.label(12, weight: FontWeight.w700,
                      color: isSelected ? Colors.white : grit.textSecondary),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _compareHint(BuildContext context) {
    final grit = Theme.of(context).grit;
    final remaining = _comparePhotoA == null ? 'Tap a photo to use as BEFORE' : 'Tap another photo to use as AFTER';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 4),
      child: Text(remaining, style: GritTextStyles.label(12, color: grit.accent)),
    );
  }

  Widget _photoTile(BuildContext context, ProgressPhoto photo) {
    final grit = Theme.of(context).grit;
    final isPickedA = _comparePhotoA?.id == photo.id;
    final isPickedB = _comparePhotoB?.id == photo.id;

    return GestureDetector(
      onTap: () {
        if (_compareMode) {
          GritHaptics.selectionTick();
          setState(() {
            if (_comparePhotoA == null) {
              _comparePhotoA = photo;
            } else if (_comparePhotoB == null && photo.id != _comparePhotoA!.id) {
              _comparePhotoB = photo;
            } else {
              _comparePhotoA = photo;
              _comparePhotoB = null;
            }
          });
        } else {
          _showFullPhoto(context, photo);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isPickedA || isPickedB ? grit.accent : grit.border,
                width: isPickedA || isPickedB ? 2 : 1,
              ),
              image: DecorationImage(image: FileImage(File(photo.filePath)), fit: BoxFit.cover),
            ),
          ),
          Positioned(
            bottom: 2,
            left: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              color: Colors.black54,
              child: Text(photo.date, style: GritTextStyles.label(8, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullPhoto(BuildContext context, ProgressPhoto photo) {
    final grit = Theme.of(context).grit;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: grit.background,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(photo.filePath)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(photo.date, style: GritTextStyles.label(13, color: grit.textPrimary)),
                  GestureDetector(
                    onTap: () async {
                      await ref.read(progressPhotoActionsProvider).deletePhoto(photo);
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    },
                    child: Icon(Icons.delete_outline, color: grit.failureSet),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
