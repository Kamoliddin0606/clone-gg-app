import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';

class MockDio extends Mock implements Dio {
  @override
  BaseOptions get options => super.noSuchMethod(
    Invocation.getter(#options),
    returnValue: BaseOptions(),
    returnValueForMissingStub: BaseOptions(),
  );

  @override
  Future<Response<T>> get<T>(
    String? path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) => super.noSuchMethod(
    Invocation.method(
      #get,
      [path],
      {
        #data: data,
        #queryParameters: queryParameters,
        #options: options,
        #cancelToken: cancelToken,
        #onReceiveProgress: onReceiveProgress,
      },
    ),
    returnValue: Future.value(Response<T>(
      requestOptions: RequestOptions(path: path ?? ''),
      data: null,
    )),
    returnValueForMissingStub: Future.value(Response<T>(
      requestOptions: RequestOptions(path: path ?? ''),
      data: null,
    )),
  );
}
