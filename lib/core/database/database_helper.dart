import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notario.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabela de utilizadores
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        google_id TEXT NOT NULL,
        email TEXT NOT NULL,
        nome TEXT NOT NULL,
        foto_url TEXT,
        google_calendar_id TEXT,
        timezone TEXT DEFAULT 'Europe/Lisbon',
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL
      )
    ''');

    // Tabela de tarefas
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        google_event_id TEXT,
        titulo TEXT NOT NULL,
        descricao TEXT,
        data_inicio TEXT NOT NULL,
        data_fim TEXT NOT NULL,
        duracao_minutos INTEGER NOT NULL,
        prioridade TEXT NOT NULL,
        aviso_antes_minutos INTEGER DEFAULT 10,
        aviso_depois_minutos INTEGER DEFAULT 5,
        estado TEXT DEFAULT 'pendente',
        tempo_real_minutos INTEGER,
        sincronizado INTEGER DEFAULT 0,
        versao INTEGER DEFAULT 1,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        concluido_em TEXT,
        sync_status TEXT DEFAULT 'synced',
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Índices para tarefas
    await db.execute('''
      CREATE INDEX idx_tasks_user_id ON tasks(user_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_tasks_data_inicio ON tasks(data_inicio)
    ''');
    await db.execute('''
      CREATE INDEX idx_tasks_sync_status ON tasks(sync_status)
    ''');

    // Tabela de notas
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        google_event_id TEXT,
        titulo TEXT NOT NULL,
        conteudo TEXT NOT NULL,
        data_lembrete TEXT NOT NULL,
        sincronizado INTEGER DEFAULT 0,
        versao INTEGER DEFAULT 1,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        sync_status TEXT DEFAULT 'synced',
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Índices para notas
    await db.execute('''
      CREATE INDEX idx_notes_user_id ON notes(user_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_notes_data_lembrete ON notes(data_lembrete)
    ''');

    // Tabela de estatísticas
    await db.execute('''
      CREATE TABLE statistics (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        data TEXT NOT NULL,
        tarefas_planejadas INTEGER DEFAULT 0,
        tarefas_concluidas INTEGER DEFAULT 0,
        tempo_planejado_minutos INTEGER DEFAULT 0,
        tempo_real_minutos INTEGER DEFAULT 0,
        pontuacao REAL DEFAULT 0,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        UNIQUE(user_id, data),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de fila de sincronização
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        entidade_tipo TEXT NOT NULL,
        entidade_id TEXT NOT NULL,
        operacao TEXT NOT NULL,
        payload TEXT NOT NULL,
        processado INTEGER DEFAULT 0,
        tentativas INTEGER DEFAULT 0,
        erro TEXT,
        criado_em TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_queue_processado ON sync_queue(processado)
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
