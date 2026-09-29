part of 'strings.dart';

abstract final class CommonStrings {
  static const appName = 'Botánica';
  static const home = 'Inicio';
  static const assessments = 'Consultas';
  static const plants = 'Plantas';
  static const profile = 'Perfil';
  static const loading = 'Cargando…';
  static const loadFailed = 'No se pudieron cargar los datos.';
  static const retry = 'Reintentar';
  static const cancel = 'Cancelar';
  static const delete = 'Eliminar';
  static const close = 'Cerrar';
  static const notFound = 'No encontramos lo que buscas.';
  static const actionFailed =
      'No se pudo completar la acción. Inténtalo de nuevo.';
  static const disclaimer =
      'Orientación basada en información pública; no reemplaza la consulta '
      'profesional. Si empeoras o no mejoras, consulta a un médico.';

  static String photoCredit(String author, String license) =>
      'Foto: $author · $license';
}
