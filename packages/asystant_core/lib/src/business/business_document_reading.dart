import 'package:asystant_core/src/business/business_document.dart';
import 'package:asystant_core/src/knowledge/asystant_knowledge.dart';
import 'package:asystant_core/src/knowledge/knowledge_document.dart';
import 'package:asystant_core/src/knowledge/knowledge_query.dart';

/// Consults a [BusinessDocument] by its Markdown sections.
extension BusinessDocumentReading on BusinessDocument {
  static final RegExp _heading = RegExp(r'^#{1,6}\s+\S');
  static final RegExp _headingMarks = RegExp(r'^#{1,6}\s+');

  /// The shortest cut kept when a section does not fit whole.
  static const int _minExcerpt = 200;

  /// The document split at its Markdown headings (outside code fences),
  /// each section titled by its heading; text before the first heading is
  /// titled [BusinessDocument.title].
  List<KnowledgeDocument> get sections {
    final sections = <KnowledgeDocument>[];
    var heading = title;
    var isInFence = false;
    final body = StringBuffer();
    void close() {
      final text = body.toString().trim();
      if (heading.isNotEmpty || text.isNotEmpty) {
        sections.add(
          KnowledgeDocument(
            id: '${sections.length}',
            title: heading,
            text: text,
          ),
        );
      }
      body.clear();
    }

    for (final line in this.text.split('\n')) {
      if (line.trimLeft().startsWith('```')) isInFence = !isInFence;
      if (!isInFence && _heading.hasMatch(line)) {
        close();
        heading = line.replaceFirst(_headingMarks, '').trim();
      } else {
        body.writeln(line);
      }
    }
    close();
    return sections;
  }

  /// The sections that match [query], best first, or every section in
  /// order when [query] is empty, cut to [maxCharacters] in total. Ranked
  /// lexically by `AsystantKnowledge`, so it needs no service.
  ({List<KnowledgeDocument> sections, bool isTruncated}) matchingSections(
    String query, {
    int maxCharacters = 8000,
  }) {
    final all = sections;
    final ranked = query.trim().isEmpty
        ? all
        : [
            for (final hit in AsystantKnowledge(documents: all).rank(
              KnowledgeQuery(text: query, limit: AsystantKnowledge.maxLimit),
            ))
              all[int.parse(hit.id)],
          ];
    final kept = <KnowledgeDocument>[];
    var remaining = maxCharacters;
    for (final section in ranked) {
      final size = section.title.length + section.text.length;
      if (size <= remaining) {
        kept.add(section);
        remaining -= size;
        continue;
      }
      final cut = (remaining - section.title.length).clamp(
        0,
        section.text.length,
      );
      if (cut > _minExcerpt) {
        kept.add(section.copyWith(text: '${section.text.substring(0, cut)}…'));
      }
      return (sections: kept, isTruncated: true);
    }
    return (sections: kept, isTruncated: false);
  }
}
