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
    if (AppConfig.notionTaskDatabaseId.isEmpty) {
      if (kDebugMode) {
        print('Notion Task Database ID is not configured.');
      }
      return null;
    }

    try {
      final response = await _dio.post('/pages', data: {
        'parent': {'database_id': AppConfig.notionTaskDatabaseId},
        'properties': {
          'Name': {
            'title': [
              {
                'text': {'content': task.titulo}
              }
            ]
          },
          'Status': {'checkbox': task.isConcluida},
          'Description': {
            'rich_text': [
              {
                'text': {'content': task.descricao}
              }
            ]
          },
          'Start Date': {
            'date': {
              'start': task.dataInicio.toIso8601String(),
            }
          },
          'Duration (mins)': {'number': task.duracaoMinutos},
          'Priority': {
            'select': {'name': task.prioridade}
          }
        }
      });

      if (response.statusCode == 200) {
        return response.data['id'];
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
    if (AppConfig.notionNoteDatabaseId.isEmpty) {
      if (kDebugMode) {
        print('Notion Note Database ID is not configured.');
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
}
