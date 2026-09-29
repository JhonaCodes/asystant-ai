part of 'strings.dart';

abstract final class ProfileStrings {
  static const title = 'Perfil';
  static const empty =
      'Aún no hay datos. El asistente irá guardando aquí lo que le cuentes '
      'sobre tu salud.';
  static const personal = 'Datos personales';
  static const name = 'Nombre';
  static const age = 'Edad';
  static const sex = 'Sexo';
  static const weight = 'Peso';
  static const height = 'Estatura';
  static const pregnancyAndLactation = 'Embarazo y lactancia';
  static const pregnant = 'Embarazo';
  static const lactating = 'Lactancia';
  static const yes = 'Sí';
  static const no = 'No';
  static const unknown = 'Sin dato';
  static const conditions = 'Condiciones de salud';
  static const medications = 'Medicamentos';
  static const allergies = 'Alergias';
  static const habits = 'Hábitos';
  static const familyHistory = 'Antecedentes familiares';
  static const none = 'Ninguno registrado';
  static const smoking = 'Tabaco';
  static const alcohol = 'Alcohol';
  static const caffeine = 'Cafeína';
  static const activity = 'Actividad física';
  static const sleep = 'Sueño';
  static const diet = 'Alimentación';
  static const female = 'Femenino';
  static const male = 'Masculino';
  static const intersex = 'Intersexual';
  static const unspecified = 'No indicado';
  static const deleteAll = 'Borrar mis datos';
  static const deleteTitle = '¿Borrar tus datos?';
  static const deleteBody =
      'Se borra tu perfil de este teléfono. Tus consultas se conservan.';

  static String years(int value) => '$value años';
  static String kilograms(double value) => '${value.toStringAsFixed(1)} kg';
  static String centimeters(double value) => '${value.round()} cm';
}
