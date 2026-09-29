import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/knowledge/knowledge_hit.dart';
import 'package:asystant_core/src/knowledge/knowledge_query.dart';
import 'package:asystant_core/src/model/assistant_failure.dart';

/// Finds the documents relevant to a query. The extension point of local
/// knowledge: [KnowledgeSearchTool] and the apps talk to this contract, not
/// to a particular index.
///
/// The SDK ships [AsystantKnowledge], a lexical (BM25) index. A semantic
/// retriever (embeddings, a vector store, a hybrid of both) implements this
/// same class, and apps swap it in where they pass the index today, with no
/// other change. Like the providers, it says nothing about which AI answers.
abstract class KnowledgeRetriever {
  const KnowledgeRetriever();

  /// The best hits for [query], most relevant first, at most `query.limit`.
  /// An empty list when nothing matches; an `Err` only when the retriever
  /// itself cannot answer (for example, a remote index that is down).
  Future<Result<List<KnowledgeHit>, AssistantFailure>> search(
    KnowledgeQuery query,
  );

  /// The collections a search can be narrowed to, offered to the model as
  /// the accepted values of `collection`. Empty when unknown, which accepts
  /// any value.
  List<String> get collections => const [];
}
