import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

class UploadImageCloudinaryCall {
  static Future<ApiCallResponse> call({
    FFUploadedFile? file,
    String? uploadPreset = 'aman_build',
    String? publicId = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'UploadImageCloudinary',
      apiUrl: 'https://api.cloudinary.com/v1_1/dxjzonvxd/image/upload',
      callType: ApiCallType.POST,
      headers: {},
      params: {
        'file': file,
        'upload_preset': uploadPreset,
        'public_id': publicId,
      },
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}
