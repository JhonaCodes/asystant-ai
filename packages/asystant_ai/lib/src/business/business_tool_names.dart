/// The names the model calls the business tools by. Change them to fit a
/// host's vocabulary, such as `operate_keel_business`.
///
/// Configuration held by a `BusinessToolkit`, never serialized, so it has
/// no JSON form.
class BusinessToolNames {
  const BusinessToolNames({
    this.register = 'register_business',
    this.update = 'update_business',
    this.connect = 'connect_business',
    this.operate = 'operate_business',
    this.configureEnvironment = 'configure_business_environment',
    this.configurePrivateHeader = 'configure_business_private_header',
    this.enterSecrets = 'enter_business_secrets',
    this.readDocs = 'read_business_docs',
  });

  final String register;
  final String update;
  final String connect;
  final String operate;
  final String configureEnvironment;
  final String configurePrivateHeader;
  final String enterSecrets;
  final String readDocs;

  /// Every name, for a host that filters remote tools with the same names.
  List<String> get all => [
    register,
    update,
    connect,
    operate,
    configureEnvironment,
    configurePrivateHeader,
    enterSecrets,
    readDocs,
  ];

  BusinessToolNames copyWith({
    String? register,
    String? update,
    String? connect,
    String? operate,
    String? configureEnvironment,
    String? configurePrivateHeader,
    String? enterSecrets,
    String? readDocs,
  }) => BusinessToolNames(
    register: register ?? this.register,
    update: update ?? this.update,
    connect: connect ?? this.connect,
    operate: operate ?? this.operate,
    configureEnvironment: configureEnvironment ?? this.configureEnvironment,
    configurePrivateHeader:
        configurePrivateHeader ?? this.configurePrivateHeader,
    enterSecrets: enterSecrets ?? this.enterSecrets,
    readDocs: readDocs ?? this.readDocs,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessToolNames &&
          register == other.register &&
          update == other.update &&
          connect == other.connect &&
          operate == other.operate &&
          configureEnvironment == other.configureEnvironment &&
          configurePrivateHeader == other.configurePrivateHeader &&
          enterSecrets == other.enterSecrets &&
          readDocs == other.readDocs;

  @override
  int get hashCode => Object.hash(
    register,
    update,
    connect,
    operate,
    configureEnvironment,
    configurePrivateHeader,
    enterSecrets,
    readDocs,
  );
}
