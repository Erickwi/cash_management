import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
      baseUrl: dotenv.get('API_URL', fallback: 'http://10.0.2.2:3000'),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final roomCode = prefs.getString('room_code');
        final deviceId = prefs.getString('device_id');

        if (roomCode != null) {
          options.headers['x-room-code'] = roomCode;
        }
        if (deviceId != null) {
          options.headers['x-device-id'] = deviceId;
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  Future<void> setBaseUrl(String url) {
    _dio.options.baseUrl = url;
    return SharedPreferences.getInstance().then((prefs) => prefs.setString('api_url', url));
  }

  Future<String> getBaseUrl() async {
    if (_dio.options.baseUrl.isNotEmpty) return _dio.options.baseUrl;
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('api_url') ?? dotenv.get('API_URL', fallback: 'http://10.0.2.2:3000');
    _dio.options.baseUrl = url;
    return url;
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) => _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) => _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) => _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);
}
