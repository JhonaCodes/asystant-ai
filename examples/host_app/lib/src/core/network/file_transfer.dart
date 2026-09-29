import 'package:result_controller/result_controller.dart';

import 'package:host_app/src/core/network/api_failure.dart';

import 'package:host_app/src/core/network/api_envelope.dart';
import 'package:host_app/src/core/network/api_impl.dart';
import 'package:host_app/src/core/network/file_upload.dart';
import 'package:host_app/src/core/network/uploaded_file.dart';
import 'package:host_app/src/core/services/infra_service.dart';

/// Uploads and removes files through the app's backend.
class FileTransfer {
  const FileTransfer();

  ApiImpl get _api => InfraService.mainApi.notifier;

  Future<Result<UploadedFile, ApiFailure>> upload(FileUpload file) async =>
      (await _api.post(Params(path: '/files', model: file)))
          .entity(UploadedFile.fromJson);

  Future<Result<bool, ApiFailure>> remove(String fileId) async =>
      (await _api.delete(Params(path: '/files/$fileId'))).done();
}
