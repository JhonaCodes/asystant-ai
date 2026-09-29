import 'dart:convert';

import 'package:asystant_core/asystant_core.dart';
import 'package:test/test.dart';

const _filler =
    'Keep the pot away from cold drafts and check the leaves every week. '
    'Clean the leaves with a damp cloth so they breathe. ';

final _documents = [
  const KnowledgeDocument(
    id: 'guide-orchid',
    title: 'Cuidado de la orquídea',
    collection: 'guides',
    text:
        '$_filler$_filler$_filler'
        'Riega las orquídeas una vez por semana, por la mañana, y deja que '
        'el sustrato se seque entre riegos. $_filler$_filler',
  ),
  const KnowledgeDocument(
    id: 'guide-cactus',
    title: 'Cactus care',
    collection: 'guides',
    text: 'Water a cactus once a month in winter. Full sun all year.',
  ),
  const KnowledgeDocument(
    id: 'faq-orchid',
    title: 'Why does my orchid lose flowers?',
    collection: 'faq',
    text: 'Una orquídea pierde flores por cambios bruscos de temperatura.',
  ),
  const KnowledgeDocument(
    id: 'faq-shipping',
    title: 'Shipping',
    collection: 'faq',
    text: 'Orders ship within two business days.',
  ),
];

void main() {
  test('ranks accents and plurals first and filters by collection', () {
    final knowledge = AsystantKnowledge(documents: _documents);

    // No accents, plural: "orquideas" / "riegos" match "orquídea" / "riega".
    final hits = knowledge.rank(
      const KnowledgeQuery(text: 'riego de orquideas', limit: 3),
    );
    expect(hits.first.id, 'guide-orchid');
    expect(hits.first.snippet, contains('Riega las orquídeas'));
    expect(
      hits.first.snippet.length,
      lessThanOrEqualTo(AsystantKnowledge.defaultSnippetLength + 2),
    );

    // Both collections have orchids; the filter keeps only the FAQ.
    expect(
      knowledge
          .rank(const KnowledgeQuery(text: 'orquideas'))
          .map((hit) => hit.collection)
          .toSet(),
      {'guides', 'faq'},
    );
    final faq = knowledge.rank(
      const KnowledgeQuery(text: 'orquideas', collection: 'faq'),
    );
    expect(faq.map((hit) => hit.id), ['faq-orchid']);

    // Saved and restored, the index ranks the same.
    final restored = AsystantKnowledge.fromJson(
      jsonDecode(jsonEncode(knowledge.toJson())) as Map<String, Object?>,
    );
    expect(
      restored
          .rank(const KnowledgeQuery(text: 'riego de orquideas', limit: 3))
          .map((hit) => hit.id),
      hits.map((hit) => hit.id),
    );
  });

  test('search tool returns compact hits for the model', () async {
    final tool = KnowledgeSearchTool(
      knowledge: AsystantKnowledge(documents: _documents),
    );
    expect(ToolRegistry([tool]).validate().isOk, isTrue);
    expect(tool.definition.name, 'search_knowledge');

    const arguments = ToolArguments(
      '{"query":"orquídea","collection":"guides","limit":2}',
    );
    expect(
      ToolRegistry([tool]).resolve('search_knowledge', arguments).isOk,
      isTrue,
    );
    final outcome = await tool.execute(
      arguments,
      ToolContext(
        idempotencyKey: 'call-1',
        selectedOptions: const [],
        isCanceled: () => false,
      ),
    );
    final content =
        jsonDecode(outcome.data.modelContent) as Map<String, Object?>;
    final results = (content['results'] as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(results, hasLength(1));
    expect(results.single.keys, [
      'id',
      'title',
      'collection',
      'score',
      'snippet',
    ]);
    expect(results.single['id'], 'guide-orchid');
    expect(results.single['collection'], 'guides');
    expect(
      (results.single['snippet'] as String).length,
      lessThan(_documents.first.text.length),
    );
  });
}
