import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:host_app/src/modules/plant/model/plant.dart';
import 'package:host_app/src/modules/plant/model/plant_enums.dart';
import 'package:host_app/src/modules/reference/model/reference_data.dart';
import 'package:host_app/src/modules/reference/model/term_kind.dart';

/// The bundled catalog's rules: every plant speaks for botany, popular use
/// and science, and every use, preparation and belief cites its sources.
///
/// `PLANTS=ruda,sauco flutter test test/seed_catalog_test.dart` checks only
/// those files while they are written, accepting the terms they propose in
/// `newTerms`; without it the whole catalog is checked and nothing may be
/// left proposed.
void main() {
  final seed = jsonDecode(
    File('assets/seed/botanica_seed.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final reference = ReferenceData.fromJson(
    seed['reference'] as Map<String, Object?>,
  );
  final listed = (seed['plants'] as List<Object?>).cast<String>();
  final only = Platform.environment['PLANTS'];
  final authoring = only != null && only.trim().isNotEmpty;
  final ids = authoring
      ? only.split(',').map((id) => id.trim()).where((id) => id.isNotEmpty)
      : listed;

  for (final id in ids) {
    test('$id follows the catalog rules', () {
      final file = File('assets/seed/plants/$id.json');
      expect(file.existsSync(), isTrue, reason: 'Missing ${file.path}');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final problems = _Rules(
        json: json,
        reference: reference,
        acceptsProposed: authoring,
      ).problems(id);
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  }

  if (!authoring) {
    test('the catalog has at least 100 plants, each listed once', () {
      final files = Directory('assets/seed/plants')
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .where((name) => name.endsWith('.json'))
          .map((name) => name.substring(0, name.length - 5))
          .toSet();
      expect(listed.toSet(), files);
      expect(listed.toSet().length, listed.length);
      expect(listed.length, greaterThanOrEqualTo(100));
    });
  }
}

/// Checks one plant file and names every problem it finds.
class _Rules {
  _Rules({
    required this.json,
    required this.reference,
    required this.acceptsProposed,
  });

  final Map<String, Object?> json;

  final ReferenceData reference;

  /// While authoring, terms in `newTerms` count as known.
  final bool acceptsProposed;

  final List<String> _found = [];

  List<String> problems(String id) {
    final Plant plant;
    try {
      plant = Plant.fromJson(json);
    } on Object catch (error) {
      return ['$id does not parse: $error'];
    }
    final proposed = _proposed();
    if (!acceptsProposed && json.containsKey('newTerms')) {
      _found.add('newTerms must be merged into the vocabulary');
    }
    bool known(TermKind kind, String tag) =>
        reference.termsOf(kind).any((term) => term.id == tag) ||
        (acceptsProposed && proposed.contains((kind, tag)));

    _require(plant.id == id, 'id "${plant.id}" does not match the file');
    _require(plant.commonName.isNotEmpty, 'commonName is empty');
    _require(plant.scientificName.isNotEmpty, 'scientificName is empty');
    _require(plant.family.isNotEmpty, 'family is empty');
    _require(plant.easyExplanation.isNotEmpty, 'easyExplanation is empty');

    final sourceIds = <String>{};
    for (final source in plant.sources) {
      _require(source.id.isNotEmpty, 'a source has no id');
      _require(sourceIds.add(source.id), 'source id ${source.id} repeats');
      _require(source.title.isNotEmpty, 'source ${source.id} has no title');
      _require(
        source.url.startsWith('https://'),
        'source ${source.id} needs an https url',
      );
    }
    for (final kind in SourceKind.values) {
      _require(
        plant.sourcesOf(kind).isNotEmpty,
        'no ${kind.name} source: the three views need one each',
      );
    }
    SourceKind? kindOf(String sourceId) => plant.sources
        .where((source) => source.id == sourceId)
        .firstOrNull
        ?.kind;
    void cites(String what, List<String> cited, SourceKind needed) {
      _require(cited.isNotEmpty, '$what cites no source');
      for (final sourceId in cited) {
        _require(sourceIds.contains(sourceId), '$what cites unknown $sourceId');
      }
      _require(
        cited.any((sourceId) => kindOf(sourceId) == needed),
        '$what needs a ${needed.name} source',
      );
    }

    final botany = plant.botany;
    _require(botany.description.isNotEmpty, 'botany.description is empty');
    _require(
      botany.identification.isNotEmpty,
      'botany.identification is empty',
    );
    _require(botany.cultivation.isNotEmpty, 'botany.cultivation is empty');
    _require(botany.nativeRange.isNotEmpty, 'botany.nativeRange is empty');
    cites('botany', botany.sources, SourceKind.botany);

    // A plant with no safe use has no uses and no preparations; its
    // beliefs and safety fields say why.
    final noSafeUse = plant.indications.isEmpty;
    _require(
      !noSafeUse || plant.beliefs.isNotEmpty,
      'a plant without uses needs beliefs that explain why',
    );
    final uses = <String>{};
    for (final use in plant.indications) {
      uses.add(use.tag);
      _require(
        known(TermKind.symptom, use.tag) || known(TermKind.goal, use.tag),
        'use ${use.tag} is not a symptom or goal term',
      );
      _require(use.label.isNotEmpty, 'use ${use.tag} has no label');
      cites(
        'use ${use.tag}',
        use.sources,
        use.isPopular ? SourceKind.popular : SourceKind.science,
      );
    }
    for (final belief in plant.beliefs) {
      _require(belief.claim.isNotEmpty, 'a belief has no claim');
      _require(belief.note.isNotEmpty, 'belief "${belief.claim}" has no note');
      cites('belief "${belief.claim}"', belief.sources, SourceKind.science);
    }

    _require(
      noSafeUse ? plant.preparations.isEmpty : plant.preparations.isNotEmpty,
      noSafeUse
          ? 'a plant without uses offers no preparation'
          : 'no preparations',
    );
    for (final preparation in plant.preparations) {
      final name = 'preparation "${preparation.title}"';
      _require(preparation.title.isNotEmpty, 'a preparation has no title');
      _require(preparation.steps.isNotEmpty, '$name has no steps');
      _require(preparation.dose.isNotEmpty, '$name has no dose');
      for (final tag in preparation.uses) {
        _require(uses.contains(tag), '$name is for $tag, not a plant use');
      }
      _require(preparation.sources.isNotEmpty, '$name cites no source');
      for (final sourceId in preparation.sources) {
        _require(sourceIds.contains(sourceId), '$name cites unknown $sourceId');
      }
    }

    // A source nothing cites only fills the rules; every source must back
    // something the person reads.
    for (final sourceId in plant.safetySources) {
      _require(
        kindOf(sourceId) == SourceKind.science,
        'safetySources must be science sources ($sourceId)',
      );
    }
    final hasSafetyData =
        plant.contraindications.isNotEmpty ||
        plant.interactions.isNotEmpty ||
        plant.sideEffects.isNotEmpty ||
        plant.pregnancy != SafetyGuidance.notEstablished ||
        plant.lactation != SafetyGuidance.notEstablished;
    _require(
      !hasSafetyData || plant.safetySources.isNotEmpty,
      'safety fields need safetySources',
    );
    final cited = {
      ...botany.sources,
      ...plant.safetySources,
      for (final use in plant.indications) ...use.sources,
      for (final belief in plant.beliefs) ...belief.sources,
      for (final preparation in plant.preparations) ...preparation.sources,
    };
    for (final sourceId in sourceIds.difference(cited)) {
      _require(false, 'source $sourceId is not cited by anything');
    }

    for (final item in plant.contraindications) {
      final kind = switch (item.kind) {
        ContraindicationKind.condition => TermKind.condition,
        ContraindicationKind.allergy => TermKind.allergenGroup,
      };
      _require(known(kind, item.tag), 'contraindication ${item.tag} unknown');
    }
    for (final item in plant.interactions) {
      _require(
        known(TermKind.medicationClass, item.medicationClass),
        'interaction ${item.medicationClass} unknown',
      );
    }
    for (final group in plant.allergenGroups) {
      _require(known(TermKind.allergenGroup, group), 'allergen $group unknown');
    }

    _require(plant.photos.isNotEmpty, 'no photo');
    for (final photo in plant.photos) {
      final path = photo.ref.replaceFirst('asset://', '');
      _require(
        photo.ref.startsWith('asset://') && File(path).existsSync(),
        'photo ${photo.ref} is not a bundled file',
      );
      _require(
        photo.author.isNotEmpty &&
            photo.license.isNotEmpty &&
            photo.licenseUrl.isNotEmpty &&
            photo.sourceUrl.isNotEmpty,
        'photo ${photo.ref} lacks its credit',
      );
    }
    return _found;
  }

  /// The (kind, id) pairs this file proposes in `newTerms`.
  Set<(TermKind, String)> _proposed() => {
    for (final term in json['newTerms'] as List<Object?>? ?? const [])
      if (term case {'id': final String id, 'kind': final String kind})
        (TermKind.values.byName(kind), id),
  };

  void _require(bool condition, String problem) {
    if (!condition) {
      _found.add(problem);
    }
  }
}
