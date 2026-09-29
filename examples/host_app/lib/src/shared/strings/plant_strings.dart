part of 'strings.dart';

abstract final class PlantStrings {
  static const title = 'Plantas';
  static const search = 'Buscar planta';
  static const all = 'Todas';
  static const fromCatalog = 'Del catálogo';
  static const addedByYou = 'Agregadas por ti';
  static const addedBadge = 'Agregada por ti';
  static const empty =
      'No hay plantas con ese nombre. Puedes contarle al asistente de una '
      'planta que conozcas para agregarla.';
  static const choose = 'Elige una planta para ver su ficha.';
  static const inShort = 'En pocas palabras';
  static const usedFor = 'Para qué se usa';
  static const howToTake = 'Cómo tomarla';
  static const precautions = 'Precauciones';
  static const sources = 'Fuentes';
  static const photos = 'Fotos';
  static const noPhoto =
      'Esta planta aún no tiene foto. El asistente te la pedirá para que no '
      'la confundas.';
  static const deletePlant = 'Eliminar planta';
  static const deleteTitle = '¿Eliminar esta planta?';
  static const deleteBody = 'Se borran su ficha y sus fotos de este teléfono.';
  static const wellEstablished = 'Uso bien establecido';
  static const traditional = 'Uso tradicional';
  static const limited = 'Evidencia limitada';
  static const popular = 'Uso popular, no comprobado';
  static const botany = 'La planta';
  static const nativeRange = 'De dónde es';
  static const identification = 'Cómo reconocerla';
  static const cultivation = 'Cómo cultivarla';
  static const lookalikes = 'Cuidado, se puede confundir con';
  static const science = 'Lo que dice la ciencia';
  static const popularUses = 'Lo que dice la gente';
  static const popularNote =
      'Usos que cuenta la tradición popular. No están comprobados.';
  static const beliefs = 'Creencias que no conviene seguir';
  static const noSafeUse = 'Esta planta no tiene un uso seguro para recomendar';
  static const noSafeUseBody =
      'Lee abajo por qué. Si alguien te la ofrece como remedio, consulta antes '
      'a un profesional de la salud.';
  static const known = 'Lo que se sabe';
  static const botanySources = 'Botánica';
  static const popularSources = 'Tradición popular';
  static const scienceSources = 'Ciencia';
  static const pregnancy = 'Embarazo';
  static const lactation = 'Lactancia';
  static const acceptable = 'Se puede usar';
  static const avoid = 'Evitar';
  static const notEstablished = 'No hay datos suficientes: mejor evitarla';
  static const avoidWith = 'Evitar con';
  static const cautionWith = 'Precaución con';
  static const notFor = 'No usar si tienes';
  static const allergyTo = 'Alergia a';
  static const sideEffects = 'Efectos posibles';
  static const infusion = 'Infusión';
  static const decoction = 'Decocción';
  static const tincture = 'Tintura';
  static const topical = 'Uso sobre la piel';
  static const capsule = 'Cápsulas';
  static const essentialOil = 'Aceite esencial';
  static const gel = 'Gel';
  static const freshPlant = 'Planta fresca';
  static const oral = 'Por boca';
  static const onSkin = 'Sobre la piel';
  static const inhaled = 'Inhalada';

  static const howMuch = 'Cuánto';
  static const howOften = 'Cada cuándo';
  static const boilingWater = 'Agua recién hervida';
  static const careful = 'Ten cuidado';
  static const moreDetails = 'Más detalles';

  static String step(int number) => 'Paso $number';
  static String minAge(int years) => 'Desde los $years años';
  static String maxDays(int days) => 'Máximo $days días seguidos';
  static String dose(String value) => 'Cantidad: $value';
  static String frequency(String value) => 'Frecuencia: $value';
  static String catalogCount(int total, int added) =>
      '$total plantas · $added agregadas por ti';
}
