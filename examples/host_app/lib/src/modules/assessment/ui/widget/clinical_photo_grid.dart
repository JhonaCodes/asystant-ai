import 'package:flutter/material.dart';

import 'package:host_app/src/modules/assessment/model/clinical_photo.dart';
import 'package:host_app/src/shared/shared.dart';

/// The assessment's photos; tap to enlarge, long-press to remove.
class ClinicalPhotoGrid extends StatelessWidget {
  const ClinicalPhotoGrid({
    super.key,
    required this.photos,
    required this.onRemove,
  });

  final List<ClinicalPhoto> photos;

  final ValueChanged<ClinicalPhoto> onRemove;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (final photo in photos) _PhotoTile(photo: photo, onRemove: onRemove),
    ],
  );
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.onRemove});

  final ClinicalPhoto photo;

  final ValueChanged<ClinicalPhoto> onRemove;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      GestureDetector(
        onTap: () => PhotoViewerDialog.show(
          context,
          ref: photo.ref,
          credit: photo.caption,
        ),
        child: BotanicaPhoto(ref: photo.ref, size: 110),
      ),
      TextButton(
        onPressed: () => onRemove(photo),
        child: const Text(AssessmentStrings.removePhoto),
      ),
    ],
  );
}
