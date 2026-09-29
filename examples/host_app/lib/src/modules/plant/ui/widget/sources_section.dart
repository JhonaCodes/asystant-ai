import 'package:flutter/material.dart';

import 'package:host_app/src/integrations/links/links.dart';
import 'package:host_app/src/modules/plant/model/plant_media.dart';

/// Where the plant's information comes from; each source opens its page.
class SourcesSection extends StatelessWidget {
  const SourcesSection({super.key, required this.sources});

  final List<PlantSource> sources;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final source in sources)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.menu_book_outlined),
          title: Text(source.title),
          subtitle: source.publisher.isEmpty ? null : Text(source.publisher),
          trailing: source.url.isEmpty ? null : const Icon(Icons.open_in_new),
          onTap: source.url.isEmpty
              ? null
              : () => ExternalLink.open(source.url),
        ),
    ],
  );
}
