import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late final Dio _dio;
  final SharedPreferences _prefs;

  ApiService(this._prefs) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: AppConfig.httpTimeout),
        receiveTimeout: const Duration(seconds: AppConfig.httpTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Adicionar interceptor para incluir token JWT
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = _prefs.getString(AppConfig.tokenCacheKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Se receber 401, limpar token e redirecionar para login
          if (error.response?.statusCode == 401) {
            await _prefs.remove(AppConfig.tokenCacheKey);
            await _prefs.remove(AppConfig.userCacheKey);
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Autenticação
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    required String accessToken,
  }) async {
    final response = await _dio.post('/auth/google', data: {
      'id_token': idToken,
      'access_token': accessToken,
    });
    return response.data;
  }

  // Utilizadores
  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/users/me');
    return response.data;
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) async {
    final response = await _dio.patch('/users/me', data: data);
    return response.data;
  }

  // Tarefas
  Future<List<dynamic>> getTasks({
    String? dataInicio,
    String? dataFim,
    String? estado,
  }) async {
    final queryParams = <String, dynamic>{};
    if (dataInicio != null) queryParams['data_inicio'] = dataInicio;
    if (dataFim != null) queryParams['data_fim'] = dataFim;
    if (estado != null) queryParams['estado'] = estado;

    final response = await _dio.get('/tasks', queryParameters: queryParams);
    return response.data['tasks'] ?? [];
  }

  Future<Map<String, dynamic>> getTask(String id) async {
    final response = await _dio.get('/tasks/$id');
    return response.data['task'];
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    final response = await _dio.post('/tasks', data: data);
    return response.data['task'];
  }

  Future<Map<String, dynamic>> updateTask(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put('/tasks/$id', data: data);
    return response.data['task'];
  }

  Future<void> deleteTask(String id) async {
    await _dio.delete('/tasks/$id');
  }

  Future<Map<String, dynamic>> validateDay(Map<String, dynamic> data) async {
    final response = await _dio.post('/tasks/validate-day', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> startTask(String id) async {
    final response = await _dio.post('/tasks/$id/start');
    return response.data;
  }

  Future<Map<String, dynamic>> completeTask(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/tasks/$id/complete', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> skipTask(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/tasks/$id/skip', data: data);
    return response.data;
  }

  // Health check
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
