import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../features/tasks/domain/entities/task.dart';
import '../../features/notes/domain/entities/note.dart';
import '../config/app_config.dart';

class NotionService {
  final Dio _dio;

  NotionService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = AppConfig.notionApiUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer ${AppConfig.notionApiToken}',
      'Notion-Version': AppConfig.notionApiVersion,
      'Content-Type': 'application/json',
    };
  }

  /// Cria uma tarefa no banco de dados do Notion
  /// Retorna o ID da página criada ou null em caso de falha.
  Future<String?> createTask(Task task) async {
    if (AppConfig.notionTaskDatabaseId.isEmpty ||
        AppConfig.notionTaskDatabaseId == 'notariodb') {
      if (kDebugMode) {
        print('Notion Task Database ID is not configured properly.');
      }
      return null;
    }

    try {
      final properties = <String, dynamic>{
        'Name': {
          'title': [
            {
              'text': {'content': task.titulo}
            }
          ]
        },
        'Date': {
          'date': {
            'start': task.dataInicio.toIso8601String(),
          }
        },
        'Duration (mins)': {'number': task.duracaoMinutos},
        'Priority': {
          'select': {'name': task.prioridade.displayName}
        }
      };

      // Tentar definir Status. Como não sabemos se o database usa 'status' ou 'checkbox',
      // vamos assumir 'status' por padrão e o usuário configurará se falhar,
      // ou podemos tentar ser espertos. Mas na criação, se o JSON estiver errado, a API rejeita.
      // O mais seguro para criação é o usuário ter o database correto.
      // Porém, vamos tentar manter consistência com o updateTaskStatus.
      properties['Status'] = {
        'status': {'name': task.isConcluida ? 'Done' : 'Not started'}
      };

      // Adicionar descrição apenas se não for null
      if (task.descricao != null && task.descricao!.isNotEmpty) {
        properties['Description'] = {
          'rich_text': [
            {
              'text': {'content': task.descricao}
            }
          ]
        };
      }

      final response = await _dio.post('/pages', data: {
        'parent': {'database_id': AppConfig.notionTaskDatabaseId},
        'properties': properties
      });

      if (response.statusCode == 200) {
        return response.data['id'];
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error creating task in Notion: ${e.message}');
        if (e.response != null) {
          print('Notion API Error Response: ${e.response?.data}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating task in Notion: $e');
      }
    }
    return null;
  }

  /// Cria uma nota no banco de dados do Notion
  /// Retorna o ID da página criada ou null em caso de falha.
  Future<String?> createNote(Note note) async {
    if (AppConfig.notionNoteDatabaseId.isEmpty ||
        AppConfig.notionNoteDatabaseId == 'notariodb') {
      if (kDebugMode) {
        print('Notion Note Database ID is not configured properly.');
      }
      return null;
    }

    try {
      final response = await _dio.post('/pages', data: {
        'parent': {'database_id': AppConfig.notionNoteDatabaseId},
        'properties': {
          'Name': {
            'title': [
              {
                'text': {'content': note.titulo}
              }
            ]
          },
          'Content': {
            'rich_text': [
              {
                'text': {'content': note.conteudo}
              }
            ]
          },
          'Date': {
            'date': {
              'start': note.criadoEm.toIso8601String(),
            }
          },
        }
      });

      if (response.statusCode == 200) {
        return response.data['id'];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating note in Notion: $e');
      }
    }
    return null;
  }

  /// Atualiza o status de uma tarefa no Notion
  Future<bool> updateTaskStatus(String pageId, bool completed) async {
    try {
      // Tentar atualizar como 'status' primeiro (padrão novo do Notion)
      try {
        final response = await _dio.patch('/pages/$pageId', data: {
          'properties': {
            'Status': {
              'status': {'name': completed ? 'Done' : 'Not started'}
            },
          }
        });
        if (response.statusCode == 200) return true;
      } catch (e) {
        if (kDebugMode) {
          print('Failed to update as status property, trying as checkbox...');
        }
      }

      // Se falhar, tentar como 'checkbox' (padrão que alguns usuários usam)
      final response = await _dio.patch('/pages/$pageId', data: {
        'properties': {
          'Status': {'checkbox': completed},
        }
      });

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating task status in Notion: $e');
      }
      return false;
    }
  }
}
