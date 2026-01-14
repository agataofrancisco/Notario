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
        google_id TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        nome TEXT NOT NULL,
        foto_url TEXT,
        google_calendar_id TEXT,
        google_refresh_token TEXT,
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
        google_event_id TEXT UNIQUE,
        titulo TEXT NOT NULL,
        descricao TEXT,
        data_inicio TEXT NOT NULL,
        data_fim TEXT NOT NULL,
        duracao_minutos INTEGER NOT NULL,
        prioridade TEXT NOT NULL CHECK (prioridade IN ('baixa', 'media', 'alta')),
        aviso_antes_minutos INTEGER DEFAULT 15,
        aviso_depois_minutos INTEGER DEFAULT 5,
        estado TEXT DEFAULT 'pendente' CHECK (estado IN ('pendente', 'em_execucao', 'concluida', 'pulada', 'cancelada')),
        tempo_real_minutos INTEGER,
        sincronizado INTEGER DEFAULT 0,
        versao INTEGER DEFAULT 1,
        dirty INTEGER DEFAULT 0,
        deleted_at TEXT,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        concluido_em TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_tasks_user_data ON tasks(user_id, data_inicio)
    ''');

    // Tabela de notas
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        google_event_id TEXT UNIQUE,
        titulo TEXT NOT NULL,
        conteudo TEXT NOT NULL,
        data_lembrete TEXT NOT NULL,
        sincronizado INTEGER DEFAULT 0,
        versao INTEGER DEFAULT 1,
        dirty INTEGER DEFAULT 0,
        deleted_at TEXT,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_notes_user_data ON notes(user_id, data_lembrete)
    ''');

    // Tabela de estatísticas
    await db.execute('''
      CREATE TABLE statistics (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        data TEXT NOT NULL,
        tarefas_planejadas INTEGER DEFAULT 0,
        tarefas_concluidas INTEGER DEFAULT 0,
        tarefas_puladas INTEGER DEFAULT 0,
        tempo_planejado_minutos INTEGER DEFAULT 0,
        tempo_real_minutos INTEGER DEFAULT 0,
        pontuacao_produtividade REAL,
        criado_em TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(user_id, data)
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
