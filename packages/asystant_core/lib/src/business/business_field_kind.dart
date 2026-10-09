/// The JSON type of a [BusinessField] value.
///
/// [secret] is a string the person types on the device, never the model;
/// [object] has typed members and [list] a typed item.
enum BusinessFieldKind {
  string,
  integer,
  number,
  boolean,
  object,
  list,
  secret,
}
