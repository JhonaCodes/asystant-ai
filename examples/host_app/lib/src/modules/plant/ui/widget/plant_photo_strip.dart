import 'package:flutter/material.dart';

import 'package:host_app/src/modules/plant/model/plant_media.dart';
import 'package:host_app/src/shared/shared.dart';

/// The plant's photos side by side; tap one to see it large with its credit.
class PlantPhotoStrip extends StatelessWidget {
  const PlantPhotoStrip({super.key, required this.photos});

  final List<PlantPhoto> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return BotanicaCard(child: Text(PlantStrings.noPhoto));
    }
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) => _PhotoTile(photo: photos[index]),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo});

  final PlantPhoto photo;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => PhotoViewerDialog.show(
      context,
      ref: photo.ref,
      credit: photo.hasCredit
          ? CommonStrings.photoCredit(photo.author, photo.license)
          : '',
    ),
    child: AspectRatio(
      aspectRatio: 4 / 3,
      child: BotanicaPhoto(ref: photo.ref),
    ),
  );
}
