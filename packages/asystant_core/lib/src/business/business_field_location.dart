/// Where an operation sends a [BusinessField]: replacing `{name}` in the
/// path, as a query parameter, as a member of the JSON body, or as a header.
enum BusinessFieldLocation { path, query, body, header }
